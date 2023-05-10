resource "aws_cloudwatch_log_group" "pipe_log" {
  name = "/aws/events/pipe-logs"
}

resource "aws_iam_role" "pipe_role" {
  name = "EventBridgePipeTasksCreatedRole"

  assume_role_policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Effect" ="Allow"
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
      "Version"= "2012-10-17"
      "Statement"= [
        {
          "Effect"= "Allow"
          "Action"= [
            "dynamodb:DescribeStream",
            "dynamodb:GetRecords",
            "dynamodb:GetShardIterator",
            "dynamodb:ListStreams"
          ],
          "Resource"= [
            aws_dynamodb_table.tasks-table.stream_arn
          ]
        }
      ]
    })
  }

  inline_policy {
    name = "logs"
    policy = jsonencode({
      "Version"= "2012-10-17"
      "Statement"= [
        {
          "Effect"= "Allow"
          "Action"= [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource"= [
            "${aws_cloudwatch_log_group.pipe_log.arn}:*"
          ]
        }
      ]
    })
  }
}

resource "awscc_pipes_pipe" "dynamodb_stream_pipe" {
  name   = "new-tasks-stream"
  source = aws_dynamodb_table.tasks-table.stream_arn
  target = aws_cloudwatch_log_group.pipe_log.arn
  role_arn = aws_iam_role.pipe_role.arn
  source_parameters = {
    dynamo_db_stream_parameters = {
      starting_position = "LATEST"
    }
  }
  target_parameters = {
    cloudwatch_logs_parameters = {
      log_stream_name = "tasks-created"
    }
  }
}