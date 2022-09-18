resource "aws_cloudwatch_metric_alarm" "canary" {
  alarm_name        = "Synthetics-Canary-Alarm-${var.name_prefix}-1"
  alarm_description = "alarm for any failed executions of the canary for ${var.name_prefix}"
  namespace   = "CloudWatchSynthetics"
  metric_name = "Failed"
  dimensions = {
    CanaryName = var.name_prefix
  }
  unit = "Count"
  period              = var.canary_schedule * 60 //seconds
  statistic           = "Sum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  evaluation_periods  = var.alarm_threshold_time / var.canary_schedule
  datapoints_to_alarm = var.alarm_threshold_time / var.canary_schedule
  treat_missing_data  = "notBreaching"
  tags = local.tags
}
