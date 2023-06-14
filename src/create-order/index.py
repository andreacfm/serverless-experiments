import json
import os
import boto3
import uuid
from aws_lambda_powertools.event_handler import APIGatewayRestResolver
from aws_lambda_powertools import Logger

app = APIGatewayRestResolver()
logger = Logger()

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('DYNAMO_DB_TABLE_NAME'))

PENDING = 'pending'


@app.post("/orders")
def create_order(event, context):
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


@app.get("/order")
def get_order(order_id):
    response = table.get_item(
        Item={
            'PK': order_id
        }
    )
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(response)
    }


def lambda_handler(event, context):
    logger.info(event)
    return app.resolve(event, context)
