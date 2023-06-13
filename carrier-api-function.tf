locals {
  carrier_api = "carrier-api"
}
module "carrier-mock-function" {
  source = "registry.terraform.io/terraform-aws-modules/lambda/aws"

  function_name              = local.carrier_api
  description                = "Carrier Mock"
  handler                    = "index.lambda_handler"
  runtime                    = "python3.9"
  publish                    = true
  source_path                = "./src/${local.carrier_api}"
  create_lambda_function_url = true
  layers = ["arn:aws:lambda:${var.region}:017000801446:layer:AWSLambdaPowertoolsPythonV2:32"]

  environment_variables = {
    "INTEGRATION_API_BASE_URL" = "${aws_api_gateway_deployment.integration_api_deployment.invoke_url}${aws_api_gateway_stage.integration_api_stage.stage_name}"
  }

  tags = {
    Name = local.carrier_api
  }
}

output "carrier_api" {
  value = module.carrier-mock-function.lambda_function_url
}