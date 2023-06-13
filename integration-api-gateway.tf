locals {
  integration_api_name = "third-parties-api"
}
resource "aws_api_gateway_rest_api" "integration_api" {
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = local.integration_api_name
      version = "1.0"
    }
    paths = {
      "/confirm-shipment" = {
        post = {
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "aws_proxy"
            uri                  = module.confirm-shipment-function.lambda_function_qualified_invoke_arn
          }
        }
      }
    }
  })

  name = local.integration_api_name

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "integration_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.integration_api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.integration_api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "integration_api_stage" {
  deployment_id = aws_api_gateway_deployment.integration_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.integration_api.id
  stage_name    = "prod"
}

output "integration_api_gateway_url" {
  value = aws_api_gateway_deployment.integration_api_deployment.invoke_url
}