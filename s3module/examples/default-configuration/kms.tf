resource "aws_kms_key" "key" {
  deletion_window_in_days = 7
  description             = "CMK for the s3-default-example bucket"
  enable_key_rotation     = true
  is_enabled              = true

  policy = templatefile("${path.module}/kms_key_policy.tmpl", {
    kms_accounts           = jsonencode(var.kms_accounts)
    kms_key_administrators = jsonencode(var.kms_key_administrators)
    kms_key_users          = jsonencode(var.kms_key_users)
  })

}