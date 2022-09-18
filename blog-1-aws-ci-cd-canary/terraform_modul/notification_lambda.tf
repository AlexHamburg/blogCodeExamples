data "aws_s3_bucket_object" "teams_notifications" {
  bucket = local.teams_notifier_bucket
  key    = local.teams_notifier_key
}

resource "aws_lambda_function" "teams_notifications" {
  function_name = "${var.name_prefix}-canary-notifications"
  description   = "send notifications to ms teams channel when canary ${var.name_prefix} alarm goes off"

  role = aws_iam_role.team_notifications_function.arn

  handler = "notifier.lambda_handler"
  runtime = "python3.9"

  s3_bucket         = data.aws_s3_bucket_object.teams_notifications.bucket
  s3_key            = data.aws_s3_bucket_object.teams_notifications.key
  s3_object_version = data.aws_s3_bucket_object.teams_notifications.version_id

  timeout                        = 30
  reserved_concurrent_executions = 1
  environment {
    variables = {
      WEBHOOK_SECRET_ARN   = var.webhook_secret_arn
      LOGS_TABLE           = aws_dynamodb_table.notification_logs.name
      LOGS_EXPIRATION_DAYS = var.logs_retention_days
    }
  }

  tags = local.tags
}

resource "aws_iam_role" "team_notifications_function" {
  name               = "${var.name_prefix}-canary-notifications"
  description        = "Role for MS Teams Notifications Lambda for Canary ${var.name_prefix} Alarms"
  assume_role_policy = data.aws_iam_policy_document.assume_notifications_role.json

  tags = local.tags
}

data "aws_iam_policy_document" "assume_notifications_role" {
  policy_id = "TeamsNotificationsExecutionRoleAssumePolicy"
  statement {
    sid     = "AllowLambdaAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role_policy" "notifications_function_role" {
  role   = aws_iam_role.team_notifications_function.id
  name   = "TeamsNotificationsExecutionRolePolicy"
  policy = data.aws_iam_policy_document.notifications_function_role.json
}

data "aws_iam_policy_document" "notifications_function_role" {
  statement {
    sid    = "AllowLambda${replace(var.name_prefix, "-", "")}WriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      local.teams_notifier_log_group,
      "${local.teams_notifier_log_group}:*"
    ]
  }
  statement {
    sid       = "AllowLambda${replace(var.name_prefix, "-", "")}ReadTeamsURL"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.webhook_secret_arn]
  }

  statement {
    sid    = "AllowLambda${replace(var.name_prefix, "-", "")}WriteLogsToDynamoDB"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem"
    ]
    resources = [aws_dynamodb_table.notification_logs.arn]
  }
}
