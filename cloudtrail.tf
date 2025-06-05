###### CLOUDTRAIL START  ######
# No existing module or standard pattern defined by CCoE for CloudTrail. Using direct resource implementation.

resource "aws_cloudtrail" "resource_deletion_trail" {
  name                       = var.cloudtrail_resource_deletion_monitoring
  s3_bucket_name             = module.bef-cloudtrail-storage-s3.s3_bucket_id
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
  cloud_watch_logs_role_arn  = data.aws_iam_role.bef_cloudtrail_role.arn

  event_selector {
    read_write_type                  = "WriteOnly"
    include_management_events        = true
    exclude_management_event_sources = []
  }
  tags = merge(
    var.required_common_tags,
    var.extra_tags,
    {
      Name = "Resource Deletion Monitoring Trail"
    }
  )
}

resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = var.cloudtrail_resource_deletion_log_group
  retention_in_days = 7

  tags = merge(
    var.required_common_tags,
    var.extra_tags,
    {
      Name = "Cloud Trail Log Group"
    }
  )
}

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
