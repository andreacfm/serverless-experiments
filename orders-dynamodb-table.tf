resource "aws_dynamodb_table" "orders-table" {
  name             = "orders"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "PK"
  stream_view_type = "NEW_IMAGE"
  stream_enabled   = true

  attribute {
    name = "PK"
    type = "S"
  }
}
