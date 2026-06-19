import time

import boto3
from botocore.exceptions import ClientError

from app.config import get_settings

_WINDOW_SECONDS = 3600
_MAX_REQUESTS_PER_DEVICE = 10
_MAX_DEVICES_PER_HOUR = 50


class RateLimiter:
    def __init__(self):
        settings = get_settings()
        self.dynamodb = boto3.resource("dynamodb", region_name=settings.aws_region)
        self.table = self.dynamodb.Table(settings.dynamodb_table_credits)

    def check_device_rate(self, device_id: str) -> bool:
        now = int(time.time())
        window_start = now - _WINDOW_SECONDS

        try:
            response = self.table.update_item(
                Key={"pk": f"RATE#{device_id}", "sk": "GENERATE"},
                UpdateExpression="SET #cnt = if_not_exists(#cnt, :zero) + :one, #ts = :now, #exp = :ttl",
                ConditionExpression="attribute_not_exists(#ts) OR #ts < :window OR #cnt < :limit",
                ExpressionAttributeNames={
                    "#cnt": "request_count",
                    "#ts": "window_start",
                    "#exp": "expires_at",
                },
                ExpressionAttributeValues={
                    ":one": 1,
                    ":zero": 0,
                    ":now": now,
                    ":window": window_start,
                    ":limit": _MAX_REQUESTS_PER_DEVICE,
                    ":ttl": now + _WINDOW_SECONDS * 2,
                },
                ReturnValues="UPDATED_NEW",
            )
            count = int(response["Attributes"]["request_count"])
            window = int(response["Attributes"]["window_start"])

            if window < window_start:
                self.table.update_item(
                    Key={"pk": f"RATE#{device_id}", "sk": "GENERATE"},
                    UpdateExpression="SET #cnt = :one, #ts = :now",
                    ExpressionAttributeNames={
                        "#cnt": "request_count",
                        "#ts": "window_start",
                    },
                    ExpressionAttributeValues={":one": 1, ":now": now},
                )
                return True

            return count <= _MAX_REQUESTS_PER_DEVICE
        except ClientError as e:
            if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
                return False
            return False

    def check_new_device_rate(self) -> bool:
        now = int(time.time())
        hour_key = f"NEWDEV#{now // _WINDOW_SECONDS}"

        try:
            response = self.table.update_item(
                Key={"pk": hour_key, "sk": "COUNT"},
                UpdateExpression="SET #cnt = if_not_exists(#cnt, :zero) + :one, #exp = :ttl",
                ExpressionAttributeNames={"#cnt": "device_count", "#exp": "expires_at"},
                ExpressionAttributeValues={
                    ":one": 1,
                    ":zero": 0,
                    ":ttl": now + _WINDOW_SECONDS * 2,
                },
                ReturnValues="UPDATED_NEW",
            )
            count = int(response["Attributes"]["device_count"])
            return count <= _MAX_DEVICES_PER_HOUR
        except ClientError:
            return True
