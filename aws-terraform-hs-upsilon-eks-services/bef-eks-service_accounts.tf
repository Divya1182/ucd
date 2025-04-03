terraform {
  required_version = ">= 0.15"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {}
}

# This module will register OIDC provider and will create 
# service account role for each cluster and its corresponding application
module "create_service_accounts" {
    for_each = var.cluster_to_application_map
    source              = "./module"
    oidc_provider       = local.cluster_map[each.key].oidc_provider
    oidc_pr_acc_no      = local.cluster_map[each.key].oidc_aws_acc_no
    applications = tomap(
      {
        for application in each.value: application.application_name => {
          application_name      = application.application_name
          eks_namespace         = application.eks_namespace
          policy_name            = application.policy_name
          role_name             = "${each.key}-${application.application_name}-irsa-role"
          service_account_name  = "${application.application_name}-service-account"
        }
      }
    )
    product_aws_acc_no = local.aws_account_number
    required_common_tags= var.required_common_tags
    required_data_tags  = var.required_data_tags
}