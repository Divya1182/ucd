module "bef-presigned-url-kms" {
  source                   = "git::https://github.sys.cigna.com/cigna/thub-gov-terraform-kms.git"
  name                     = var.presigned-url-kms-name
  description              = var.presigned-url-kms-description
  customer_master_key_spec = var.presigned-url-kms-customer-master-key-spec
  enable_key_rotation      = var.presigned-url-kms-enable-key-rotation
  policy                   = data.aws_iam_policy_document.presigned-url-kms-iam-policy.json
  tags                     = merge(var.required_common_tags, var.extra_tags)
}