import os
from datetime import datetime

import boto3
from aws_lambda_powertools.event_handler.exceptions import BadRequestError
from botocore.exceptions import ClientError
from aws_lambda_powertools import Logger

logger = Logger()

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('DYNAMO_DB_TABLE_NAME'))

SHIPPED = "shipped"


def lambda_handler(event, context):
    order_id = event["order_id"]
    shipped_at = event["shipped_at"]
    try:
        table.update_item(
            Key={'PK': order_id},
            UpdateExpression="set #state=:state,reason=:reason",
            ConditionExpression='attribute_exists(PK)',
            ExpressionAttributeValues={':state': SHIPPED, ':reason': "Shipped at %s" % shipped_at},
            ExpressionAttributeNames={'#state': 'state'},
            ReturnValues="UPDATED_NEW")
    except ClientError as err:
        message = "%s: %s" % (err.response['Error']['Code'], err.response['Error']['Message'])
        logger.error(message)
        raise BadRequestError(message)