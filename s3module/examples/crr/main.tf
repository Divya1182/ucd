terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}


provider "aws" {
  profile = "saml"
  region  = "us-east-1"
}

provider "aws" {
  alias   = "crr"
  profile = "saml"
  region  = "us-west-1"
}

module "s3" {
  bucket_kms_key_id = aws_kms_key.key.arn
  bucket_name       = "s3-default-example"
  # A role should be passed in from a data source, but this doesn't exist in the test account so we hard code for the
  # example
  # crr_role_arn   = data.aws_iam_role.replication_role.arn
  crr_bucket_kms_key_id = aws_kms_key.crr_key.arn
  crr_role_arn          = "arn:aws:iam::12345:role/Enterprise/S3CRR"
  enable_crr            = true
  lc_rule_id            = "s3-default-lifecycle-rule"
  source                = "../../"

  bucket_policy = templatefile("${path.module}/s3_policy.tmpl", {
    bucket_resources = jsonencode(var.s3_default_resources)
    key_users        = jsonencode(var.s3_default_users),
  })

  crr_bucket_policy = templatefile("${path.module}/s3_policy.tmpl", {
    bucket_resources = jsonencode(var.s3_replicated_bucket_default_resources)
    key_users        = jsonencode(var.s3_default_users),
  })

  required_tags = {
    AssetOwner          = "<Asset Owner>"
    CostCenter          = "<Cost Center>"
    SecurityReviewID    = "<Security Review ID>"
    ServiceNowAS        = "<ServiceNow AS>"
    ServiceNowBA        = "<ServiceNow BA>"
  }

  required_data_tags = {
    BusinessEntity         = "<Business Entity>"
    ComplianceDataCategory = "<Compliance Data Category>"
    DataClassification     = "<Data Classification>"
    DataSubjectArea        = "<Data Subject Area>"
    LineOfBusiness         = "<Line Of Business>"
  }

  providers = {
    aws.replication = aws.crr
    aws.source      = aws
  }
}
