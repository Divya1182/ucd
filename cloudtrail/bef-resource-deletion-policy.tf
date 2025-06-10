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



## s3 policy

data "aws_iam_policy_document" "resource_deletion_monitoring_s3_kms_iam_policy" {
  #Root Access
  statement {
    sid    = "Root Access"
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      type        = "AWS"
    }
    actions = [
      "kms:*"
    ]
    resources = ["*"]
  }

  # Key Admin
  statement {
    sid    = "Key Administrator"
    effect = "Allow"
    principals {
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DEPLOYER"
      ]
      type = "AWS"
    }
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:RotateKeyOnDemand",
      "kms:CreateAlias"
    ]
    resources = ["*"]
  }

  #User Roles
  statement {
    sid    = "User roles access"
    effect = "Allow"
    principals {
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DEPLOYER",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Enterprise/BEFStorageSolution",
        data.aws_iam_role.resource_deletion_monitoring.arn
      ]
      type = "AWS"
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }


  #Allow attachment of persistent resources
  statement {
    sid    = "Allow attachment of persistent resources"
    effect = "Allow"
    principals {
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DEPLOYER"
      ]
      type = "AWS"
    }
    actions = [
      "kms:ListGrants",
      "kms:CreateGrant",
      "kms:RevokeGrant"
    ]
    resources = ["*"]
  }



  #Serivce Users
  statement {
    sid    = "Allow access through S3, Dynamo, SQS for current account"
    effect = "Allow"
    principals {
      identifiers = ["${data.aws_caller_identity.current.id}"]
      type        = "AWS"
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:Get*",
      "kms:List*"
    ]
    resources = ["*"]
    condition {
      test = "StringEquals"
      values = [
        "s3.us-east-1.amazonaws.com",
        "sqs.us-east-1.amazonaws.com",
        "dynamodb.*.amazonaws.com"
      ]
      variable = "kms:ViaService"
    }
  }

}