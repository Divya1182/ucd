
data "archive_file" "resource_deletion_monitoring" {
  type        = "zip"
  source_dir  = "${path.module}/resource_deletion_monitoring_code"
  output_path = "${path.module}/resource-deletion-monitoring-deployment-archive/resource_deletion_monitoring.zip"
}

# Lambda Function
module "resource_deletion_monitoring" {
  source               = "git::https://github.sys.cigna.com/cigna/lambda.git?ref=1.4.0"
  function_name        = var.resource_deletion_monitoring_lambda_function_name
  filename             = data.archive_file.resource_deletion_monitoring.output_path
  source_code_hash     = data.archive_file.resource_deletion_monitoring.output_base64sha256
  handler              = var.resource_deletion_monitoring_lambda_handler_function
  runtime              = var.resource_deletion_monitoring_lambda_runtime
  memory_size          = var.resource_deletion_monitoring_lambda_memory_size
  timeout              = var.resource_deletion_monitoring_lambda_timeout_seconds
  required_tags        = var.required_common_tags
  optional_tags        = var.extra_tags
  alarm_env            = var.environment
  alarm_app_name       = var.alarm_app_name
  alarm_sns_topic_arns = var.alarm_sns_topic_arns
  alarm_thresholds     = var.alarm_thresholds
  role_arn           = data.aws_iam_role.resource_deletion_monitoring.arn

  environment_variables = {
    "log_level"              = var.log_level,
    SNS_TOPIC_ARN = "${aws_sns_topic.deletion_notifications.arn}"

  }

  depends_on = [data.archive_file.resource_deletion_monitoring]
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.resource_deletion_monitoring.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.deletion_rule.arn
}

