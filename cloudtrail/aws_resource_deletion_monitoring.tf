
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "${var.cloudtrail_bucket_name}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name        = "CloudTrail Logs for Resource Deletion Monitoring"
    Environment = var.environment
  }
}


resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_bucket.arn
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current_region.name}:${data.aws_caller_identity.current.account_id}:trail/${var.var.cloudtrail_resource_deletion_monitoring}"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
            "AWS:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current_region.name}:${data.aws_caller_identity.current.account_id}:trail/${var.var.cloudtrail_resource_deletion_monitoring}"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_bucket_pab" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudtrail" "resource_deletion_trail" {
  name                         = var.cloudtrail_resource_deletion_monitoring
  s3_bucket_name              = aws_s3_bucket.cloudtrail_bucket.bucket
  cloud_watch_logs_group_arn  = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
  cloud_watch_logs_role_arn   = aws_iam_role.cloudtrail_logs_role.arn

  event_selector {
    read_write_type                 = "WriteOnly"  
    include_management_events       = true        
    exclude_management_event_sources = []
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_bucket_policy,
    aws_iam_role_policy.cloudtrail_logs_policy
  ]

  tags = {
    Name        = "Resource Deletion Monitoring Trail"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = var.cloudtrail_resource_deletion_log_group
  retention_in_days = 7

  tags = {
    Name        = "CloudTrail Resource Deletion Logs"
    Environment = var.environment
  }
}

resource "aws_iam_role" "cloudtrail_logs_role" {
  name = "${var.cloudtrail_cloudwatch_role_name}-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudtrail_logs_policy" {
  name = "CloudTrail-CloudWatchLogs-Policy-${var.environment}-${data.aws_region.current_region.name}"
  role = aws_iam_role.cloudtrail_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
      }
    ]
  })
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
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ResourceDeletions"
  namespace           = "ResourceDeletion"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This alarm triggers when any AWS resource is deleted"
  alarm_actions       = [var.alarm_sns_topic_arns]
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "Resource Deletion Alarm"
    Environment = var.environment
  }
}
