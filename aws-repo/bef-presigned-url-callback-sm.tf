# Secret Manager Block for Intent Artifact START
resource "aws_secretsmanager_secret" "intent_consumer" {
  depends_on = [module.bef-presigned-url-kms]
  name        = var.intent-consumer-secret-name
  description = "Intent API Consumer Secret"
  kms_key_id  = module.bef-presigned-url-kms[0].arn
  tags        = merge(var.required_common_tags, var.extra_tags)
}

resource "aws_secretsmanager_secret_version" "intent_consumer_version" {
  secret_id      = aws_secretsmanager_secret.intent_consumer.id
  secret_string  = var.intent_callback_endpoint
  version_stages = ["AWSCURRENT"]
}
# Secret Manager Block for Intent Artifact END