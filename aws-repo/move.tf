moved {
  from = module.bef-presigned-url-kms
  to   = module.bef-presigned-url-kms[0]
}

moved {
  from = data.aws_iam_policy_document.presigned-url-s3-policy
  to   = data.aws_iam_policy_document.presigned-url-s3-policy[0]
}

moved {
  from = data.aws_iam_policy_document.presigned-url-kms-iam-policy
  to   = data.aws_iam_policy_document.presigned-url-kms-iam-policy[0]
}

moved {
  from = module.bef-storage-s3
  to   = module.bef-storage-s3[0]
}
