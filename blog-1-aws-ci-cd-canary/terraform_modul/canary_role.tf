resource "aws_iam_role" "canary" {
  name               = "${var.name_prefix}-canary"
  description        = "Role for ${var.name_prefix} Lambda Function (Syntatic canary)"
  assume_role_policy = data.aws_iam_policy_document.assume_canary_role.json

  tags = local.tags
}

data "aws_iam_policy_document" "assume_canary_role" {
  policy_id = "SyntheticsCanaryExecutionRoleAssumePolicy"
  statement {
    sid     = "AllowSyntheticsAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role_policy" "canary_basic_permissions" {
  role   = aws_iam_role.canary.id
  name   = "SyntheticsCanaryExecutionRoleBasicPolicy"
  policy = data.aws_iam_policy_document.canary_role_basic.json
}

data "aws_iam_policy_document" "canary_role_basic" {
  statement {
    sid       = "AllowSynthetic${replace(var.name_prefix, "-", "")}ListBuckets"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
  statement {
    sid       = "AllowSynthetic${replace(var.name_prefix, "-", "")}FindBucketRegion"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [aws_s3_bucket.results.arn]
  }
  statement {
    sid       = "AllowSynthetic${replace(var.name_prefix, "-", "")}StoreResultsInS3"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.results.arn}/*"]
  }
  statement {
    sid    = "AllowSynthetic${replace(var.name_prefix, "-", "")}WriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.whoami.account_id}:log-group:/aws/lambda/cwsyn-${var.name_prefix}*",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.whoami.account_id}:log-group:/aws/lambda/cwsyn-${var.name_prefix}*:*"
    ]
  }
  statement {
    sid       = "AllowSyntheticsWriteMetrics"
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }
  statement {
    sid       = "AllowSyntheticsSecretManager"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "canary_tracing_permissions" {
  role   = aws_iam_role.canary.id
  name   = "SyntheticsCanaryExecutionRoleTracingPolicy"
  policy = data.aws_iam_policy_document.canary_role_tracing.json
}

data "aws_iam_policy_document" "canary_role_tracing" {
  statement {
    sid       = "AllowSyntheticsPutTraceSegments"
    effect    = "Allow"
    actions   = ["xray:PutTraceSegments"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "canary_vpc_permissions" {
  role   = aws_iam_role.canary.id
  name   = "SyntheticsCanaryExecutionRoleVPCPolicy"
  policy = data.aws_iam_policy_document.canary_role_vpc.json
}

data "aws_iam_policy_document" "canary_role_vpc" {
  statement {
    sid    = "AllowWorkWithNetworkInteracesForVPCAccess"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:AttachNetworkInterface"
    ]
    resources = ["*"]
  }
}
