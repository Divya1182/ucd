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
  alarm_app_name                        = "s3-default-app"
  alarm_env                             = "pvs"
  alarm_evaluation_periods              = 4
  alarm_period                          = 60
  alarm_severity_4xx                    = "CRITICAL"
  alarm_severity_5xx                    = "CRITICAL"
  alarm_threshold_4xx                   = 2
  alarm_threshold_5xx                   = 2
  app_name                              = "test_app"
  bucket_kms_key_id                     = aws_kms_key.key.arn
  bucket_name                           = "s3-default-example-bucket"
  crr_bucket_kms_key_id                 = aws_kms_key.crr_key.arn
  crr_role_arn                          = "arn:aws:iam::12345:role/Enterprise/S3CRR"
  delete_marker_replication_status      = "Disabled"
  enable_bucket_400_error_alarm         = false
  enable_bucket_versioning              = true
  enable_crr                            = true
  enable_logging                        = true
  lc_abort_incomplete_upload_days       = 10
  lc_remove_expired_deletion_markers    = false
  lc_rule_id                            = "s3-default-lifecycle-rule"
  lc_transition_1_days                  = 365
  lc_transition_1_storage_class         = "INTELLIGENT_TIERING"
  lc_transition_2_days                  = 2555
  lc_transition_2_storage_class         = "GLACIER"
  lc_version_transition_1_days          = 365
  lc_version_transition_1_storage_class = "INTELLIGENT_TIERING"
  lc_version_transition_2_days          = 2555
  lc_version_transition_2_storage_class = "GLACIER"
  logging_target_bucket                 = "send-logs-here-bucket"
  logging_target_prefix                 = "s3/"
  logging_target_bucket_replicated_bucket = "send-logs-here-bucket-replicated-bucket"
  source                                = "../../"

  bucket_policy = templatefile("${path.module}/s3_policy.tmpl", {
    key_users        = jsonencode(var.s3_default_users),
    bucket_resources = jsonencode(var.s3_default_resources)
  })

  crr_bucket_policy = templatefile("${path.module}/s3_policy.tmpl", {
    bucket_resources = jsonencode(var.s3_replicated_bucket_default_resources)
    key_users        = jsonencode(var.s3_default_users),
  })

  optional_tags = {
    exampleTag = "Just an example"
  }

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
  optional_data_tags = {
    Purpose             = "A bucket for testing"
    RegionalRestriction = "us-east-1:us-east-2"
  }

  providers = {
    aws.source      = aws
    aws.replication = aws.crr
  }
}
