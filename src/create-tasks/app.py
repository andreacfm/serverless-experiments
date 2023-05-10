import json
import os
import boto3
import uuid

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('DYNAMO_DB_TABLE_NAME'))
REQUESTED = 'requested'


def lambda_handler(event, context):
    task_id = str(uuid.uuid4())
    response = table.put_item(
        Item={
            'PK': task_id,
            'state': REQUESTED
        }
    )
    print(response)
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "task_id ": task_id
        })
    }
