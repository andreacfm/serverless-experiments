resource "aws_dynamodb_table" "tasks-table" {
  name             = "tasks"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "PK"
  stream_view_type = "NEW_IMAGE"
  stream_enabled   = true

  attribute {
    name = "PK"
    type = "S"
  }
}
