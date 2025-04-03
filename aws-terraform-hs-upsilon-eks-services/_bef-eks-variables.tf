variable "cluster_to_application_map" {
  description = <<EOF
    Cluster map with list of application deployed in each cluster
    Key = The cluster name where applications are deployed
    Value = List of Objects({
      application_name= Springboot application name deployed in EKS cluster
      namespace       = EKS Namespace where application is deployed
      policy_arn      = List of policy arns which needs to be assigned to the Service Account role
    })
    
    Example:
    {
      hs-eks-1-dev = [{
                        application_name = "test-eks"
                        namespace = "bef-event-flow-eks-dev"
                        policy_arn = ["arn:aws:iam::364685145795:policy/Enterprise/intentApiS3Access", "arn:aws:iam::364685145795:policy/Enterprise/BefLambdaEC2NetworkAccess"]
                      },
                      {
                        application_name = "bef-eks"
                        namespace = "bef-event-flow-eks-dev"
                        policy_arn = ["arn:aws:iam::364685145795:policy/Enterprise/intentApiS3Access", "arn:aws:iam::364685145795:policy/Enterprise/BefLambdaEC2NetworkAccess"]
                      }
                    ]
      hs-eks-2-dev = [{
                        application_name = "test-eks"
                        namespace = "bef-event-flow-eks-dev"
                        policy_arn = ["arn:aws:iam::364685145795:policy/Enterprise/intentApiS3Access", "arn:aws:iam::364685145795:policy/Enterprise/BefLambdaEC2NetworkAccess"]
                      }
                    ]
    }
  EOF
  type = map(set(object({
    application_name = string
    eks_namespace = string
    policy_name = set(string)
  })))
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