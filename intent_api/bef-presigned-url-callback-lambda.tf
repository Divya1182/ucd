# Lambda related configurations
# Code module
data "archive_file" "callback-lambda-code" {
  type        = "zip"
  source_dir  = "${path.module}/callback-lambda-code"
  output_path = "${path.module}/deployment-archive/callback-lambda.zip"
}

# Lambda Function
module "callback-lambda" {
  source               = "git::https://github.sys.cigna.com/cigna/lambda.git?ref=1.4.0"
  function_name        = var.bef-callback-lambda-function-name
  filename             = data.archive_file.callback-lambda-code.output_path
  source_code_hash     = data.archive_file.callback-lambda-code.output_base64sha256
  handler              = var.bef-callback-lambda-handler-function
  runtime              = var.bef-callback-lambda-runtime
  memory_size          = var.bef-callback-lambda_memory_size
  timeout              = var.bef-callback-lambda_timeout_seconds
  required_tags        = var.required_common_tags
  optional_tags        = var.extra_tags
  alarm_env            = var.environment
  alarm_app_name       = var.alarm_app_name
  alarm_sns_topic_arns = var.alarm_sns_topic_arns
  alarm_thresholds     = var.alarm_thresholds
  subnet_ids = [
    module.presigned-url-vpc.subnets_routable_by_az["${data.aws_region.current_region.name}a"][0].id,
    module.presigned-url-vpc.subnets_routable_by_az["${data.aws_region.current_region.name}b"][0].id
  ]
  layers = [aws_lambda_layer_version.bef-lambda-layer-requests.arn]

  security_group_ids = [aws_security_group.presigned-url-sg.id]
  role_arn           = data.aws_iam_role.bef_lambda_callback_role.arn

  environment_variables = {
    "log_level"         = var.log_level,
    "callback_url"      = var.callback-url,
    "token_service_url" = var.token-service-url,
    "secret_name"       = aws_secretsmanager_secret.intent_consumer.name,
    "aws_region"        = data.aws_region.current_region.name
  }

  depends_on = [
    data.archive_file.callback-lambda-code,
    aws_secretsmanager_secret.intent_consumer
  ] # Can start only after package creation completes
}

resource "aws_cloudwatch_log_subscription_filter" "callback-subscription" {
  name            = "${var.bef-callback-lambda-function-name}-subscription_filter"
  role_arn        = data.aws_ssm_parameter.org_logging_role.value # NEW REQUIREMENT
  log_group_name  = "/aws/lambda/${module.callback-lambda.function_name}"
  filter_pattern  = ""
  destination_arn = data.aws_ssm_parameter.org_logging_arn.value
  distribution    = "Random"
}

# Execution permission from eventbridge rule
resource "aws_lambda_permission" "eventbridge-rule-execution-permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.callback-lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.bef-file-create-rule.arn
} 