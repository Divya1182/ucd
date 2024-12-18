/* output "arn" {
  description = "ARN of Lambda"
  value       = module.custom_lambda.arn
}

output "invoke_arn" {
  description = "ARN to be used for invoking Lambda Function from API Gateway"
  value       =  module.custom_lambda.invoke_arn
}

output "function_name" {
  description = "Name of Lambda"
  value       = module.custom_lambda.function_name
}

output "version" {
  description = "Latest published version"
  value       = module.custom_lambda.version
} */

output "endpoint" {
  value = module.presigned-url-vpc.vpc_endpoints_gateway[0].s3
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}