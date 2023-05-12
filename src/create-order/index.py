import json
import os
import boto3
import uuid

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('DYNAMO_DB_TABLE_NAME'))
PENDING = 'pending'


def lambda_handler(event, context):
    order_id = str(uuid.uuid4())
    reason = "Waiting for shipping"
    response = table.put_item(
        Item={
            'PK': order_id,
            'state': PENDING,
            'reason': reason
        }
    )
    print(response)
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "order_id ": order_id,
            "state": PENDING,
            "reason": reason
        })
    }
