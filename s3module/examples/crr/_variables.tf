variable "kms_accounts" {
  type = list(string)
}

variable "kms_key_administrators" {
  type = list(string)
}

variable "kms_key_users" {
  type = list(string)
}

variable "s3_default_resources" {
  type = list(string)
}

variable "s3_replicated_bucket_default_resources" {
  type = list(string)
}

variable "s3_default_users" {
  type = list(string)
}
