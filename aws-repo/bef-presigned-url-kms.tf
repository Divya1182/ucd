module "bef-presigned-url-kms" {
  count                    = var.region == local.primary_region ? 1 : 0
  source                   = "git::https://github.sys.cigna.com/cigna/thub-gov-terraform-kms.git"
  name                     = var.presigned-url-kms-name
  description              = var.presigned-url-kms-description
  customer_master_key_spec = var.presigned-url-kms-customer-master-key-spec
  enable_key_rotation      = var.presigned-url-kms-enable-key-rotation
  policy                   = data.aws_iam_policy_document.presigned-url-kms-iam-policy[0].json
  tags                     = merge(var.required_common_tags, var.extra_tags)
}

module "bef-presigned-url-crr-s3-kms" {
  count = var.enable_crr ? 1 : 0
  providers = {
    aws = aws.crr
  }
  source                   = "git::https://github.sys.cigna.com/cigna/thub-gov-terraform-kms.git"
  name                     = var.presigned-url-crr-s3-kms-name
  description              = var.presigned-url-crr-s3-kms-description
  customer_master_key_spec = var.presigned-url-crr-s3-kms-customer-master-key-spec
  enable_key_rotation      = var.presigned-url-crr-s3-kms-enable-key-rotation
  policy                   = data.aws_iam_policy_document.presigned-url-crr-s3-kms-iam-policy[0].json
  tags                     = merge(var.required_common_tags, var.extra_tags)
}
