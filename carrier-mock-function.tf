locals {
  carrier_mock = "carrier-mock"
}
module "carrier-mock-function" {
  source = "registry.terraform.io/terraform-aws-modules/lambda/aws"

  function_name              = local.carrier_mock
  description                = "Carrier Mock"
  handler                    = "index.lambda_handler"
  runtime                    = "python3.9"
  publish                    = true
  source_path                = "./src/${local.carrier_mock}"
  create_lambda_function_url = true
  layers = ["arn:aws:lambda:${var.region}:017000801446:layer:AWSLambdaPowertoolsPythonV2:32"]

  environment_variables = {
    "THIRD_PARTIES_API_BASE_URL" = "${aws_api_gateway_deployment.third_parties_api_deployment.invoke_url}${aws_api_gateway_stage.third_parties_api_stage.stage_name}"
  }

  tags = {
    Name = local.carrier_mock
  }
}

output "carrier_api" {
  value = module.carrier-mock-function.lambda_function_url
}