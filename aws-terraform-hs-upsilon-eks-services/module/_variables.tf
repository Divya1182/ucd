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
    P2P              = string
  })

  validation {
    condition = alltrue([
      var.required_common_tags.AssetOwner != "",
      var.required_common_tags.CostCenter != "",
      var.required_common_tags.ServiceNowBA != "",
      var.required_common_tags.ServiceNowAS != "",
      var.required_common_tags.SecurityReviewID != "",
      var.required_common_tags.P2P != ""
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

variable "applications" {
  type = map(object({
    application_name = string
    eks_namespace = string
    role_name = string
    service_account_name = string
    policy_name = set(string)
  }))
}

variable "oidc_provider" {
  type = string
}

variable "oidc_pr_acc_no" {
  type = string
}

variable "product_aws_acc_no" {
  type = string
}

