resource "aws_cloudwatch_event_rule" "cw_alarm" {
  name          = "${var.name_prefix}-cw-alarm"
  description   = "trigger notification lambda for canary alerts of ${var.name_prefix}"
  event_pattern = <<EOF
{
  "source": [
    "aws.cloudwatch"
  ],
  "detail-type": [
    "CloudWatch alarm state has been Changed"
  ],
  "resources": [
    "${aws_cloudwatch_metric_alarm.canary.arn}"
  ],
  "detail": {
    "state": {
        "value": ["ALARM"]
    }
  }
}
EOF

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "notification_lambda" {
  target_id = aws_lambda_function.teams_notifications.function_name
  rule      = aws_cloudwatch_event_rule.cw_alarm.name
  arn       = aws_lambda_function.teams_notifications.arn
  retry_policy {
    maximum_event_age_in_seconds = 21600
    maximum_retry_attempts       = 100
  }
}

resource "aws_lambda_permission" "allow_eventbridge_call_notifications_function" {
  function_name = aws_lambda_function.teams_notifications.function_name
  statement_id  = "AllowInvokeNotificationsLambdaByEventBridge"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cw_alarm.arn
}
