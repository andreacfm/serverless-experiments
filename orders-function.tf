locals {
  orders = "orders"
}
module "create-order-function" {
  source = "registry.terraform.io/terraform-aws-modules/lambda/aws"

  function_name = local.orders
  description   = "Orders mgmt"
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  publish       = true
  layers = ["arn:aws:lambda:${var.region}:017000801446:layer:AWSLambdaPowertoolsPythonV2:32"]

  source_path = "./src/${local.orders}"

  environment_variables = {
    "DYNAMO_DB_TABLE_NAME" = aws_dynamodb_table.orders-table.name
  }

  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect    = "Allow",
      actions   = [
        "dynamodb:PutItem",
        "dynamodb:GetItem"
      ],
      resources = [aws_dynamodb_table.orders-table.arn]
    }
  }

  allowed_triggers = {
    APIGatewayProd = {
      service    = "apigateway"
      source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.orders_api.id}/prod/*/*"
    }
  }

  tags = {
    Name = local.orders
  }
}