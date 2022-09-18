resource "aws_dynamodb_table" "notification_logs" {
  name         = "${var.name_prefix}-canary-notification-logs"
  billing_mode = "PAY_PER_REQUEST"
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.canary.arn
  }
  hash_key = "timestamp"
  attribute {
    name = "timestamp"
    type = "S"
  }
  ttl {
    enabled        = true
    attribute_name = "expiration"
  }

  tags = local.tags
}
