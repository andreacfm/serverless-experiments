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
              "DetailType": "Event from dynamodb-orders-stream pipe"
            },
            "InputTemplate" : "{\"eventName\": <$.eventName>,\"task\": {\"id\": <$.dynamodb.NewImage.PK.S>,\"state\": <$.dynamodb.NewImage.state.S> } }"
          }
        }
      }
    }
  })
}

#resource "aws_pipes_pipe" "dynamodb_stream_pipe" {
#  name     = "dynamodb-orders-stream"
#  source   = aws_dynamodb_table.orders-table.stream_arn
#  target   = aws_cloudwatch_event_bus.orders_bus.arn
#  role_arn = aws_iam_role.orders_pipe_role.arn
#  source_parameters {
#    dynamo_db_stream_parameters = {
#      starting_position = "LATEST",
#      batch_size        = 1
#    }
#  }
#  target_parameters {
#    input_template = "{\"source\": \"dynamodb.orders\",\"eventName\": <$.eventName>,\"task\": {\"id\": <$.dynamodb.NewImage.PK.S>,\"state\": <$.dynamodb.NewImage.state.S> } }"
#    event_bridge_event_bus_parameters {
#      source = "dynamodb.orders"
#    }
#  }
#}


