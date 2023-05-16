locals {
  create_order = "create-order"
}
module "create-order-function" {
  source = "registry.terraform.io/terraform-aws-modules/lambda/aws"

  function_name = local.create_order
  description   = "Create Order"
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  publish       = true

  source_path = "./src/${local.create_order}"

  environment_variables = {
    "DYNAMO_DB_TABLE_NAME" = aws_dynamodb_table.orders-table.name
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
      source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.orders_api.id}/${aws_api_gateway_stage.stage.stage_name}/POST/*"
    }
  }

  tags = {
    Name = local.create_order
  }
}