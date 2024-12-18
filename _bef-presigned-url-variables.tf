# Common
variable "aws_primary_accountID" {
  type    = string
  default = ""
}

# KMS Variables
variable "presigned-url-kms-description" {
  type        = string
  description = "BEF KMS to keep the data at rest encrypted for S3, SQS, Dynamo and ES Domain"
  default     = "BEF KMS to keep the data at rest encrypted for S3, SQS, Dynamo and ES Domain"
}

variable "presigned-url-kms-customer-master-key-spec" {
  type        = string
  description = "Specifies whether the key contains a symmetric key or an asymmetric key pair and the encryption algorithms or signing algorithms that the key supports"
  default     = "SYMMETRIC_DEFAULT"
  validation {
    condition     = contains(["SYMMETRIC_DEFAULT", "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1"], var.presigned-url-kms-customer-master-key-spec)
    error_message = "Invalid input: customer_master_key_spec."
  }
}

variable "presigned-url-kms-enable-key-rotation" {
  type        = bool
  description = "Specifies whether key rotation is enabled."
  default     = true
}

variable "presigned-url-kms-name" {
  type        = string
  description = "The display name of the alias."
  default     = ""
}

#######
# VPC Routable CIDR Config - RITM8278532 #
variable "bef-vpc-routable-cidr" {
  type        = list(string)
  description = "Private VPC with Corporate network connectivity"
}
variable "bef-vpc-non-routable-cidr" {
  type        = list(string)
  description = "Private VPC non-routable (for AWS internal connectivity)"
}

variable "vpc_name_prefix" {
  type        = string
  description = <<-EOT
    Name for the VPC. It will be prepended to all resource Name tags (i.e. "-golden-vpc", "-golden-subnet", etc).
    If left blank, "cigna" will be used.
  EOT
  default     = "cigna"
}

variable "vpc_security_group_name" {
  type        = string
  description = <<-EOT
    Name for the VPC. It will be prepended to all resource Name tags (i.e. "-golden-vpc", "-golden-subnet", etc).
    If left blank, "cigna" will be used.
  EOT
  default     = "cigna-sg"
}


#######
# S3 Bucket Config #

variable "bef_bucket_name" {
  type        = string
  description = "S3 Bucket to store intent artifacts"
  default     = ""
  validation {
    condition     = var.bef_bucket_name != ""
    error_message = "S3 bucket name required."
  }
}

#######
#
# Lambda config
#
variable "environment" {
  description = "What environment is this representing?"
  type        = string
  default     = "unknown"
}

variable "log_level" {
  description = "To set log level"
  type        = string
  validation {
    condition     = contains(["CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG"], var.log_level)
    error_message = "Allowed values are [CRITICAL, ERROR, WARNING, INFO, DEBUG]."
  }
}

variable "bef-presigned-url-lambda_memory_size" {
  description = "How much ram to allocate for the lambda"
  type        = number
  default     = 256
}

variable "bef-presigned-url-lambda_timeout_seconds" {
  description = "How much time until the invocation times out"
  type        = number
  default     = 30
}


variable "bef-presigned-url-lambda-handler-function" {
  type        = string
  description = "Lambda function entry point"
  default     = "lambda_function.handler"
}

variable "bef-presigned-url-lambda-runtime" {
  type        = string
  description = "Runtime config"
  default     = "python3.11"
}

variable "bef-presigned-url-lambda-function-name" {
  type        = string
  description = "Lambda function name"
  default     = ""
  validation {
    condition     = var.bef-presigned-url-lambda-function-name != ""
    error_message = "Lambda function name required."
  }
}

variable "authinator-principal-arn" {
  type    = string
  default = ""
}

#######
#
# Alarm Setup
#

variable "alarm_sns_topic_arns" {
  description = "The ARNs for the SNS topic to send alarms to"
  default     = []
}

variable "alarm_app_name" {
  description = "The app name for alarms"
  type        = string
  default     = ""
}

variable "alarm_thresholds" {
  description = "Thresholds for Lambda alarms. Set to -1 if you do not want the alarm."
  default = {
    info_error_rate            = 10
    warn_error_rate            = -1
    critical_error_rate        = 20
    info_throttles             = 10
    warn_throttles             = 20
    critical_throttles         = -1
    info_duration_rate         = -1
    warn_duration_rate         = -1
    critical_duration_rate     = -1
    info_duration_limit_ms     = -1
    warn_duration_limit_ms     = -1
    critical_duration_limit_ms = -1
  }
}



#######
#
# Tags
#
variable "required_common_tags" {
  description = "Required common resource tags as defined by the AWS Resource Tagging Requirements spec"
  type = object({
    AssetOwner       = string
    CostCenter       = string
    ServiceNowBA     = string
    ServiceNowAS     = string
    SecurityReviewID = string
  })

  validation {
    condition = alltrue([
      var.required_common_tags.AssetOwner != "",
      var.required_common_tags.CostCenter != "",
      var.required_common_tags.ServiceNowBA != "",
      var.required_common_tags.ServiceNowAS != "",
      var.required_common_tags.SecurityReviewID != ""
    ])
    error_message = "Required tags cannot be empty."
  }
}

variable "extra_tags" {
  description = "Map of custom tags to apply to resources"
  type        = map(string)
  default     = {}
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

variable "enable_crr" {
  default     = false
  description = "True to enable bucket cross region replication. Defaults to false"
  type        = bool
}

variable "crr_is_enabled" {
  default     = false
  description = "True to enable bucket cross region replication. Defaults to false"
  type        = bool
}

variable "lc_rule_id" {
  description = "Unique name of lifecycle rule"
  type        = string
}

variable "enable_bucket_versioning" {
  default     = true
  description = "Enable versioning on the S3 bucket"
  type        = bool
}

variable "cors_rule_is_enabled" {
  default     = false
  description = "True to enable bucket access logging. Defaults to false"
  type        = bool
}

variable "enable_bucket_keys" {
  default     = true
  description = "True to enable bucket-level key for SSE to reduce the request traffic from Amazon S3 to AWS KMS. Defaults to false"
  type        = bool
}

variable "cors_allowed_origins" {
  default     = ["*"]
  description = "Lifecycle policy rule that governs the transition storage class selected based on number of days. This is used after the first rule is met"
  type        = list(any)
}

variable "cors_allowed_methods" {
  default     = ["GET"]
  description = "Lifecycle policy rule that governs the transition storage class selected based on number of days. This is used after the first rule is met"
  type        = list(any)
}

variable "cors_allowed_headers" {
  default     = ["*"]
  description = "Lifecycle policy rule that governs the transition storage class selected based on number of days. This is used after the first rule is met"
  type        = list(any)
}

variable "use_default_lc_configuration" {
  description = "Set to false if you want to use a custom lifecycle rule configuration for your S3 bucket."
  type        = bool
  default     = true
}

variable "logging_is_enabled" {
  type        = bool
  description = "S3 logging enabled"
  default     = false
}


