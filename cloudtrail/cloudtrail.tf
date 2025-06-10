resource "aws_cloudwatch_event_rule" "deletion_rule" {
  name        = var.resource_deletion_monitoring_cw_event_rule
  description = "Capture AWS resource deletion events"
  event_pattern = jsonencode({
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
      "eventName": [
        { "prefix": "Delete" },
        { "prefix": "Terminate" },
        { "prefix": "Remove" },
        "StopInstances",
        "DeregisterImage",
        "DisassociateResourceShare",
        "CancelSpotInstanceRequests"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.deletion_rule.name
  target_id = "DeletionNotifier"
  arn       = module.resource_deletion_monitoring.arn
}

resource "aws_cloudtrail" "resource_deletion_trail" {
  name                       = var.cloudtrail_resource_deletion_monitoring
  s3_bucket_name             = module.bef-cloudtrail-storage-s3.s3_bucket_id
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
  cloud_watch_logs_role_arn  = data.aws_iam_role.bef_cloudtrail_role.arn

  event_selector {
    read_write_type                  = "WriteOnly"
    include_management_events        = true
    exclude_management_event_sources = []
  }
  tags = merge(
    var.required_common_tags,
    var.extra_tags,
    {
      Name = "Resource Deletion Monitoring Trail"
    }
  )
}

resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = var.cloudtrail_resource_deletion_log_group
  retention_in_days = 7

  tags = merge(
    var.required_common_tags,
    var.extra_tags,
    {
      Name = "Cloud Trail Log Group"
    }
  )
}

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
  bucket_kms_key_id            = module.resource_deletion_monitoring_kms.arn
  enable_bucket_keys           = var.enable_bucket_keys
  use_default_lc_configuration = false

  providers = {
    aws.replication = aws.crr
    aws.source      = aws
  }
}

module "resource_deletion_monitoring_kms" {
  source                   = "git::https://github.sys.cigna.com/cigna/thub-gov-terraform-kms.git"
  name                     = var.resource_deletion_monitoring_kms
  description              = var.resource_deletion_monitoring_kms_description
  customer_master_key_spec = var.resource_deletion_monitoring_kms_customer_master_key_spec
  enable_key_rotation      = var.resource_deletion_monitoring_kms_enable_key_rotation
  policy                   = data.aws_iam_policy_document.resource_deletion_monitoring_s3_kms_iam_policy.json
  tags                     = merge(var.required_common_tags, var.extra_tags)
}
