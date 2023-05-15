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
  layers = ["arn:aws:lambda:us-east-1:017000801446:layer:AWSLambdaPowertoolsPythonV2:32"]

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
      actions   = ["dynamodb:PutItem"],
      resources = [aws_dynamodb_table.orders-table.arn]
    }
  }

  allowed_triggers = {
    APIGatewayProdPost = {
      service    = "apigateway"
      source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.third_parties_api.id}/${aws_api_gateway_stage.third_parties_api_stage.stage_name}/POST/*"
    }
  }

  tags = {
    Name = local.create_order
  }
}