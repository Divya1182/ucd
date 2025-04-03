# EKS Cluster map
locals {
  cluster_map = {
    # DEV Clusters
    hs-eks-1-dev	= {
        oidc_provider 	= "oidc.eks.us-east-1.amazonaws.com/id/68230522CBE22E1EEA35651436C78388"
        oidc_aws_acc_no = "783341671408"
    }
    hs-eks-2-dev	= {
        oidc_provider 	= "oidc.eks.us-east-1.amazonaws.com/id/CBE1D514777581A884F1F4C1DE8F8BC9"
        oidc_aws_acc_no = "783341671408"
    }

    # QA Clusters
    hs-eks-1-qa		= {
        oidc_provider 	= "oidc.eks.us-east-1.amazonaws.com/id/69B9D65FD746DECC36F60B33F95A5A17"
        oidc_aws_acc_no = "945023953769"
    }
    hs-eks-2-qa		= {
        oidc_provider 	= "oidc.eks.us-east-1.amazonaws.com/id/A50012E6AB8BBF6CB5B8CA7ABA52C9AE"
        oidc_aws_acc_no = "945023953769"
    }

    # UAT Clusters
    hs-eks-1-uat	= {
        oidc_provider 	= "oidc.eks.us-east-1.amazonaws.com/id/405089F15E56349F9DC0A46D84B31021"
        oidc_aws_acc_no = "945023953769"
    }
    hs-eks-2-uat	= {
        oidc_provider 	= "oidc.eks.us-east-1.amazonaws.com/id/0DD6CF96922BDBECF0FD753FEB721D56"
        oidc_aws_acc_no = "945023953769"
    }

    # PROD Clusters
    hs-eks-1-prod	= {
        oidc_provider 	= "oidc.eks.us-east-1.amazonaws.com/id/14379390DCFA87D271E4717E05046CBB"
        oidc_aws_acc_no = "530155283313"
    }
    hs-eks-2-prod	= {
        oidc_provider 	= "oidc.eks.us-east-1.amazonaws.com/id/7A5CAAD74AC090C6C133EB9BD83468BC"
        oidc_aws_acc_no = "530155283313"
    }
    hs-eks-3-prod	= {
        oidc_provider 	= "oidc.eks.us-east-1.amazonaws.com/id/19D30AFD95AEA2F8887D29C457A86F07"
        oidc_aws_acc_no = "530155283313"
    }
    hs-eks-4-prod	= {
        oidc_provider 	= "oidc.eks.us-east-1.amazonaws.com/id/051BBA17FB0919F997EA8E23226D8329"
        oidc_aws_acc_no = "530155283313"
    }
    hs-eks-5-prod	= {
        oidc_provider 	= "oidc.eks.us-east-1.amazonaws.com/id/979B7E8E08DB4B2013D324D038FD96A6"
        oidc_aws_acc_no = "530155283313"
    }
    hs-eks-6-prod	= {
        oidc_provider 	= "oidc.eks.us-east-1.amazonaws.com/id/CF47B5004C420057A682541E2A965A2C"
        oidc_aws_acc_no = "530155283313"
    }
    hs-eks-7-prod	= {
        oidc_provider 	= "oidc.eks.us-east-1.amazonaws.com/id/75D2BE0D0A13F34055A09B2DC034C5B7"
        oidc_aws_acc_no = "530155283313"
    }
    hs-eks-8-prod	= {
        oidc_provider 	= "oidc.eks.us-east-1.amazonaws.com/id/DFBCFC32D7C63339D49C15F4258BB8BB"
        oidc_aws_acc_no = "530155283313"
    }
  }

  aws_account_number = data.aws_caller_identity.current.account_id
}