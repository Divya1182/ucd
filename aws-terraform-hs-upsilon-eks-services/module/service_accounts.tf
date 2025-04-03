
locals {
  oidc_provider_url = "https://${var.oidc_provider}"
  role_map = merge(
                    [ for application in var.applications : {
                        for policy in application.policy_name : "${application.role_name}-${policy}" => { 
                          policy    = "arn:aws:iam::${var.product_aws_acc_no}:policy/${policy}" 
                          role_name =  application.role_name
                        }
                      } 
                    ]...
                  ) # please do NOT remove the dots 
}

# To get thumbprint of OIDC url 
data "tls_certificate" "oidc_provider_certificate" {
  url = local.oidc_provider_url
}


# Register OIDC provider of EKS cluster
resource "aws_iam_openid_connect_provider" "eks_oidc" {
  url             = local.oidc_provider_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc_provider_certificate.certificates[0].sha1_fingerprint]
  tags            = var.required_common_tags
}


# Create trust policy for the role
data "aws_iam_policy_document" "eks_oidc_trust_policy" {
  for_each = var.applications

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${var.oidc_pr_acc_no}:oidc-provider/${var.oidc_provider}"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:sub"
      values   = ["system:serviceaccount:${each.value.eks_namespace}:${each.value.service_account_name}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# role in our AWS account to be assumed by shared-eks OIDC
resource "aws_iam_role" "eks_role" {
  for_each = var.applications
  name               = each.value.role_name
  assume_role_policy = data.aws_iam_policy_document.eks_oidc_trust_policy[each.key].json
  tags               = var.required_common_tags
  depends_on = [ aws_iam_openid_connect_provider.eks_oidc ]
}

# Attach policy to the created role for service account
resource "aws_iam_role_policy_attachment" "eks_role_policies" {
  for_each    = local.role_map
  role        = each.value.role_name
  policy_arn  = each.value.policy
  depends_on = [ aws_iam_role.eks_role ]
}

