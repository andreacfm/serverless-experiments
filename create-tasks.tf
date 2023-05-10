locals {
  create_tasks = "create-tasks"
}
module "create-tasks" {
  source = "registry.terraform.io/terraform-aws-modules/lambda/aws"

  function_name = local.create_tasks
  description   = "Create Task"
  handler       = "app.lambda_handler"
  runtime       = "python3.9"
  publish       = true

  source_path = "./src/${local.create_tasks}"

  environment_variables = {
    "DYNAMO_DB_TABLE_NAME" = aws_dynamodb_table.tasks-table.name
  }

  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect    = "Allow",
      actions   = ["dynamodb:PutItem"],
      resources = [aws_dynamodb_table.tasks-table.arn]
    }
  }

  allowed_triggers = {
    APIGatewayProdPost = {
      service    = "apigateway"
      source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.tasks-api.id}/${aws_api_gateway_stage.stage.stage_name}/POST/*"
    }
  }

  tags = {
    Name = local.create_tasks
  }
}