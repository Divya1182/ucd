module "presigned-url-vpc" {
  source                        = "git::https://github.sys.cigna.com/cigna/AWS-GoldenVPC.git?ref=0.7.0"
  cidr_blocks_routable          = var.bef-vpc-routable-cidr
  cidr_blocks_non_routable      = var.bef-vpc-non-routable-cidr
  availability_zones            = ["${data.aws_region.current_region.name}a", "${data.aws_region.current_region.name}b", "${data.aws_region.current_region.name}c"]
  vpc_gateway_endpoint_services = ["s3"]
  vpc_endpoint_service_policies = {
    s3 = data.aws_iam_policy_document.presigned-url-s3-endpoint-policy.json
  }
  name_prefix = var.vpc_name_prefix
  cigna_tags  = merge(var.required_common_tags, var.extra_tags)
}