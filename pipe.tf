resource "aws_cloudwatch_log_group" "pipe_log" {
  name = "/aws/events/pipe-logs"
}

resource "aws_iam_role" "pipe_role" {
  name = "EventBridgePipeTasksCreatedRole"

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
    name = "dynamodb"
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
            aws_dynamodb_table.tasks-table.stream_arn
          ]
        }
      ]
    })
  }

  inline_policy {
    name = "logs"
    policy = jsonencode({
      "Version" = "2012-10-17"
      "Statement" = [
        {
          "Effect" = "Allow"
          "Action" = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" = [
            "${aws_cloudwatch_log_group.pipe_log.arn}:*"
          ]
        }
      ]
    })
  }
}

resource "aws_cloudformation_stack" "dynamodb_stream_pipe" {
  name = "new-tasks-stream"

  parameters = {
    RoleArn   = aws_iam_role.pipe_role.arn
    SourceArn = aws_dynamodb_table.tasks-table.stream_arn
    TargetArn = aws_cloudwatch_log_group.pipe_log.arn
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
      "TasksPipe" : {
        "Type" : "AWS::Pipes::Pipe",
        "Properties" : {
          "Name" : "new-tasks-stream-3",
          "RoleArn" : { "Ref" : "RoleArn" }
          "Source" : { "Ref" : "SourceArn" },
          "SourceParameters" : {
            "FilterCriteria": {
              "Filters" : [{"Pattern" : "{\"eventSourceARN\" : [{ \"prefix\":\"${aws_dynamodb_table.tasks-table.arn}/stream\"}]}"}]
            },
            "DynamoDBStreamParameters" : {
              "StartingPosition" : "LATEST"
            }
          }
          "Target" : { "Ref" : "TargetArn" },
          "TargetParameters" : {
            "CloudWatchLogsParameters" : {
              "LogStreamName" : "tasks-created"
            },
            "InputTemplate" : "{\"source\": \"dynamodb.tasks\",\"eventName\": <$.eventName>,\"task\": {\"id\": <$.dynamodb.NewImage.PK.S>,\"state\": <$.dynamodb.NewImage.state.S> } }"
          }
        }
      }
    }
  })
}

#
#
#resource "awscc_pipes_pipe" "dynamodb_stream_pipe" {
#  name     = "new-tasks-stream-2"
#  source   = aws_dynamodb_table.tasks-table.stream_arn
#  target   = aws_cloudwatch_log_group.pipe_log.arn
#  role_arn = aws_iam_role.pipe_role.arn
#  source_parameters = {
#    dynamo_db_stream_parameters = {
#      starting_position = "LATEST"
#    },
#    filter_criteria = {
#      filters = [{ pattern : "{\"eventSourceARN\" : [{ \"prefix\":\"${aws_dynamodb_table.tasks-table.arn}/stream\"}]}" }]
#    }
#  }
#  target_parameters = {
#    input_template = "{\"source\": \"dynamodb.tasks\",\"eventName\": <$.eventName>,\"task\": {\"id\": <$.dynamodb.NewImage.PK.S>,\"state\": <$.dynamodb.NewImage.state.S> } }",
#    cloudwatch_logs_parameters = {
#      log_stream_name = "tasks-created"
#    }
#  }
#}


