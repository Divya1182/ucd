variable "alarm_app_name" {
  default     = ""
  description = "An optional app name to give to the alarm if there are multiple alarms in an account"
  type        = string
}

variable "alarm_env" {
  default     = ""
  description = "An optional environment to give to the alarm if there are two logical environments in one account"
  type        = string
}

variable "alarm_evaluation_periods" {
  default     = 5
  description = "The number of periods over which data is compared to the specified threshold"
  type        = number
}

variable "alarm_period" {
  default     = 60
  description = "The period in seconds over which the specified statistic is applied"
  type        = number
}

variable "alarm_region" {
  default     = "us-east-1"
  description = "The region to use for the alarm funnel. Supported regions are us-east-1 and eu-west-2."
  type        = string
}

variable "alarm_severity_4xx" {
  default     = "WARN"
  description = "The alarm severity level for 4xx errors. Allowed values are `WARN` or `CRITICAL` or `INFO`"
  type        = string
}

variable "alarm_severity_5xx" {
  default     = "WARN"
  description = "The alarm severity level for 5xx errors. Allowed values are `WARN` or `CRITICAL` or `INFO`"
  type        = string
}

variable "alarm_threshold_4xx" {
  default     = 5
  description = "The number of data points to trigger the alarm for 4xx errors"
  type        = number
}

variable "alarm_threshold_5xx" {
  default     = 5
  description = "The number of data points to trigger the alarm for 5xx errors"
  type        = number
}

variable "app_name" {
  default     = ""
  description = "The name of the app that this resource supports"
  type        = string
}

variable "bucket_acl" {
  default     = "BucketOwnerPreferred"
  description = "If enable_bucket_acl is true, this controls which canned ACL policy is applied"
  type        = string
}

variable "bucket_encryption_algorithm" {
  default     = "aws:kms"
  description = "The encryption algorithm to use for the S3 bucket"
  type        = string
} 

variable "bucket_kms_key_id" {
  default     = ""
  description = "An existing KMS key id used to encrypt this bucket"
  type        = string
}

variable "bucket_name" {
  description = "The name of the s3 bucket that will be created"
  type        = string
}

variable "bucket_policy" {
  description = "A JSON document with the Bucket Policy to be placed on the Bucket"
  type        = string
}

variable "crr_bucket_policy" {
  description = "A JSON document with the Bucket Policy to be placed on the Bucket"
  type        = string
  default     = ""
}

variable "crr_bucket_kms_key_id" {
  default     = ""
  type        = string
  description = "An existing KMS key id to be used with the replication bucket"
}

variable "crr_role_arn" {
  default     = null
  description = "The arn for the role that will handle replicating the bucket. This is only required if replication is enabled"
  type        = string
}

variable "enable_bucket_400_error_alarm" {
  default     = true
  description = "Setting this to true has the possibility to generate overwhelming false alarms"
  type        = bool
}

variable "enable_bucket_500_error_alarm" {
  default     = true
  description = "Setting this to true has the possibility to generate overwhelming false alarms"
  type        = bool
}

variable "enable_bucket_acl" {
  default     = false
  description = "If true, enable bucket ACLs and allow object writers to be owners"
  type        = bool
}

variable "enable_bucket_keys" {
  default     = true
  description = "True to enable bucket-level key for SSE to reduce the request traffic from Amazon S3 to AWS KMS. Defaults to false"
  type        = bool
}

variable "enable_bucket_versioning" {
  default     = true
  description = "Enable versioning on the S3 bucket"
  type        = bool
}

variable "enable_crr" {
  default     = false
  description = "True to enable bucket cross region replication. Defaults to false"
  type        = bool
}

variable "enable_expire_current_versions" {
  default     = false
  description = "If true, current versions will be expired after a specified number of days."
  type        = bool
}

variable "enable_expire_non_current_versions" {
  default     = false
  description = "If true, non current versions will be expired after a specified number of days."
  type        = bool
}

variable "enable_logging" {
  default     = false
  description = "True to enable bucket access logging. Defaults to false"
  type        = bool
}

variable "force_destroy_bucket" {
  description = "Boolean for forcibly destroying the s3 bucket"
  type        = bool
  default     = false
}

variable "force_destroy_crr_bucket" {
  description = "Boolean for forcibly destroying the s3 crr bucket"
  type        = bool
  default     = false
}

variable "use_default_lc_configuration" {
  description = "Set to false if you want to use a custom lifecycle rule configuration for your S3 bucket."
  type = bool
  default = true
}

variable "lc_abort_incomplete_upload_days" {
  default     = 7
  description = "Number of days until failed multipart uploads are deleted"
  type        = number
}

variable "lc_current_expiration_days" {
  default     = 365
  description = "Lifecycle policy rule that expires current versions of objects after specified number of days"
  type        = number
}

variable "lc_prefix" {
  default     = ""
  description = "Scope the lifecycle policy to a specific sub directory. Pass in empty string to scope to bucket"
  type        = string
}

variable "lc_expiration_prefix" {
  default     = ""
  description = "Scope the lifecycle policy to a specific sub directory. Pass in empty string to scope to bucket"
  type        = string
}

variable "lc_remove_expired_deletion_markers" {
  default     = true
  description = "Flag for S3 to delete expired deletion markers on versioned buckets"
  type        = bool
}

variable "lc_rule_id" {
  description = "Unique name of lifecycle rule"
  type        = string
}

variable "lc_non_current_expiration_days" {
  default     = 7
  description = "Lifecycle policy rule that expires non current versions of objects after specified number of days"
  type        = number
}

variable "lc_number_of_newer_noncurrent_versions" {
  default     = 0
  description = "Lifecycle policy rule that retains a certain number of newer noncurrent versions"
  type        = number
}

variable "lc_transition_1_days" {
  default     = 90
  description = "Lifecycle policy rule that governs the transition to next storage class based on number of days"
  type        = number
}

variable "lc_transition_1_storage_class" {
  default     = "INTELLIGENT_TIERING"
  description = "Lifecycle policy rule that governs the transition storage class selected based on number of days"
  type        = string
}

variable "lc_transition_2_days" {
  default     = 2555
  description = "Lifecycle policy rule that governs the transition to next storage class based on number of days. This is used after the first rule is met"
  type        = number
}

variable "lc_transition_2_storage_class" {
  default     = "GLACIER"
  description = "Lifecycle policy rule that governs the transition storage class selected based on number of days. This is used after the first rule is met"
  type        = string
}

variable "lc_version_transition_1_days" {
  default     = 90
  description = "Lifecycle policy rule, for older versions, that governs the transition to next storage class based on number of days"
  type        = number
}

variable "lc_version_transition_1_storage_class" {
  default     = "INTELLIGENT_TIERING"
  description = "Lifecycle policy rule, for older versions, that governs the transition storage class selected based on number of days"
  type        = string
}

variable "lc_version_transition_2_days" {
  default     = 2555
  description = "Lifecycle policy rule, for older versions, that governs the transition to next storage class based on number of days. This is used after the first rule is met"
  type        = number
}

variable "lc_version_transition_2_storage_class" {
  default     = "GLACIER"
  description = "Lifecycle policy rule, for older versions, that governs the transition storage class selected based on number of days. This is used after the first rule is met"
  type        = string
}

variable "logging_target_bucket" {
  default     = ""
  description = "The name of the bucket that will receive the log objects. This is only required if enable_logging = true"
  type        = string
}

variable "logging_target_prefix" {
  default     = ""
  description = "To specify a key prefix for log objects."
  type        = string
}

variable "logging_target_bucket_replicated_bucket" {
  default     = ""
  description = "The name of the bucket that will receive the log objects from the replicated bucket. This is only required if enable_logging = true"
  type        = string
}

variable "cors_rule_is_enabled" {
  default     = false
  description = "True to enable bucket access logging. Defaults to false"
  type        = bool
}

variable "cors_allowed_headers" {
  default     = []
  description = "Lifecycle policy rule that governs the transition storage class selected based on number of days. This is used after the first rule is met"
  type        = list
}

variable "cors_allowed_methods" {
  default     = ["GET"]
  description = "Lifecycle policy rule that governs the transition storage class selected based on number of days. This is used after the first rule is met"
  type        = list
}

variable "cors_allowed_origins" {
  default     = []
  description = "Lifecycle policy rule that governs the transition storage class selected based on number of days. This is used after the first rule is met"
  type        = list
}

variable "cors_expose_headers" {
  default     = []
  description = "Lifecycle policy rule that governs the transition storage class selected based on number of days. This is used after the first rule is met"
  type        = list
}
variable "cors_max_age" {
  default     = 90
  description = "Lifecycle policy rule, for older versions, that governs the transition to next storage class based on number of days"
  type        = number
}

variable "required_tags" {
  description = "Required common resource tags as defined by the CCOE Cloud Tagging Requirements"
  type = object({
    AssetOwner       = string
    CostCenter       = string
    SecurityReviewID = string
    ServiceNowAS     = string
    ServiceNowBA     = string
  })
  validation {
    condition     = !contains(["", "<Asset Owner>"], var.required_tags.AssetOwner) && !contains(["", "<Cost Center>"], var.required_tags.CostCenter) && !contains(["", "<Security Review ID>"], var.required_tags.SecurityReviewID) && !contains(["", "<ServiceNow BA>"], var.required_tags.ServiceNowBA) && !contains(["", "<ServiceNow AS>"], var.required_tags.ServiceNowAS)
    error_message = "Defining all tags is required for this resource (reference https://confluence.sys.cigna.com/display/CLOUD/Cloud+Tagging+Requirements+v2.0)."
  }
}

variable "required_data_tags" {
  description = "Required tags for data at rest as defined by the CCOE Cloud Tagging Requirements"
  type = object({
    BusinessEntity         = string
    ComplianceDataCategory = string
    DataClassification     = string
    DataSubjectArea        = string
    LineOfBusiness         = string
  })
  validation {
    condition     = !contains(["", "<Business Entity>"], var.required_data_tags.BusinessEntity) && !contains(["", "<Compliance Data Category>"], var.required_data_tags.ComplianceDataCategory) && !contains(["", "<Data Classification>"], var.required_data_tags.DataClassification) && !contains(["", "<Data Subject Area>"], var.required_data_tags.DataSubjectArea) && !contains(["", "<Line Of Business>"], var.required_data_tags.LineOfBusiness)
    error_message = "Defining all tags is required for this resource (reference https://confluence.sys.cigna.com/display/CLOUD/Cloud+Tagging+Requirements)."
  }
}

variable "optional_tags" {
  description = "Optional Cigna standard tags (reference https://confluence.sys.cigna.com/display/CLOUD/Cloud+Tagging+Requirements+v2.0)."
  type = map(string)
  default = {}
}

variable "optional_data_tags" {
  description = "Optional Cigna data at rest tags (reference https://confluence.sys.cigna.com/display/CLOUD/Cloud+Tagging+Requirements+v2.0)."
  type = map(string)
  default = {}
}
variable "alarm_account" {
  description = "Optional account for CloudWatch alarm funnel"
  type = string
  default = "746770431074"
}

variable "delete_marker_replication_status" {
  description = "Delete marker replication status for replication configuration"
  type = string
  default = "Disabled"
}
