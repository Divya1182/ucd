# EventBridge rule to invoke general callback lambda
resource "aws_cloudwatch_event_rule" "general-bucket-file-create-rule" {
  name = var.callback-notification-name
  event_pattern = jsonencode({
    "source"      : ["aws.s3"],
    "detail-type" : ["Object Created"],
    "detail"      : {
                      "bucket" : {
                        "name" : [local.general-purpose-storage]
                      }
                    }
  })
  depends_on = [module.bef-general-storage-s3]
}

# EventBridge rule target
resource "aws_cloudwatch_event_target" "callback-lambda-target" {
  arn  = module.general-callback-lambda.arn
  rule = aws_cloudwatch_event_rule.general-bucket-file-create-rule.name
  depends_on = [module.general-callback-lambda, aws_cloudwatch_event_rule.general-bucket-file-create-rule]
}

# Enable EventBridge notification in General Purpose Bucket
resource "aws_s3_bucket_notification" "enable-eventbridge-notification" {
  bucket      = local.general-purpose-storage
  eventbridge = true
  depends_on = [module.bef-general-storage-s3, module.general-callback-lambda]
}

# Lambda Invoke permission from EventBridge
resource "aws_lambda_permission" "eventbridge-rule-execution-permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.general-callback-lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.general-bucket-file-create-rule.arn
  depends_on = [module.bef-general-storage-s3, module.general-callback-lambda, aws_cloudwatch_event_rule.general-bucket-file-create-rule]
}