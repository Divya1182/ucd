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

  use_default_lc_configuration = false
  enable_crr                   = var.enable_crr
  crr_bucket_kms_key_id        = var.enable_crr ? module.bef-presigned-url-crr-s3-kms[0].arn : ""
  crr_bucket_policy            = var.enable_crr ? data.aws_iam_policy_document.presigned-url-crr-s3-policy[0].json : ""
  crr_role_arn                 = var.enable_crr ? aws_iam_role.crr_s3_replication_role[0].arn : ""
}

# Enable eventbridge notification for the S3 bucket
resource "aws_s3_bucket_notification" "enable-eventbridge-notification" {
  eventbridge = true
  bucket      = local.s3_bucket_name
}
# --- S3 Config Ends ---

/* ---- Intent API Infra config ends --- */

resource "aws_s3_bucket_replication_configuration" "crr_bucket_replication_configuration" {
  depends_on = [module.bef-storage-s3]
  count      = var.enable_crr ? 1 : 0
  provider = aws.crr
  bucket     = local.crr_s3_bucket_name
  role       = aws_iam_role.source_crr_s3_replication_role[0].arn
  rule {
    id = "${local.crr_s3_bucket_name}-crr-source"
    filter {
      prefix = ""
    }
    delete_marker_replication {
      status = var.delete_marker_replication_status
    }
    status = "Enabled"
    destination {
      bucket = module.bef-storage-s3.s3_bucket_arn
      encryption_configuration {
        replica_kms_key_id = module.bef-presigned-url-kms.arn
      }
      storage_class = "STANDARD"
    }
    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }
  }
}

