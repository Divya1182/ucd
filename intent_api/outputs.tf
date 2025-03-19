/* output "endpoint" {
  value = module.presigned-url-vpc.vpc_endpoints_gateway[0].s3
}

output "golden-vpc" {
  value = module.presigned-url-vpc
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
} */