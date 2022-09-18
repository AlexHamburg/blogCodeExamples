output "canary" {
  value = aws_synthetics_canary.canary
}

output "canary_function_role" {
  value = aws_iam_role.canary
}

output "canary_cloudwatch_alarm" {
  value = aws_cloudwatch_metric_alarm.canary
}

output "canary_results_bucket" {
  value = aws_s3_bucket.results
}

output "canary_kms_key" {
  value = aws_kms_key.canary
}

# Optional Outputs (if teams_notifications enabled)
output "teams_notification_event_rule" {
  value = aws_cloudwatch_event_rule.cw_alarm
}

output "teams_notification_function" {
  value = aws_lambda_function.teams_notifications
}

output "teams_notification_function_role" {
  value = aws_iam_role.team_notifications_function
}

output "teams_notification_log_group_arn" {
  value = local.teams_notifier_log_group
}

output "teams_notification_logs_table" {
  value = aws_dynamodb_table.notification_logs
}

output "canary_vpc_sec_group" {
  value = aws_security_group.canary_vpc
}
