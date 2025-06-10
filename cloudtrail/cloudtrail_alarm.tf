resource "aws_cloudwatch_log_metric_filter" "resource_deletion_filter" {
  name           = "Resource-Deletion-Filter-${var.environment}-${data.aws_region.current_region.name}"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name
  pattern        = "{ $.eventName = Delete* || $.eventName = Terminate* || $.eventName = Remove* || $.eventName = Destroy* }"

  metric_transformation {
    name          = "ResourceDeletions"
    namespace     = "ResourceDeletion"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "resource_deletion_alarm" {
  alarm_name          = "${var.resource_deletion_alarm_name}-${var.environment}"
  alarm_description  = "${var.environment} | WARN | ${var.alarm_app_name} | AWS Resource is deleted"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ResourceDeletions"
  namespace           = "ResourceDeletion"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_actions       = var.alarm_sns_topic_arns
  treat_missing_data  = "notBreaching"

  tags = merge(
    var.required_common_tags,
    var.extra_tags,
    {
      Name = "Resource Deletion Alarm"
    }
  )
}
