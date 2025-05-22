# Lambda related configurations
# Code module
data "archive_file" "general-callback-code" {
  type        = "zip"
  source_dir  = "${path.module}/callback-code"
  output_path = "${path.module}/deployment-archive/general-callback.zip"
}

# Lambda Function
module "general-callback-lambda" {
  source               = "git::https://github.sys.cigna.com/cigna/lambda.git?ref=1.4.0"
  function_name        = var.general-callback-lambda-function-name
  filename             = data.archive_file.general-callback-code.output_path
  source_code_hash     = data.archive_file.general-callback-code.output_base64sha256
  handler              = var.general-callback-handler-function
  runtime              = var.bef-presigned-url-lambda-runtime
  memory_size          = var.bef-presigned-url-lambda_memory_size
  timeout              = var.bef-presigned-url-lambda_timeout_seconds
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

  security_group_ids = [aws_security_group.presigned-url-sg.id]
  role_arn           = data.aws_iam_role.bef_lambda_callback_role.arn
  layers             = [aws_lambda_layer_version.bef-lambda-layer-requests.arn]

  environment_variables = {
    "log_level" = var.log_level,
    "dynamo_db" = aws_dynamodb_table.general-dynamodb-table.id
    "general_purpose_bucket" = local.general-purpose-storage
  }

  depends_on = [data.archive_file.general-callback-code, aws_lambda_layer_version.bef-lambda-layer-requests] # Can start only after package creation completes
}
# --- Lambda Config ends ---


resource "aws_cloudwatch_log_subscription_filter" "cloudwatch-subscription" {
  name            = "${var.general-callback-lambda-function-name}-subscription_filter"
  role_arn        = data.aws_ssm_parameter.org_logging_role.value # NEW REQUIREMENT
  log_group_name  = "/aws/lambda/${module.general-callback-lambda.function_name}"
  filter_pattern  = ""
  destination_arn = data.aws_ssm_parameter.org_logging_arn.value
  distribution    = "Random"
}