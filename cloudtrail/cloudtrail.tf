data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [
      "arn:aws:s3:::${local.cloudtrail_bucket_name}",
      "arn:aws:s3:::${local.cloudtrail_bucket_name}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudtrail:${data.aws_region.current_region.name}:${data.aws_caller_identity.current.account_id}:trail/${var.cloudtrail_resource_deletion_monitoring}"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

      actions = [
      "s3:Get*",
      "s3:List*",
      "s3:Put*",
      "s3:Delete*",
      "s3:GetObject*",
    ]
    resources = [
      "arn:aws:s3:::${local.cloudtrail_bucket_name}",
      "arn:aws:s3:::${local.cloudtrail_bucket_name}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudtrail:${data.aws_region.current_region.name}:${data.aws_caller_identity.current.account_id}:trail/${var.cloudtrail_resource_deletion_monitoring}"]
    }
  }
}



#cloudtrail-storage-bucket
module "bef-cloudtrail-storage-s3" {
  source                       = "git::https://github.sys.cigna.com/cigna/terraform-aws-s3"
  bucket_name                  = local.cloudtrail_bucket_name
  required_tags                = var.required_common_tags
  optional_tags                = var.extra_tags
  required_data_tags           = var.required_data_tags
  lc_rule_id                   = var.lc_rule_id
  bucket_policy                = data.aws_iam_policy_document.cloudtrail_bucket_policy.json
  cors_rule_is_enabled         = var.cors_rule_is_enabled
  cors_allowed_headers         = var.cors_allowed_headers
  cors_allowed_methods         = var.cors_allowed_methods
  cors_allowed_origins         = var.cors_allowed_origins
  bucket_encryption_algorithm  = "aws:kms"
  bucket_kms_key_id            = module.bef-presigned-url-kms[0].arn
  enable_bucket_keys           = var.enable_bucket_keys
  use_default_lc_configuration = false

  providers = {
    aws.replication = aws.crr
    aws.source      = aws
  }
}

