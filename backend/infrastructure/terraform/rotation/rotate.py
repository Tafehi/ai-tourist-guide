import secrets
import string

import boto3


def handler(event, context):
    secret_id = event["SecretId"]
    step = event["Step"]
    token = event["ClientRequestToken"]

    client = boto3.client("secretsmanager")

    if step == "createSecret":
        try:
            client.get_secret_value(
                SecretId=secret_id, VersionId=token, VersionStage="AWSPENDING"
            )
        except client.exceptions.ResourceNotFoundException:
            alphabet = string.ascii_letters + string.digits
            new_key = "".join(secrets.choice(alphabet) for _ in range(32))
            client.put_secret_value(
                SecretId=secret_id,
                ClientRequestToken=token,
                SecretString=new_key,
                VersionStages=["AWSPENDING"],
            )

    elif step == "setSecret":
        pass

    elif step == "testSecret":
        client.get_secret_value(
            SecretId=secret_id, VersionId=token, VersionStage="AWSPENDING"
        )

    elif step == "finishSecret":
        metadata = client.describe_secret(SecretId=secret_id)
        current_version = None
        for version_id, stages in metadata["VersionIdsToStages"].items():
            if "AWSCURRENT" in stages:
                if version_id == token:
                    return
                current_version = version_id
                break

        client.update_secret_version_stage(
            SecretId=secret_id,
            VersionStage="AWSCURRENT",
            MoveToVersionId=token,
            RemoveFromVersionId=current_version,
        )
