resource "aws_cloudwatch_log_group" "orders_pipe_log" {
  name = "/orders/events/pipe-logs"
}

resource "aws_iam_role" "orders_pipe_role" {
  name = "EventBridgePipeOrdersRole"

  assume_role_policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Effect" = "Allow"
        "Principal" = {
          "Service" = "pipes.amazonaws.com"
        },
        "Action" = "sts:AssumeRole"
        "Condition" = {
          "StringEquals" = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  inline_policy {
    name = "AllowReadDynamoDbOrdersStream"
    policy = jsonencode({
      "Version" = "2012-10-17"
      "Statement" = [
        {
          "Effect" = "Allow"
          "Action" = [
            "dynamodb:DescribeStream",
            "dynamodb:GetRecords",
            "dynamodb:GetShardIterator",
            "dynamodb:ListStreams"
          ],
          "Resource" = [
            aws_dynamodb_table.orders-table.stream_arn
          ]
        }
      ]
    })
  }

  inline_policy {
    name = "AllowPutEventsToOrdersBus"
    policy = jsonencode({
      "Version" = "2012-10-17"
      "Statement" = [
        {
          "Effect" = "Allow"
          "Action" = [
            "events:PutEvents"
          ],
          "Resource" = [
            aws_cloudwatch_event_bus.orders_bus.arn
          ]
        }
      ]
    })
  }
}


resource "aws_cloudformation_stack" "dynamodb_stream_pipe" {
  name = "dynamodb-orders-stream"

  parameters = {
    RoleArn   = aws_iam_role.orders_pipe_role.arn
    SourceArn = aws_dynamodb_table.orders-table.stream_arn
    TargetArn = aws_cloudwatch_event_bus.orders_bus.arn
  }

  template_body = jsonencode({
    "Parameters" : {
      "SourceArn" : {
        "Type" : "String",
      },
      "TargetArn" : {
        "Type" : "String",
      },
      "RoleArn" : {
        "Type" : "String"
      }
    },
    "Resources" : {
      "OrdersPipe" : {
        "Type" : "AWS::Pipes::Pipe",
        "Properties" : {
          "Name" : "dynamodb-orders-stream",
          "RoleArn" : { "Ref" : "RoleArn" }
          "Source" : { "Ref" : "SourceArn" },
          "SourceParameters" : {
            "DynamoDBStreamParameters" : {
              "StartingPosition" : "LATEST",
              "BatchSize" : 1
            }
          }
          "Target" : { "Ref" : "TargetArn" },
          "TargetParameters" : {
            "EventBridgeEventBusParameters" : {
              "Source" : "dynamodb.orders",
              "DetailType": "dynamodb-orders-stream"
            },
            "InputTemplate" : "{\"eventName\": <$.eventName>,\"order\": {\"id\": <$.dynamodb.NewImage.PK.S>,\"state\": <$.dynamodb.NewImage.state.S> } }"
          }
        }
      }
    }
  })
}


