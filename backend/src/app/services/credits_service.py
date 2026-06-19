import logging
import time

import boto3
from botocore.exceptions import ClientError

from app.config import get_settings

logger = logging.getLogger(__name__)


class CreditsService:
    """Manages trip credits (consumable in-app purchases).

    Products:
      - 1 trip: $1.99
      - 3-trip pack: $4.99 (primary offering)
      - 10-trip pack: $9.99
    """

    PRODUCT_CREDITS = {
        "com.aisuggestion.trip.1": 1,
        "com.aisuggestion.trip.3": 3,
        "com.aisuggestion.trip.10": 10,
    }

    def __init__(self):
        settings = get_settings()
        self.dynamodb = boto3.resource("dynamodb", region_name=settings.aws_region)
        self.table = self.dynamodb.Table(settings.dynamodb_table_credits)
        self.free_credits = settings.free_credits

    async def get_credits(self, device_id: str) -> int:
        try:
            response = self.table.get_item(
                Key={"pk": f"DEVICE#{device_id}", "sk": "CREDITS"}
            )
            item = response.get("Item")
            if not item:
                return self.free_credits
            return int(item.get("balance", 0))
        except ClientError:
            logger.warning("Failed to get credits", exc_info=True)
            return 0

    async def has_credits(self, device_id: str) -> bool:
        if get_settings().unlimited_test_credits:
            return True
        return (await self.get_credits(device_id)) > 0

    async def consume_credit(self, device_id: str) -> int:
        if get_settings().unlimited_test_credits:
            return 999
        try:
            response = self.table.update_item(
                Key={"pk": f"DEVICE#{device_id}", "sk": "CREDITS"},
                UpdateExpression="SET balance = if_not_exists(balance, :free) - :one, last_used = :now",
                ExpressionAttributeValues={
                    ":one": 1,
                    ":free": self.free_credits,
                    ":now": int(time.time()),
                    ":zero": 0,
                },
                ConditionExpression="attribute_not_exists(balance) OR balance > :zero",
                ReturnValues="UPDATED_NEW",
            )
            remaining = int(response["Attributes"]["balance"])
            logger.info(
                "Device %s: credit consumed, %d remaining", device_id[:8], remaining
            )
            return remaining
        except ClientError as e:
            if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
                return -1
            raise

    async def add_credits(
        self,
        device_id: str,
        product_id: str,
        transaction_id: str,
    ) -> int:
        credits_to_add = self.PRODUCT_CREDITS.get(product_id, 0)
        if credits_to_add == 0:
            raise ValueError(f"Unknown product: {product_id}")

        try:
            # Global transaction check — prevents cross-device replay
            self.table.put_item(
                Item={
                    "pk": f"TXN#{transaction_id}",
                    "sk": "META",
                    "device_id": device_id,
                    "product_id": product_id,
                    "credits_added": credits_to_add,
                    "timestamp": int(time.time()),
                    "expires_at": int(time.time()) + 86400 * 365,
                },
                ConditionExpression="attribute_not_exists(pk) AND attribute_not_exists(sk)",
            )
        except ClientError as e:
            if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
                raise ValueError("Transaction already processed") from e
            raise

        try:
            response = self.table.update_item(
                Key={"pk": f"DEVICE#{device_id}", "sk": "CREDITS"},
                UpdateExpression=(
                    "SET balance = if_not_exists(balance, :zero) + :credits, "
                    "last_purchased = :now, "
                    "total_purchased = if_not_exists(total_purchased, :zero) + :credits"
                ),
                ExpressionAttributeValues={
                    ":credits": credits_to_add,
                    ":zero": 0,
                    ":now": int(time.time()),
                },
                ReturnValues="UPDATED_NEW",
            )

            return int(response["Attributes"]["balance"])
        except ClientError:
            logger.error("Failed to add credits", exc_info=True)
            raise
