locals {
  orders_api_name = "orders-api"
}
resource "aws_api_gateway_rest_api" "orders_api" {
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = local.orders_api_name
      version = "1.0"
    }
    paths = {
      "/orders" = {
        post = {
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "aws_proxy"
            uri                  = module.create-order-function.lambda_function_qualified_invoke_arn
          }
        }
      }
    }
  })

  name = local.orders_api_name

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "orders_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.orders_api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.orders_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.orders_api.id
  stage_name    = "prod"
}

output "orders_api_gateway_url" {
  value = aws_api_gateway_deployment.orders_api_deployment.invoke_url
}