import hashlib
import logging
import secrets
import time

import boto3
from botocore.exceptions import ClientError

from app.config import get_settings

logger = logging.getLogger(__name__)


class AuthService:
    def __init__(self):
        settings = get_settings()
        self.dynamodb = boto3.resource("dynamodb", region_name=settings.aws_region)
        self.table = self.dynamodb.Table(settings.dynamodb_table_credits)

    async def register_device(
        self, device_id: str, attestation: str, challenge: str
    ) -> str:
        if not self._validate_attestation(attestation, challenge, device_id):
            raise ValueError("Attestation validation failed")

        token = secrets.token_urlsafe(48)
        token_hash = hashlib.sha256(token.encode()).hexdigest()

        try:
            self.table.put_item(
                Item={
                    "pk": f"DEVICE#{device_id}",
                    "sk": "AUTH",
                    "token_hash": token_hash,
                    "attested": True,
                    "created_at": int(time.time()),
                    "last_used": int(time.time()),
                },
                ConditionExpression="attribute_not_exists(sk) OR #att = :false",
                ExpressionAttributeNames={"#att": "attested"},
                ExpressionAttributeValues={":false": False},
            )
        except ClientError as e:
            if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
                raise ValueError("Device already registered") from e
            raise

        logger.info("Device %s registered via App Attest", device_id[:8])
        return token

    async def validate_token(self, device_id: str, token: str) -> bool:
        token_hash = hashlib.sha256(token.encode()).hexdigest()

        try:
            response = self.table.get_item(
                Key={"pk": f"DEVICE#{device_id}", "sk": "AUTH"}
            )
            item = response.get("Item")
            if not item:
                return False
            if item.get("token_hash") != token_hash:
                return False
            if not item.get("attested"):
                return False

            self.table.update_item(
                Key={"pk": f"DEVICE#{device_id}", "sk": "AUTH"},
                UpdateExpression="SET last_used = :now",
                ExpressionAttributeValues={":now": int(time.time())},
            )
            return True
        except ClientError:
            logger.warning("Token validation failed for device %s", device_id[:8])
            return False

    async def revoke_device(self, device_id: str) -> None:
        self.table.delete_item(Key={"pk": f"DEVICE#{device_id}", "sk": "AUTH"})

    def _validate_attestation(
        self, attestation: str, challenge: str, device_id: str
    ) -> bool:
        settings = get_settings()
        if settings.unlimited_test_credits:
            return len(attestation) > 0

        # Production: validate Apple App Attest attestation object
        # The attestation is a base64-encoded CBOR object from Apple
        # containing a certificate chain signed by Apple's App Attest CA
        #
        # Full validation steps:
        # 1. Decode CBOR attestation statement
        # 2. Verify certificate chain against Apple App Attest root CA
        # 3. Extract public key from leaf certificate
        # 4. Verify nonce = SHA256(challenge + keyId)
        # 5. Verify app ID matches bundle identifier
        # 6. Check counter is 0 (first attestation)
        #
        # For now, validate format and length (replace with full validation before App Store)
        if len(attestation) < 100:
            return False

        return True
