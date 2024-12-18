# Lambda related configurations
# Code module
data "archive_file" "presigned-url-code" {
  type = "zip"
  source_file = "${path.module}/presigned-url-code/presigned-url.py"
  output_path = "${path.module}/deployment-archive/presigned-url.zip"
}

# Lambda Function
module "presigned-url-lambda" {
  source                = "git::https://github.sys.cigna.com/cigna/lambda.git?ref=1.4.0"
  function_name         = var.bef-presigned-url-lambda-function-name
  filename              = data.archive_file.presigned-url-code.output_path
  source_code_hash      = data.archive_file.presigned-url-code.output_base64sha256
  handler               = var.bef-presigned-url-lambda-handler-function
  runtime               = var.bef-presigned-url-lambda-runtime
  memory_size           = var.bef-presigned-url-lambda_memory_size
  timeout               = var.bef-presigned-url-lambda_timeout_seconds
  required_tags         = var.required_common_tags
  optional_tags         = var.extra_tags
  alarm_env             = var.environment
  alarm_app_name        = var.alarm_app_name
  alarm_sns_topic_arns  = var.alarm_sns_topic_arns
  alarm_thresholds      = var.alarm_thresholds
  subnet_ids            = [ 
                            module.presigned-url-vpc.subnets_routable_by_az["${data.aws_region.current_region.name}a"][0].id,
                            module.presigned-url-vpc.subnets_routable_by_az["${data.aws_region.current_region.name}b"][0].id
                          ]

  security_group_ids    = [aws_security_group.presigned-url-sg.id]
  role_arn              = data.aws_iam_role.bef_lambda_role.arn

  environment_variables = {
                            "log_level"   = var.log_level
                          }

  depends_on            = [ data.archive_file.presigned-url-code ] # Can start only after package creation completes
}

# Lambda Invoke permission for Authinator API
resource "aws_lambda_permission" "authinator_permission" {
  statement_id  = "GATEWAY"
  action        = "lambda:InvokeFunction"
  function_name =  module.presigned-url-lambda.function_name
  principal     = var.authinator-principal-arn
}
# --- Lambda Config ends ---


