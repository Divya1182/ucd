# S3 Bucket related configs
module "bef-storage-s3" {
  source             = "git::https://github.sys.cigna.com/cigna/terraform-aws-s3"
  bucket_name        = local.s3_bucket_name
  required_tags      = var.required_common_tags
  optional_tags      = var.extra_tags
  required_data_tags = var.required_data_tags
  lc_rule_id         = var.lc_rule_id
  bucket_policy      = data.aws_iam_policy_document.presigned-url-s3-policy.json
  providers = {
    aws.replication = aws.crr
    aws.source      = aws
  }
  cors_rule_is_enabled = var.cors_rule_is_enabled
  cors_allowed_headers = var.cors_allowed_headers
  cors_allowed_methods = var.cors_allowed_methods
  cors_allowed_origins = var.cors_allowed_origins

  bucket_encryption_algorithm = "aws:kms"
  bucket_kms_key_id           = module.bef-presigned-url-kms.arn
  enable_bucket_keys          = var.enable_bucket_keys
}

/* resource "aws_s3_bucket_server_side_encryption_configuration" "bef-storage-s3-encryption" {
  depends_on = [module.bef-storage-s3, module.bef-presigned-url-kms]
  bucket     = local.s3_bucket_name
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = module.bef-presigned-url-kms.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = var.enable_bucket_keys
  }
  
} */
# --- S3 Config Ends ---

/* ---- Intent API Infra config ends --- */

