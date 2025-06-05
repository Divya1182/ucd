variable "bef_cloudtrail_bucket_name" {
  
}
variable "resource_deletion_monitoring_kms" {
    type        = string
    description = "The display name of the alias."
    default     = ""
  
}

variable "resource_deletion_monitoring_kms_description" {
  type        = string
  description = "BEF KMS to keep the data at rest encrypted for S3, SQS, Dynamo and ES Domain"
  default     = "BEF KMS to keep the data at rest encrypted for S3, SQS, Dynamo and ES Domain"
}

variable "resource_deletion_monitoring_kms_customer_master_key_spec" {
  type        = string
  description = "Specifies whether the key contains a symmetric key or an asymmetric key pair and the encryption algorithms or signing algorithms that the key supports"
  default     = "SYMMETRIC_DEFAULT"
  validation {
    condition     = contains(["SYMMETRIC_DEFAULT", "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1"], var.presigned-url-kms-customer-master-key-spec)
    error_message = "Invalid input: customer_master_key_spec."
  }
}

variable "resource_deletion_monitoring_kms_enable_key_rotation" {
  type        = bool
  description = "Specifies whether key rotation is enabled."
  default     = true
}

variable "resource_deletion_monitoring_cw_event_rule" {
    type = string
  
}

variable "cloudtrail_resource_deletion_monitoring" {
    type = string
  
}

variable "cloudtrail_resource_deletion_log_group" {
    type = string
  
}

variable "resource_deletion_monitoring_lambda_function_name" {
    type = string

}

variable "resource_deletion_monitoring_lambda_handler_function" {
    type = string
  
}

variable "resource_deletion_monitoring_lambda_runtime" {
    type = string
  
}

variable "resource_deletion_monitoring_lambda_memory_size" {
  
}



bef_cloudtrail_bucket_name = "bef-cloudtrail-monitoring"
resource_deletion_monitoring_kms = "bef-cloudtrail-s3-kms-key"
resource_deletion_monitoring_cw_event_rule = "bef-cloudtrail-monitoring-event-rule"
cloudtrail_resource_deletion_monitoring = "bef-cloudtrail-resource-deletion-monitoring"
cloudtrail_resource_deletion_log_group = "/aws/cloudtrail/bef-cloudtrail-resource-deletion-monitoring"
resource_deletion_monitoring_lambda_function_name = "bef-resource-monitoring"
resource_deletion_monitoring_lambda_handler_function = "lambda_function.lambda_handler"
resource_deletion_monitoring_lambda_runtime = "python3.12"
resource_deletion_monitoring_lambda_memory_size      = 256
resource_deletion_monitoring_lambda_timeout_seconds  = 900




data "aws_iam_role" "resource_deletion_monitoring" {
  name = "BEFLambdaAccess"
}

locals {
  cloudtrail_bucket_name = "${var.bef_cloudtrail_bucket_name}-${data.aws_caller_identity.current.account_id}"
}