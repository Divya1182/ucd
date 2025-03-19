locals {
  consumer_credential_map = {
    consumer_id     = var.intent_consumer_key
    consumer_secret = var.intent_consumer_secret
  }
}

resource "aws_secretsmanager_secret" "intent_consumer" {
  name        = var.intent_consumer_secret_name
  description = "Intent API Consumer Secret"
  kms_key_id  = module.bef-presigned-url-kms.arn
  tags        = merge(var.required_common_tags, var.extra_tags)
}

resource "aws_secretsmanager_secret_version" "intent_consumer_version" {
  secret_id      = aws_secretsmanager_secret.intent_consumer.id
  secret_string  = jsonencode(local.consumer_credential_map)
  version_stages = ["AWSCURRENT"]
}