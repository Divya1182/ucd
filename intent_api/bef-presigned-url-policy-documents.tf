# Used in KMS
data "aws_iam_policy_document" "presigned-url-kms-iam-policy" {
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
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Enterprise/intentApiLambdaS3AccessPolicy",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Enterprise/BEFStorageSolution",
        data.aws_iam_role.bef_lambda_callback_role.arn
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
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DEPLOYER",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Enterprise/intentApiLambdaS3AccessPolicy"
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

  statement {
    sid    = "Allow access through S3 for Polaris and Databricks"
    effect = "Allow"
    principals {
      identifiers = var.ap_polaris
      # identifiers = [ "arn:aws:iam::035074925037:role/UCLandzAccessrole"]
      type = "AWS"
    }
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Get*"
    ]
    resources = ["*"]
    condition {
      test = "StringEquals"
      values = [
        "s3.us-east-1.amazonaws.com"
      ]
      variable = "kms:ViaService"
    }
  }

}

# Used in VPC Gateway Endpoint
data "aws_iam_policy_document" "presigned-url-s3-endpoint-policy" {
  statement {
    sid       = "Allow S3 access"
    effect    = "Allow"
    actions   = ["s3:Get*", "s3:Put*", "s3:Delete*"]
    resources = ["arn:aws:s3:::bef*/*", "arn:aws:s3:::bef*/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      values   = ["o-xl5jimff3q"]
      variable = "aws:PrincipalOrgID"
    }
  }
}


# S3 Bucket related configs
data "aws_iam_policy_document" "presigned-url-s3-policy" {
  statement {
    sid = "BEF Bucket Policy"
    principals {
      identifiers = [
        "${data.aws_caller_identity.current.id}"
        # "arn:aws:iam::035074925037:role/UCLandzAccessrole"
      ]
      type = "AWS"
    }
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:Put*",
      "s3:Delete*",
      "s3:GetObject*",
      "s3:AbortMultipartUpload"
    ]
    resources = [
      "arn:aws:s3:::${local.s3_bucket_name}",
      "arn:aws:s3:::${local.s3_bucket_name}/*"
    ]
  }

  statement {
    sid = "Deny Internet Access"
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
    effect = "Deny"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${local.s3_bucket_name}",
      "arn:aws:s3:::${local.s3_bucket_name}/*"
    ]
    condition {
      test     = "ForAnyValue:StringNotLike"
      variable = "aws:PrincipalArn"
      values = concat([
        "${data.aws_iam_role.bef_lambda_role.arn}",
        "${data.aws_iam_role.bef_lambda_role.arn}/*",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DEPLOYER",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DEPLOYER/*",
        # "arn:aws:iam::035074925037:role/UCLandzAccessrole"
        ],
      var.ap_polaris)
    }
  }

  statement {
    sid = "Access Point Policy"
    principals {
      identifiers = var.ap_polaris
      type        = "AWS"
    }
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      "arn:aws:s3:::${local.s3_bucket_name}",
      "arn:aws:s3:::${local.s3_bucket_name}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:DataAccessPointAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }
  }
}

data "aws_iam_policy_document" "presigned-url-crr-s3-kms-iam-policy" {
  count = var.enable_crr ? 1 : 0

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
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Enterprise/intentApiLambdaS3AccessPolicy",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Enterprise/BEFStorageSolution",
        data.aws_iam_role.bef_lambda_callback_role.arn
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
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DEPLOYER",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Enterprise/intentApiLambdaS3AccessPolicy"
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
        "s3.us-west-1.amazonaws.com",
        "sqs.us-west-1.amazonaws.com",
        "dynamodb.*.amazonaws.com"
      ]
      variable = "kms:ViaService"
    }
  }

  statement {
    sid    = "Allow access through S3 for Polaris and Databricks"
    effect = "Allow"
    principals {
      identifiers = var.ap_polaris
      # identifiers = [ "arn:aws:iam::035074925037:role/UCLandzAccessrole"]
      type = "AWS"
    }
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Get*"
    ]
    resources = ["*"]
    condition {
      test = "StringEquals"
      values = [
        "s3.us-west-1.amazonaws.com",
        "s3.us-east-1.amazonaws.com"
      ]
      variable = "kms:ViaService"
    }
  }

}

data "aws_iam_policy_document" "presigned-url-crr-s3-policy" {
  count = var.enable_crr ? 1 : 0

  statement {
    sid = "BEF Bucket Policy"
    principals {
      identifiers = [
        "${data.aws_caller_identity.current.id}"
        # "arn:aws:iam::035074925037:role/UCLandzAccessrole"
      ]
      type = "AWS"
    }
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:Put*",
      "s3:Delete*",
      "s3:GetObject*",
      "s3:AbortMultipartUpload"
    ]
    resources = [
      "arn:aws:s3:::${local.crr_s3_bucket_name}",
      "arn:aws:s3:::${local.crr_s3_bucket_name}/*"
    ]
  }

  statement {
    sid = "Deny Internet Access"
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
    effect = "Deny"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${local.crr_s3_bucket_name}",
      "arn:aws:s3:::${local.crr_s3_bucket_name}/*"
    ]
    condition {
      test     = "ForAnyValue:StringNotLike"
      variable = "aws:PrincipalArn"
      values = concat([
        "${data.aws_iam_role.bef_lambda_role.arn}",
        "${data.aws_iam_role.bef_lambda_role.arn}/*",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DEPLOYER",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DEPLOYER/*",
        # "arn:aws:iam::035074925037:role/UCLandzAccessrole"
        ],
      var.ap_polaris)
    }
  }

  statement {
    sid = "Access Point Policy"
    principals {
      identifiers = var.ap_polaris
      type        = "AWS"
    }
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      "arn:aws:s3:::${local.crr_s3_bucket_name}",
      "arn:aws:s3:::${local.crr_s3_bucket_name}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:DataAccessPointAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }
  }
}

data "aws_iam_policy_document" "crr_s3_assume_role" {
  count = var.enable_crr ? 1 : 0
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "crr_s3_replication_role" {

  count = var.enable_crr ? 1 : 0

  name = "bef_s3_crr_replication_${var.environment}"

  assume_role_policy = data.aws_iam_policy_document.crr_s3_assume_role[0].json

}

resource "aws_iam_policy" "crr_s3_replication_iam_policy" {

  count = var.enable_crr ? 1 : 0

  name = "bef_s3_crr_replication_iam_policy_${var.environment}"

  policy = data.aws_iam_policy_document.crr_s3_replication_policy[0].json

}

resource "aws_iam_role_policy_attachment" "crr_s3_replication_iam_policy_attachment" {

  count = var.enable_crr ? 1 : 0

  role = aws_iam_role.crr_s3_replication_role[0].name

  policy_arn = aws_iam_policy.crr_s3_replication_iam_policy[0].arn

}

data "aws_iam_policy_document" "crr_s3_replication_policy" {
  count = var.enable_crr ? 1 : 0
  statement {
    sid    = "SourceBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:GetObjectRetention",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectVersionAcl",
      "s3:ListBucket",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectLegalHold",
      "s3:GetReplicationConfiguration"
    ]
    resources = [
      "arn:aws:s3:::${local.s3_bucket_name}",
      "arn:aws:s3:::${local.s3_bucket_name}/*"
    ]
  }

  statement {
    sid    = "DestinationBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:GetObjectVersionTagging",
      "s3:ReplicateTags",
      "s3:ReplicateDelete"
    ]
    resources = [
      "arn:aws:s3:::${local.crr_s3_bucket_name}",
      "arn:aws:s3:::${local.crr_s3_bucket_name}/*"
    ]
  }

  statement {
    sid    = "SourceBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      module.bef-presigned-url-kms.arn
    ]
  }

  statement {
    sid    = "DestinationBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      module.bef-presigned-url-crr-s3-kms[0].arn
    ]
  }
}
data "aws_iam_policy_document" "source_crr_s3_assume_role" {
  count = var.enable_crr ? 1 : 0
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "source_crr_s3_replication_role" {
  count              = var.enable_crr ? 1 : 0
  name               = "bef_s3_source_crr_replication_${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.source_crr_s3_assume_role[0].json
}
resource "aws_iam_policy" "source_crr_s3_replication_iam_policy" {
  count  = var.enable_crr ? 1 : 0
  name   = "bef_s3_source_crr_replication_iam_policy_${var.environment}"
  policy = data.aws_iam_policy_document.source_crr_s3_replication_policy[0].json
}
resource "aws_iam_role_policy_attachment" "source_crr_s3_replication_iam_policy_attachment" {
  count      = var.enable_crr ? 1 : 0
  role       = aws_iam_role.source_crr_s3_replication_role[0].name
  policy_arn = aws_iam_policy.source_crr_s3_replication_iam_policy[0].arn
}
data "aws_iam_policy_document" "source_crr_s3_replication_policy" {
  count = var.enable_crr ? 1 : 0
  statement {
    sid    = "SourceBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:GetObjectRetention",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectVersionAcl",
      "s3:ListBucket",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectLegalHold",
      "s3:GetReplicationConfiguration"
    ]
    resources = [
      "arn:aws:s3:::${local.crr_s3_bucket_name}",
      "arn:aws:s3:::${local.crr_s3_bucket_name}/*"
    ]
  }
  statement {
    sid    = "DestinationBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:GetObjectVersionTagging",
      "s3:ReplicateTags",
      "s3:ReplicateDelete"
    ]
    resources = [
      "arn:aws:s3:::${local.s3_bucket_name}",
      "arn:aws:s3:::${local.s3_bucket_name}/*"
    ]
  }
  statement {
    sid    = "SourceBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      module.bef-presigned-url-crr-s3-kms[0].arn
    ]
  }
  statement {
    sid    = "DestinationBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      module.bef-presigned-url-kms.arn
    ]
  }
}


