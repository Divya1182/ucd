resource "aws_cloudwatch_metric_alarm" "s3_alarm_4xx" {
  count = var.enable_bucket_400_error_alarm ? 1 : 0

  alarm_actions = ["arn:aws:sns:${var.alarm_region}:${var.alarm_account}:cloudwatch-alarm-funnel"]
  alarm_description = format(
    "%s|%s|%s|%s|%s-%s",
    local.alarm_env,
    local.bucket_400_error_alarm_severity,
    var.alarm_app_name,
    data.aws_iam_account_alias.current.account_alias,
    aws_s3_bucket.this.bucket,
    "400 errors threshold met"
  )
  alarm_name          = "${var.bucket_name}-400-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "4xxErrors"
  namespace           = "AWS/S3"
  period              = var.alarm_period
  statistic           = "Sum"
  threshold           = var.alarm_threshold_4xx
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName = aws_s3_bucket.this.bucket
    FilterId   = "EntireBucket"
  }

  tags = merge(var.required_tags, {
    AppName     = var.app_name
    AssetName   = "${var.bucket_name}-4xx-alarm"
    Environment = local.environment
    Purpose     = "Trigger cloudwatch warning when threshold for 400s is met"
    Version     = local.version
  })
}

resource "aws_cloudwatch_metric_alarm" "s3_alarm_5xx" {
  count = var.enable_bucket_500_error_alarm ? 1 : 0

  alarm_actions = ["arn:aws:sns:${var.alarm_region}:${var.alarm_account}:cloudwatch-alarm-funnel"]
  alarm_description = format(
    "%s|%s|%s|%s|%s-%s",
    local.alarm_env,
    local.bucket_500_error_alarm_severity,
    var.alarm_app_name,
    data.aws_iam_account_alias.current.account_alias,
    aws_s3_bucket.this.bucket,
    "500 errors threshold met"
  )
  alarm_name          = "${var.bucket_name}-500-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "5xxErrors"
  namespace           = "AWS/S3"
  period              = var.alarm_period
  statistic           = "Sum"
  threshold           = var.alarm_threshold_5xx
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName = aws_s3_bucket.this.bucket
    FilterId   = "EntireBucket"
  }

  tags = merge(var.required_tags, {
    AppName     = var.app_name
    AssetName   = "${var.bucket_name}-5xx-alarm"
    Environment = local.environment
    Purpose     = "Trigger cloudwatch warning when threshold for 500s is met"
    Version     = local.version
  })
}