import json
import os
from datetime import datetime

import boto3
from aws_lambda_powertools.event_handler import APIGatewayRestResolver
from aws_lambda_powertools.event_handler.exceptions import BadRequestError
from botocore.exceptions import ClientError
from aws_lambda_powertools import Logger

app = APIGatewayRestResolver()
logger = Logger()

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('DYNAMO_DB_TABLE_NAME'))

SHIPPED = "shipped"


@app.post("/orders/<order_id>/actions/confirm-shipment")
def confirm_shipment(order_id):
    today = datetime.now()
    iso_date = today.isoformat()
    try:
        table.update_item(
            Key={'PK': order_id},
            UpdateExpression="set #state=:state,reason=:reason",
            ConditionExpression='attribute_exists(PK)',
            ExpressionAttributeValues={':state': SHIPPED, ':reason': "Shipped at %s" % iso_date},
            ExpressionAttributeNames={'#state': 'state'},
            ReturnValues="UPDATED_NEW")
    except ClientError as err:
        message = "%s: %s" % (err.response['Error']['Code'], err.response['Error']['Message'])
        logger.error(message)
        raise BadRequestError(message)

    else:
        return {"order_id": order_id, "state": SHIPPED}


def lambda_handler(event, context):
    return app.resolve(event, context)
