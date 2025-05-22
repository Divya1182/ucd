resource "aws_dynamodb_table" "general-dynamodb-table" {
  name         = var.dynamo-tablename
  billing_mode = var.dynamo-billing_mode
  hash_key     = "document_id"

  global_secondary_index {
    name            = "FilePathIndex"
    hash_key        = "location"
    projection_type = "KEYS_ONLY"
  }

  attribute {
    name = "document_id"
    type = "S"
  }

  attribute {
    name = "location"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = module.bef-presigned-url-kms[0].arn
  }

  point_in_time_recovery {
    enabled = var.dynamo-PITR
  }

  deletion_protection_enabled = true

  tags = merge(var.required_common_tags, var.required_data_tags, var.extra_tags)
}

##########################################################################
# DYNAMO DB ALERTS #
##########################################################################

resource "aws_cloudwatch_metric_alarm" "dynamo_db_5xx_errors" {
  alarm_name          = "${var.dynamo-tablename}-dynamo_db_5xx_errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  threshold           = 1
  # YOU MUST FILL OUT ALARM DESCRIPTION WITH CORRECT VALUES
  alarm_description  = "${var.environment} | WARN | ${var.alarm_app_name} | dynamo_db_5xx_errors threshold crossed 1 for s3 search"
  alarm_actions      = var.alarm_sns_topic_arns
  treat_missing_data = "notBreaching"
  metric_name        = "SystemErrors"
  namespace          = "AWS/DynamoDB"
  period             = 180
  statistic          = "Sum"
  tags               = merge(var.required_common_tags, var.required_data_tags, var.extra_tags)
  dimensions = {
    TableName = "${var.dynamo-tablename}"
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamo_db_4xx_errors" {
  alarm_name          = "${var.dynamo-tablename}-dynamo_db_4xx_errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  threshold           = 5
  # YOU MUST FILL OUT ALARM DESCRIPTION WITH CORRECT VALUES
  alarm_description  = "${var.environment} | INFO | ${var.alarm_app_name} | dynamo_db_4xx_errors threshold crossed 5 for s3 search"
  alarm_actions      = var.alarm_sns_topic_arns
  treat_missing_data = "notBreaching"
  metric_name        = "UserErrors"
  namespace          = "AWS/DynamoDB"
  period             = 180
  statistic          = "Sum"
  tags               = merge(var.required_common_tags, var.required_data_tags, var.extra_tags)
  dimensions = {
    TableName = "${var.dynamo-tablename}"
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamo_db_consumed_read_capacity" {
  alarm_name          = "${var.dynamo-tablename}-dynamo_db_consumed_read_capacity"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  threshold           = 200
  # YOU MUST FILL OUT ALARM DESCRIPTION WITH CORRECT VALUES
  alarm_description  = "${var.environment} | WARN | ${var.alarm_app_name} | dynamo_db_consumed_read_capacity threshold crossed 200 for s3 search"
  alarm_actions      = var.alarm_sns_topic_arns
  treat_missing_data = "notBreaching"
  metric_name        = "ConsumedReadCapacityUnits"
  namespace          = "AWS/DynamoDB"
  period             = 300
  statistic          = "Sum"
  tags               = merge(var.required_common_tags, var.required_data_tags, var.extra_tags)
  dimensions = {
    TableName = "${var.dynamo-tablename}"
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamo_db_consumed_write_capacity" {
  alarm_name          = "${var.dynamo-tablename}-dynamo_db_consumed_write_capacity"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  threshold           = 200
  # YOU MUST FILL OUT ALARM DESCRIPTION WITH CORRECT VALUES
  alarm_description  = "${var.environment} | INFO | ${var.alarm_app_name} | dynamo_db_consumed_write_capacity threshold crossed 200 for s3 search"
  alarm_actions      = var.alarm_sns_topic_arns
  treat_missing_data = "notBreaching"
  metric_name        = "ConsumedWriteCapacityUnits"
  namespace          = "AWS/DynamoDB"
  period             = 300
  statistic          = "Sum"
  tags               = merge(var.required_common_tags, var.required_data_tags, var.extra_tags)
  dimensions = {
    TableName = "${var.dynamo-tablename}"
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamo_db_get_item_latency" {
  alarm_name          = "${var.dynamo-tablename}-dynamo_db_get_item_latency"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  threshold           = 500
  # YOU MUST FILL OUT ALARM DESCRIPTION WITH CORRECT VALUES
  alarm_description  = "${var.environment} | WARN | ${var.alarm_app_name} | dynamo_db_get_item_latency threshold crossed 500 in 3 evaluation_periods"
  alarm_actions      = var.alarm_sns_topic_arns
  treat_missing_data = "notBreaching"
  metric_name        = "SuccessfulRequestLatency"
  namespace          = "AWS/DynamoDB"
  period             = 180
  statistic          = "Average"
  tags               = merge(var.required_common_tags, var.required_data_tags, var.extra_tags)
  dimensions = {
    TableName = "${var.dynamo-tablename}"
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamo_db_put_item_latency" {
  alarm_name          = "${var.dynamo-tablename}-dynamo_db_put_item_latency"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 100
  # YOU MUST FILL OUT ALARM DESCRIPTION WITH CORRECT VALUES
  alarm_description  = "${var.environment} | WARN | ${var.alarm_app_name} | dynamo_db_put_item_latency threshold crossed 100 in 1 evaluation_periods"
  alarm_actions      = var.alarm_sns_topic_arns
  treat_missing_data = "notBreaching"
  metric_name        = "ReplicationLatency"
  namespace          = "AWS/DynamoDB"
  period             = 300
  statistic          = "Average"
  tags               = merge(var.required_common_tags, var.required_data_tags, var.extra_tags)
  dimensions = {
    TableName = "${var.dynamo-tablename}"
  }
}

##########################################################################