locals {
  confirm_shipment = "confirm-shipment"
}
module "confirm-shipment-function" {
  source = "registry.terraform.io/terraform-aws-modules/lambda/aws"

  function_name = local.confirm_shipment
  description   = "Shipment Management"
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  publish       = true
  layers = ["arn:aws:lambda:${var.region}:017000801446:layer:AWSLambdaPowertoolsPythonV2:32"]

  source_path = "./src/${local.confirm_shipment}"

  environment_variables = {
    DYNAMO_DB_TABLE_NAME = aws_dynamodb_table.orders-table.name
    POWERTOOLS_SERVICE_NAME = "shipments"
    LOG_LEVEL = "INFO"
  }

  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect    = "Allow",
      actions   = ["dynamodb:UpdateItem"],
      resources = [aws_dynamodb_table.orders-table.arn]
    }
  }

  allowed_triggers = {
    OrderShippedEvent = {
      service    = "events"
      source_arn = aws_cloudwatch_event_rule.order_shipped_rule.arn
    }
  }

  tags = {
    Name = local.confirm_shipment
  }
}