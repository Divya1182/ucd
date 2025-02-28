resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy_bucket
  tags = merge(var.required_tags, var.required_data_tags, var.optional_tags, var.optional_data_tags, {
    AppName     = var.app_name
    AssetName   = "${var.bucket_name}-s3"
    Environment = local.environment
    Version     = local.version
  })
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_ownership" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = var.enable_bucket_acl ? var.bucket_acl : "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket_lifecycle_this" {
  count = var.use_default_lc_configuration ? 1 : 0 
  bucket = aws_s3_bucket.this.id
  rule {
    abort_incomplete_multipart_upload {
      days_after_initiation = var.lc_abort_incomplete_upload_days
    }
    status                                 = "Enabled"
    id                                     = var.lc_rule_id
    filter {
      prefix = var.lc_prefix
    }

    dynamic "expiration" {
      for_each = [for enabled in local.expire_non_current_versions_is_enabled : enabled if enabled == true]
      content {
        expired_object_delete_marker = var.lc_remove_expired_deletion_markers
      }
    }

    dynamic "noncurrent_version_expiration" {
      for_each = [for enabled in local.expire_non_current_versions_is_enabled : enabled if enabled == true]
      content {
        noncurrent_days = var.lc_non_current_expiration_days
        newer_noncurrent_versions = var.lc_number_of_newer_noncurrent_versions
      }
    }

    transition {
      days          = var.lc_transition_1_days
      storage_class = var.lc_transition_1_storage_class
    }

    transition {
      days          = var.lc_transition_2_days
      storage_class = var.lc_transition_2_storage_class
    }
  }

  dynamic "rule" {
    for_each = [for enabled in local.expire_current_versions_is_enabled : enabled if enabled == true]
    content {
      id      = "${var.lc_rule_id}-expiration"
      filter {
        prefix = var.lc_expiration_prefix != "" ? var.lc_expiration_prefix : var.lc_prefix
      }
      status  = "Enabled"
      expiration {
        days = var.lc_current_expiration_days
      }
    }
  }
}

resource "aws_s3_bucket_versioning" "s3_bucket_versioning_this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.enable_bucket_versioning == true ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_logging" "s3_bucket_logging_this"{
  count  = local.logging_is_enabled == true ? 1 : 0
  bucket = aws_s3_bucket.this.id
  target_bucket = var.logging_target_bucket
  target_prefix = var.logging_target_prefix
}

resource "aws_s3_bucket_server_side_encryption_configuration" "server_side_encryption_configuration_this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.bucket_encryption_algorithm == "aws:kms" ? var.bucket_kms_key_id : null
      sse_algorithm     = var.bucket_encryption_algorithm
    }
    bucket_key_enabled = var.enable_bucket_keys
  }
}

resource "aws_s3_bucket_replication_configuration" "replication_configuration_this" {
    depends_on = [aws_s3_bucket_versioning.s3_bucket_versioning_this]
    count    = local.crr_is_enabled == true ? 1 : 0
    bucket = aws_s3_bucket.this.id
    role = var.crr_role_arn

    rule {
      id     = "${var.bucket_name}-crr"
      filter {
        prefix = ""
      }
      delete_marker_replication {
        status = var.delete_marker_replication_status
      }
      status = "Enabled"
      destination {
        bucket             = aws_s3_bucket.replicated_bucket[0].arn
        encryption_configuration {
          replica_kms_key_id = var.crr_bucket_kms_key_id
        }
        storage_class      = "STANDARD"
      }
      source_selection_criteria {
        sse_kms_encrypted_objects {
          status = "Enabled"
        }
      }
    }
}

resource "aws_s3_bucket_cors_configuration" "bucket_cors_configuration_this" {
  count    = var.cors_rule_is_enabled == true ? 1 : 0
  bucket = aws_s3_bucket.this.id
  cors_rule {
    allowed_headers = var.cors_allowed_headers
    allowed_methods = var.cors_allowed_methods
    allowed_origins = var.cors_allowed_origins
    expose_headers  = var.cors_expose_headers
    max_age_seconds = var.cors_max_age
  }
}

resource "aws_s3_bucket_acl" "bucket_acl_this" {
  count  = var.enable_bucket_acl == true ? 1 : 0
  bucket = aws_s3_bucket.this.id
  acl    = "private"
}

resource "aws_s3_bucket_metric" "s3_bucket_metric" {
  bucket = aws_s3_bucket.this.bucket
  name   = "EntireBucket"
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = aws_s3_bucket.this.id
  policy = var.bucket_policy
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  depends_on = [aws_s3_bucket_policy.s3_bucket_policy]
  bucket = aws_s3_bucket.this.id

  # Block new public ACLs and uploading public objects
  block_public_acls = true

  # Retroactively remove public access granted through public ACLs
  ignore_public_acls = true

  # Block new public bucket policies
  block_public_policy = true

  # Retroactivley block public and cross-account access if bucket has public policies
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "replicated_bucket" {
  count    = var.enable_crr == true ? 1 : 0
  provider = aws.replication

  bucket        = "${var.bucket_name}-copy"
  force_destroy = var.force_destroy_crr_bucket

  tags = merge(var.required_tags, var.required_data_tags, var.optional_tags, var.optional_data_tags, {
    AppName     = var.app_name
    AssetName   = "${var.bucket_name}-crr-s3"
    Environment = local.environment
    Purpose     = "Bucket for replicated data from the ${var.bucket_name} bucket"
    Version     = local.version
  })
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_ownership_replicated" {
  count    = var.enable_crr ? 1 : 0
  provider = aws.replication

  bucket = aws_s3_bucket.replicated_bucket[0].id
  rule {
    object_ownership = var.enable_bucket_acl ? var.bucket_acl : "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "s3_bucket_versioning_replicated_bucket" {
  depends_on = [aws_s3_bucket.replicated_bucket]
  count      = var.enable_crr == true ? 1 : 0
  provider   = aws.replication

  bucket = aws_s3_bucket.replicated_bucket[count.index].id
  versioning_configuration {
    status = var.enable_bucket_versioning == true ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket_lifecycle_replicated_bucket" {
  depends_on = [aws_s3_bucket.replicated_bucket]
  count      = var.enable_crr == true ? 1 : 0
  provider   = aws.replication

  bucket = aws_s3_bucket.replicated_bucket[count.index].id
  rule {
    abort_incomplete_multipart_upload {
      days_after_initiation = var.lc_abort_incomplete_upload_days
    }
    status                                 = "Enabled"
    id                                     = var.lc_rule_id
    filter {
      prefix = var.lc_prefix
    }

    dynamic "expiration" {
      for_each = [for enabled in local.expire_non_current_versions_is_enabled : enabled if enabled == true]

      content {
        expired_object_delete_marker = var.lc_remove_expired_deletion_markers
      }
    }

    dynamic "noncurrent_version_expiration" {
      for_each = [for enabled in local.expire_non_current_versions_is_enabled : enabled if enabled == true]

      content {
        noncurrent_days = var.lc_non_current_expiration_days
      }
    }

    transition {
      days          = var.lc_transition_1_days
      storage_class = var.lc_transition_1_storage_class
    }

    transition {
      days          = var.lc_transition_2_days
      storage_class = var.lc_transition_2_storage_class
    }
  }

  dynamic "rule" {
    for_each = [for enabled in local.expire_current_versions_is_enabled : enabled if enabled == true]
    content {
      id      = "${var.lc_rule_id}-expiration"
      filter {
        prefix = var.lc_expiration_prefix != "" ? var.lc_expiration_prefix : var.lc_prefix
      }
      status  = "Enabled"
      expiration {
        days = var.lc_current_expiration_days
      }
    }
  }
}

resource "aws_s3_bucket_logging" "s3_bucket_logging_replicated_bucket" {
  depends_on = [aws_s3_bucket.replicated_bucket]
  count      = var.enable_crr == true && local.logging_is_enabled == true ? 1 : 0
  bucket = aws_s3_bucket.replicated_bucket[count.index].id
  provider   = aws.replication

  target_bucket = var.logging_target_bucket_replicated_bucket
  target_prefix = var.logging_target_prefix
}

resource "aws_s3_bucket_server_side_encryption_configuration" "server_side_encryption_configuration_replicated_bucket" {
  depends_on = [aws_s3_bucket.replicated_bucket]
  count      = var.enable_crr == true ? 1 : 0
  provider   = aws.replication

  bucket = aws_s3_bucket.replicated_bucket[count.index].id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.bucket_encryption_algorithm == "aws:kms" ? var.crr_bucket_kms_key_id : null
      sse_algorithm     = var.bucket_encryption_algorithm
    }
    bucket_key_enabled = var.enable_bucket_keys
  }
}

resource "aws_s3_bucket_acl" "bucket_acl_replicated_bucket" {
  depends_on = [aws_s3_bucket.replicated_bucket]
  count      = (var.enable_crr == true && var.enable_bucket_acl == true) ? 1 : 0
  bucket = aws_s3_bucket.replicated_bucket[count.index].id
  provider   = aws.replication
  acl    = "private"
}

resource "aws_s3_bucket_metric" "crr_bucket_metric" {
  depends_on = [aws_s3_bucket.replicated_bucket]
  count      = var.enable_crr == true ? 1 : 0
  provider   = aws.replication
  bucket = aws_s3_bucket.replicated_bucket[count.index].bucket
  name   = "EntireBucket"
}

resource "aws_s3_bucket_policy" "crr_bucket_policy" {
  depends_on = [aws_s3_bucket.replicated_bucket]
  count      = var.enable_crr == true ? 1 : 0
  provider   = aws.replication
  bucket = aws_s3_bucket.replicated_bucket[count.index].id
  policy = var.crr_bucket_policy
}

resource "aws_s3_bucket_public_access_block" "crr_public_access_block" {
  depends_on = [aws_s3_bucket_policy.crr_bucket_policy]
  count      = var.enable_crr == true ? 1 : 0
  provider   = aws.replication
  bucket = aws_s3_bucket.replicated_bucket[count.index].id

  # Block new public ACLs and uploading public objects
  block_public_acls = true

  # Retroactively remove public access granted through public ACLs
  ignore_public_acls = true

  # Block new public bucket policies
  block_public_policy = true

  # Retroactivley block public and cross-account access if bucket has public policies
  restrict_public_buckets = true
}
