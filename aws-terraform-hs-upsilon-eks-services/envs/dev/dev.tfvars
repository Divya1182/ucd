required_common_tags = {
  AssetOwner       = "BEF_DEVELOPMENT@express-scripts.com" #Set this to the email address of the owner of this AWS account
  CostCenter       = "60031096"                            #Set to cost center for this project
  SecurityReviewID = "RITM8362068"                         #Set this to the RITM - Number in ServiceNow for the TSE request. Can be set to notAssigned when the solution is in the dev stage
  ServiceNowBA     = "BA14783"                         #Business Application Number of a Configuration Item in ServiceNow. Can be set to notAssigned when the solution is in the dev stage
  ServiceNowAS     = "AS050854"                         #Application Service Number within ServiceNow. Can be set to notAssigned when the solution is in the dev stage
  P2P              = "RITM8626285"
}

extra_tags = {
  BackupOwner = "BEF_DEVELOPMENT@express-scripts.com"
  Environment = "dev"
  Purpose     = "BEF-Artifacts Storage Solution"
}


required_data_tags = {
  DataSubjectArea        = "it"             # see expected values on confluence page above
  ComplianceDataCategory = "none"           # see expected values on confluence page above
  DataClassification     = "internal"       # see expected values on confluence page above
  BusinessEntity         = "healthServices" # see expected values on confluence page above
  LineOfBusiness         = "healthServices" # see expected values on confluence page above
}

# Policies can be created using RAAS module - https://github.sys.cigna.com/cigna/aws-roles-as-a-service
cluster_to_application_map = {
  hs-eks-1-dev = [{
                    application_name = "test-eks-dev"
                    eks_namespace = "bef-event-flow-eks-dev"
                    policy_name = ["Enterprise/BefEKSTestEKSPolicies"]
                  }
                ]
}
