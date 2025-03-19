# Eventbridge rule to trigger callback lambda on file creation

resource "aws_cloudwatch_event_rule" "bef-file-create-rule" {
  name = var.eventbridge_notification_name

  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["Object Created"],
    "detail" : {
      "bucket" : {
        "name" : [local.s3_bucket_name]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "callback-lambda-target" {
  arn  = module.callback-lambda.arn
  rule = aws_cloudwatch_event_rule.bef-file-create-rule.name
} 