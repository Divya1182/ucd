# Map of tags required for AWS resources
# https://confluence.sys.cigna.com/display/CLOUD/AWS+Required+Resource+Tags
aws_primary_accountID = "364685145795"
environment           = "dev"
log_level             = "DEBUG" # Debug is for DEV and QA, In Prod we need to set it to Error
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
  ServiceNowBA     = "BA14783"                         #Business Application Number of a Configuration Item in ServiceNow. Can be set to notAssigned when the solution is in the dev stage
  ServiceNowAS     = "AS050854"                         #Application Service Number within ServiceNow. Can be set to notAssigned when the solution is in the dev stage
  P2P              = "RITM8626285"
}

extra_tags = {
  BackupOwner = "BEF_DEVELOPMENT@express-scripts.com"
  Environment = "dev"
  Purpose     = "BEF-Artifacts Storage Solution"
}

alarm_sns_topic_arns = ["arn:aws:sns:us-east-1:929468956630:cloudwatch-alarm-funnel"]
alarm_app_name       = "bef-File-Storage"
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
lc_rule_id = "s3-default-lifecycle-rule"

# presigned-url configs
#VPC
bef-vpc-routable-cidr     = ["10.190.250.0/27"]
bef-vpc-non-routable-cidr = ["100.127.0.0/16"]

#Lambda
bef-presigned-url-lambda-function-name    = "bef-presigned-url"
bef-presigned-url-lambda-handler-function = "presigned-url.presigned_url"
bef-presigned-url-lambda-runtime          = "python3.12"
bef-presigned-url-lambda_memory_size      = 256
bef-presigned-url-lambda_timeout_seconds  = 30

bef-callback-lambda-function-name         = "bef-intent-upload-callback"
bef-callback-lambda-handler-function      = "callback.callback"
bef-callback-lambda-runtime               = "python3.12"
bef-callback-lambda_memory_size           = 256
bef-callback-lambda_timeout_seconds       = 30

#IntentAPI callback URL
callback-url        = "https://api-dev.express-scripts.io/evernorth/v2/intents/:artifact_id:/broadcastArtifact"
token-service-url   = "https://api-dev.express-scripts.io/v1/auth/oauth2/token"

# Mode info on Authinator - https://confluence.sys.cigna.com/display/AUT/API+Gateway+AWS+Lambda+Integration
authinator-principal-arn = "arn:aws:iam::178278630275:role/GATEWAY"

#S3
bef_bucket_name              = "bef-storage"
use_default_lc_configuration = true
enable_bucket_versioning     = true
logging_is_enabled           = true
enable_bucket_keys           = true
crr_is_enabled               = false
enable_crr                   = true
cors_rule_is_enabled         = true
cors_allowed_headers         = ["*"]
cors_allowed_methods         = ["POST", "PUT", "GET", "DELETE"]
cors_allowed_origins         = ["*"]

#KMS
presigned-url-kms-name = "bef-presigned-url-kms"

# VPC
vpc_name_prefix         = "presigned-url"
vpc_security_group_name = "presigned-url-sg"

# Secret Manager
intent_consumer_secret_name = "intentapi/intake_services_callback_consumer"

# Eventbridge
eventbridge_notification_name = "bef_storage_file_creation_notification"

#layer
lambda_layer_requests = "bef-presigned-url-request-layer"

#Region
region = "us-east-1"

# Polaris Access point 
ap_polaris = [
  "arn:aws:iam::736713978530:role/hs-polaris-doc-parser_lambda-dev-lambda-role",
  "arn:aws:iam::736713978530:role/hs-polaris-doc-splitter_lambda-dev-lambda-role",
  "arn:aws:iam::736713978530:role/hs-polaris-doc-ingest_lambda-dev-lambda-role",
  "arn:aws:iam::736713978530:role/hs-polaris-zip-extractor-lambda-dev-lambda-role",
  "arn:aws:iam::736713978530:role/get-presigned-url-role"
]

presigned-url-crr-s3-kms-name = "bef-presigned-url-crr-s3-kms"
