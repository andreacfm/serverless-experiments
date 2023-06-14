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
          "x-amazon-apigateway-integration" = {
            httpMethod  = "POST"
            type        = "aws"
            uri         = "arn:aws:apigateway:${data.aws_region.current.name}:events:action/PutEvents"
            credentials = "arn:aws:iam::306779470681:role/ToBeDeleted",
            "responses" = {
              "default" = {
                "statusCode" = "200"
              }
            },
            "requestParameters" : {
              "integration.request.header.X-Amz-Target" : "'AWSEvents.PutEvents'",
              "integration.request.header.Content-Type" : "'application/x-amz-json-1.1'"
            },
            "requestTemplates" = {
              "application/json" = <<EOF
{
  "Entries":[{
    "Source":"carrier",
    "Detail":"{\"shipped_at\": $util.escapeJavaScript($input.json('$.shipped_at')),\"order_id\": $util.escapeJavaScript($input.json('$.order_id'))}",
    "DetailType": "carrier.order_shipped",
    "EventBusName": "orders"
  }]
}
EOF
            },
            "passthroughBehavior" : "when_no_templates"
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