# used to get the account id
data "aws_caller_identity" "current" {}
data "aws_region" "current_region" {}

data "aws_iam_role" "bef_lambda_role" {
  name = "BEFStorageSolution"
}

data "aws_iam_role" "bef_lambda_callback_role" {
  name = "BEFStorageSolutionLambdaCallback"
}

# This is to make bucket name unique across accounts
locals {
  s3_bucket_name            = "${var.bef_bucket_name}-${data.aws_caller_identity.current.account_id}"
  crr_s3_bucket_name        = "${var.bef_bucket_name}-${data.aws_caller_identity.current.account_id}-copy"
  bef_s3_bucket_name        = var.region == local.primary_region ? local.s3_bucket_name : local.crr_s3_bucket_name
  def_presigned_url_kms_arn = var.region == local.primary_region ? module.bef-presigned-url-kms[0].arn : data.aws_kms_key.crr_bef_kms_key[0].arn
  primary_region            = "us-east-1"
  general-purpose-storage   = "${var.general-purpose-storage}-${data.aws_caller_identity.current.account_id}"
}
# ----------------------------------------------------------------------------------------------------------------------
# Load the Central Logging Destination ARN
# ----------------------------------------------------------------------------------------------------------------------
data "aws_ssm_parameter" "org_logging_arn" {
  name = "/Enterprise/OrgCentralLoggingDestinationArn"
}

data "aws_ssm_parameter" "org_logging_role" {
  name = "/Enterprise/OrgCentralLoggingRole"
}

data "aws_kms_key" "crr_bef_kms_key" {
  count  = var.region != local.primary_region ? 1 : 0
  key_id = "alias/${var.presigned-url-crr-s3-kms-name}"
}

data "aws_vpc_endpoint" "dynamo-gateway-endpoint" {
  tags = {
    "Name" = var.dynamo-vpc-endpoint
  }
}

