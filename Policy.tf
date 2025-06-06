data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${local.cloudtrail_bucket_name}"]
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
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.cloudtrail_bucket_name}/*"]
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

  statement {
    sid    = "AWSCloudTrailBucketDeliveryCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::${local.cloudtrail_bucket_name}"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudtrail:${data.aws_region.current_region.name}:${data.aws_caller_identity.current.account_id}:trail/${var.cloudtrail_resource_deletion_monitoring}"]
    }
  }
}
