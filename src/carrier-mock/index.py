import json
import os
from datetime import datetime

import requests
from aws_lambda_powertools.event_handler import LambdaFunctionUrlResolver
from aws_lambda_powertools.event_handler.exceptions import BadRequestError
from botocore.exceptions import ClientError
from aws_lambda_powertools import Logger

app = LambdaFunctionUrlResolver()
logger = Logger()


@app.post("/orders")
def handle_order():
    base_url = os.environ.get("THIRD_PARTIES_API_BASE_URL")
    order_id = app.current_event.json_body.get("order_id")
    url = "%s/confirm-shipment" % base_url
    logger.info(url)
    response = requests.post(url, json={'order_id': order_id})
    logger.info(response)
    return response.status_code


def lambda_handler(event, context):
    return app.resolve(event, context)
