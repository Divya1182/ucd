# Map of tags required for AWS resources
# https://confluence.sys.cigna.com/display/CLOUD/AWS+Required+Resource+Tags
aws_primary_accountID = "310705775535"
environment           = "uat"
log_level             = "DEBUG" # Debug is for DEV and uat, In Prod we need to set it to Error
/* 
"CRITICAL"
"ERROR"
"WARNING"
"INFO"
"DEBUG" 
*/

required_common_tags = {
  AssetOwner       = "BEF_DEVELOPMENT@express-scripts.com" #Set this to the email address of the owner of this AWS account
  CostCenter       = "60031096"                            #Set to cost center for this project
  SecurityReviewID = "RITM8362068"                         #Set this to the RITM - Number in ServiceNow for the TSE request. Can be set to notAssigned when the solution is in the dev stage
  ServiceNowBA     = "BA14783"                             #Business Application Number of a Configuration Item in ServiceNow. Can be set to notAssigned when the solution is in the dev stage
  ServiceNowAS     = "AS050856"                            #Application Service Number within ServiceNow. Can be set to notAssigned when the solution is in the dev stage
  P2P              = "RITM8626285"
}
extra_tags = {
  BackupOwner = "BEF_DEVELOPMENT@express-scripts.com"
  Environment = "uat"
  Purpose     = "BEF-Artifacts Storage Solution"
}


alarm_sns_topic_arns = ["arn:aws:sns:us-east-1:929468956630:cloudwatch-alarm-funnel"]
alarm_app_name       = "bef-File-Storage-uat"
alarm_thresholds = {
  info_error_rate            = 10
  warn_error_rate            = 15
  critical_error_rate        = 20
  info_throttles             = 10
  warn_throttles             = 20
  critical_throttles         = 30
  info_duration_rate         = -1
  warn_duration_rate         = -1
  critical_duration_rate     = -1
  info_duration_limit_ms     = 2000
  warn_duration_limit_ms     = 3000
  critical_duration_limit_ms = 5000
}

required_data_tags = {
  DataSubjectArea        = "it"             # see expected values on confluence page above
  ComplianceDataCategory = "none"           # see expected values on confluence page above
  DataClassification     = "internal"       # see expected values on confluence page above
  BusinessEntity         = "healthServices" # see expected values on confluence page above
  LineOfBusiness         = "healthServices" # see expected values on confluence page above
}
lc_rule_id = "s3-default-lifecycle-rule-uat"

# presigned-url configs
#VPC
bef-vpc-routable-cidr     = ["10.191.154.160/27"]
bef-vpc-non-routable-cidr = ["100.127.0.0/16"]

#Lambda
bef-presigned-url-lambda-function-name    = "bef-presigned-url-uat"
bef-presigned-url-lambda-handler-function = "presigned-url.presigned_url"
bef-presigned-url-lambda-runtime          = "python3.11"
bef-presigned-url-lambda_memory_size      = 256
bef-presigned-url-lambda_timeout_seconds  = 30

# bef-callback-lambda-function-name         = "bef-intent-upload-callback-uat"
# bef-callback-lambda-handler-function      = "callback.callback"
# bef-callback-lambda-runtime               = "python3.12"
# bef-callback-lambda_memory_size           = 256
# bef-callback-lambda_timeout_seconds       = 30


# #IntentAPI callback URL
# callback-url        = "https://internalapi-uat.express-scripts.io/evernorth/v2/intents/:artifact_id:/broadcastArtifact"
# token-service-url   = "https://internalapi-uat.express-scripts.io/v1/auth/oauth2/token"


# Mode info on Authinator - https://confluence.sys.cigna.com/display/AUT/API+Gateway+AWS+Lambda+Integration
authinator-principal-arn = "arn:aws:iam::770263348724:role/GATEWAY"

#S3
bef_bucket_name              = "bef-storage-uat"
use_default_lc_configuration = true
enable_bucket_versioning     = true
logging_is_enabled           = true
enable_bucket_keys           = true
crr_is_enabled               = false
enable_crr                   = false
cors_rule_is_enabled         = true
cors_allowed_headers         = ["*"]
cors_allowed_methods         = ["POST", "PUT", "GET", "DELETE"]
cors_allowed_origins         = ["*"]

#KMS
presigned-url-kms-name = "bef-presigned-url-kms-uat"

# VPC
vpc_name_prefix         = "presigned-url-uat"
vpc_security_group_name = "presigned-url-sg-uat"

#Region
region = "us-east-1"

#layer
lambda_layer_requests = "bef-presigned-url-request-layer-uat"


# Polaris Access point 
ap_polaris = [
  "arn:aws:iam::056615092764:role/hs-polaris-doc-parser_lambda-qa-lambda-role",
  "arn:aws:iam::056615092764:role/hs-polaris-doc-splitter_lambda-qa-lambda-role",
  "arn:aws:iam::056615092764:role/hs-polaris-doc-ingest_lambda-qa-lambda-role",
  "arn:aws:iam::056615092764:role/hs-polaris-zip-extractor-lambda-qa-lambda-role",
  "arn:aws:iam::056615092764:role/get-presigned-url-role"
]

#Databricks
databricks_aws_role = "arn:aws:iam::035074925037:role/UCLandzAccessrole"

# Dynamo Config
dynamo-tablename      = "bef-general-storage-index-uat"
# This variable takes values from default setting for all other environment
dynamo-vpc-endpoint   = "bef-s3-search-dynamo-endpoint-uat"
# General Purpose bucket name prefix
general-purpose-storage = "bef-general-storage-uat"

general-callback-lambda-function-name = "bef-general-storage-callback-uat"
general-callback-handler-function     = "callback.handle_callback"
callback-notification-name            = "bef-general-storage-notification-uat"
intent-consumer-secret-name           = "bef-general-purpose-callback/intent-callback-configuration-uat"
tf-account-id = "310705775535"


