resource "aws_s3_bucket" "results" {
  bucket        = "${data.aws_caller_identity.whoami.account_id}-${var.name_prefix}"
  force_destroy = var.force_destroy
  tags          = local.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "results_lifecycle_configuration" {
  bucket = aws_s3_bucket.results.bucket

  rule {
    id = "housekeeping"
    expiration {
      days = max(var.canary_retention_days.success, var.canary_retention_days.failure)
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "server_side_encryption" {
  bucket = aws_s3_bucket.results.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.canary.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_acl" "example_bucket_acl" {
  bucket = aws_s3_bucket.results.bucket
  acl    = "private"
}