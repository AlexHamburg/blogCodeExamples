resource "aws_synthetics_canary" "canary" {
  depends_on = [null_resource.wait_for_role]

  artifact_s3_location = "s3://${aws_s3_bucket.results.bucket}/results"
  execution_role_arn   = aws_iam_role.canary.arn
  name                 = var.name_prefix
  handler              = var.canary_handler
  runtime_version      = var.canary_runtime
  schedule {
    expression = "rate(${var.canary_schedule == 1 ? "${var.canary_schedule} minute" : "${var.canary_schedule} minutes"})"
  }
  failure_retention_period = var.canary_retention_days.failure
  success_retention_period = var.canary_retention_days.success
  run_config {
    timeout_in_seconds = var.canary_runtime_timeout
    memory_in_mb       = var.canary_memory
    active_tracing     = var.canary_tracing
  }
  zip_file     = data.archive_file.canary_function.output_path
  start_canary = false
  vpc_config {
    subnet_ids         = var.canary_vpc_config.subnet_ids
    security_group_ids = [aws_security_group.canary_vpc.id]
  }

  lifecycle {
    ignore_changes = [start_canary]
  }

  tags = local.tags
}

resource "aws_s3_bucket" "s3_bucket_with_request_body" {
  bucket        = "${var.s3_bucket_name_requests}"
  force_destroy = var.force_destroy
  tags          = local.tags
}

resource "aws_s3_bucket_acl" "s3_bucket_with_request_body_bucket_acl" {
  bucket = aws_s3_bucket.s3_bucket_with_request_body.bucket
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "s3_bucket_with_request_body_versioning" {
  bucket = aws_s3_bucket.s3_bucket_with_request_body.id
  versioning_configuration {
    status = "Enabled"
  }
}

data "archive_file" "canary_function" {
  type = "zip"
  source {
    content  = file(var.canary_source)
    filename = length(regexall(".*python.*", var.canary_runtime)) > 0 ? "python/canary.py" : "nodejs/node_modules/canary.js"
  }
  output_path = "${path.root}/canary-${filemd5(var.canary_source)}.zip"
}

resource "null_resource" "wait_for_role" {
  depends_on = [aws_iam_role.canary]

  provisioner "local-exec" {
    command = "sleep 60"
  }
}

resource "aws_security_group" "canary_vpc" {
  name        = "${var.name_prefix}-syntatic-canary-vpc"
  description = "canary function firewall rules"
  vpc_id      = var.canary_vpc_config.vpc_id
  tags        = local.tags
}

resource "aws_security_group_rule" "canary_vpc_aws_apis" {
  security_group_id = aws_security_group.canary_vpc.id
  description       = "egress https for canary to connect to required AWS APIs"
  type      = "egress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443
  cidr_blocks = [var.canary_vpc_config.canary_aws_api_cidr]
}
