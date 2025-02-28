# S3

Creates an s3 bucket with CIP standards built in, including: proper tagging, encryption, data retention lifecycle
policies, optional cross region replication, versioning, and public access turned off by default.
This module also sets up two standard s3 metric alarms including 4xx errors and 5xx errors.
The thresholds and periods can be set via variables, but most configurations have reasonable default values.

**Important**

In this version of the module, the KMS key creation was removed. The module requires that an existing KMS key be used to encrypt data in the bucket.
This was done so as not to propagate the pattern of creating a KMS key per bucket. KMS keys should be grouped logically based on the application
they support. For example, if an application contains SQS and S3, those two resources should be encrypted with the same key. In general, find
a logical grouping of resources that makes sense and use the same key for those.

## S3 Contents
- CIP required Tags
- Cross Region Replication
- KMS Encryption
- Lifecycle
- Versioning

## Required Tags

Required common tags and required tags for data at rest now have to be filled in and are passed as an object with
specific attributes

## Optional Tags

Optional tags are mostly filled in by the module itself but an object containing the RegionalRestriction and `app_name`
can optionally be passed to the module as well

## Provider Specification

This module _requires_ that a provider configuration for the main provider and the cross region replication provider
is passed into the module. 

** IMPORTANT! The cross region replication provider is required even if cross region replication is disabled**
** Please see the exmaples **

```
provider "aws" {
  profile = "saml"
  region  = "us-east-1"
}

provider "aws" {
  alias   = "crr"
  profile = "saml"
  region  = "us-west-1"
}

providers = {
    aws.replication_region = "aws.crr"
    aws.source_region      = "aws"
}
```

## Cross Region Replication Permissions

For cross region replication to work correctly there are a few requirements:

`enable_crr` has to be set to `true`

There has to be a role in the account that has permission to replicate data on your behalf. This role has to be created
via `RaaS` and will look similar to the following:

    ---
    managedPolicyArns:
      -
        name: S3CRRPerms
        awsmanaged: false

    service: s3


The policy on the role should look like the following:

    ---
    statements:
      -
        effect: "Allow"
        actions:
          - "s3:GetObjectLegalHold"
          - "s3:GetObjectRetention"
          - "s3:GetObjectVersion"
          - "s3:GetObjectVersionAcl"
          - "s3:GetObjectVersionForReplication"
          - "s3:GetObjectVersionTagging"
          - "s3:GetReplicationConfiguration"
          - "s3:ListBucket"
          - "s3:ReplicateDelete"
          - "s3:ReplicateObject"
          - "s3:ReplicateTags"
        resources:
          - "arn:aws:s3:::da-datastore-*"

      -
        effect: "Allow"
        actions:
          - "kms:Decrypt"
        Condition:
          StringLike:
            kms:ViaService:
              - "s3.us-east-1.amazonaws.com"
            kms:EncryptionContext:aws:s3:arn:
              - "arn:aws:s3:::*/*"
        resources:
          - "*"

      -
        effect: "Allow"
        actions:
          - "kms:Encrypt"
        Condition:
          StringLike:
            kms:ViaService:
              - "s3.us-west-1.amazonaws.com"
            kms:EncryptionContext:aws:s3:arn:
              - "arn:aws:s3:::*/*"
        resources:
          - "*"

`crr_role_arn` must point to the created role arn. In this case:

    data "aws_iam_role" "replication_role" {
      name = "S3CRR"
    }

 `crr_role_arn = data.aws_iam_role.replication_role.arn`

 Additionally, the role that deploys the infrastructure will need the following `Allow`:

      -
        effect: "Allow"
        actions:
          - "iam:PassRole"
        resources:
          - !Sub "arn:aws:iam::${AWS::AccountId}:role/Enterprise/S3CRR"

## Enabling S3 Server Access Logging

`NOTE: S3 object level logging is preferred, and enabled by default in Cloudtrail for all Cigna AWS. Only use S3 server access logging for specific use cases.`

For server access logging to work correctly there are a few requirements:

`enable_logging` has to be set to `true`
`logging_target_bucket` = `bucket-you-want-to-send-logs-to`
`logging_target_prefix` = `optional-log-prefix`

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |
| <a name="provider_aws.replication"></a> [aws.replication](#provider\_aws.replication) | ~> 4.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.s3_alarm_4xx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.s3_alarm_5xx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_s3_bucket.replicated_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.bucket_acl_replicated_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_acl.bucket_acl_this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_cors_configuration.bucket_cors_configuration_this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.s3_bucket_lifecycle_replicated_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.s3_bucket_lifecycle_this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.s3_bucket_logging_replicated_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_logging.s3_bucket_logging_this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_metric.crr_bucket_metric](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_metric) | resource |
| [aws_s3_bucket_metric.s3_bucket_metric](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_metric) | resource |
| [aws_s3_bucket_policy.crr_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.s3_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.crr_public_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.public_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_replication_configuration.replication_configuration_this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.server_side_encryption_configuration_replicated_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.server_side_encryption_configuration_this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.s3_bucket_versioning_replicated_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.s3_bucket_versioning_this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_iam_account_alias.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_account_alias) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_account"></a> [alarm\_account](#input\_alarm\_account) | Optional account for CloudWatch alarm funnel | `string` | `"746770431074"` | no |
| <a name="input_alarm_app_name"></a> [alarm\_app\_name](#input\_alarm\_app\_name) | An optional app name to give to the alarm if there are multiple alarms in an account | `string` | `""` | no |
| <a name="input_alarm_env"></a> [alarm\_env](#input\_alarm\_env) | An optional environment to give to the alarm if there are two logical environments in one account | `string` | `""` | no |
| <a name="input_alarm_evaluation_periods"></a> [alarm\_evaluation\_periods](#input\_alarm\_evaluation\_periods) | The number of periods over which data is compared to the specified threshold | `number` | `5` | no |
| <a name="input_alarm_period"></a> [alarm\_period](#input\_alarm\_period) | The period in seconds over which the specified statistic is applied | `number` | `60` | no |
| <a name="input_alarm_region"></a> [alarm\_region](#input\_alarm\_region) | The region to use for the alarm funnel. Supported regions are us-east-1 and eu-west-2. | `string` | `"us-east-1"` | no |
| <a name="input_alarm_severity_4xx"></a> [alarm\_severity\_4xx](#input\_alarm\_severity\_4xx) | The alarm severity level for 4xx errors. Allowed values are `WARN` or `CRITICAL` | `string` | `WARN` | no |
| <a name="input_alarm_severity_5xx"></a> [alarm\_severity\_5xx](#input\_alarm\_severity\_5xx) | The alarm severity level for 5xx errors. Allowed values are `WARN` or `CRITICAL` | `string` | `WARN` | no |
| <a name="input_alarm_threshold_4xx"></a> [alarm\_threshold\_4xx](#input\_alarm\_threshold\_4xx) | The number of data points to trigger the alarm for 4xx errors | `number` | `5` | no |
| <a name="input_alarm_threshold_5xx"></a> [alarm\_threshold\_5xx](#input\_alarm\_threshold\_5xx) | The number of data points to trigger the alarm for 5xx errors | `number` | `5` | no |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | The name of the app that this resource supports | `string` | `""` | no |
| <a name="input_bucket_acl"></a> [bucket\_acl](#input\_bucket\_acl) | The canned bucket ACL policy to be used if ACLs are enabled via [enable_bucket_acl](#input\_enable\_bucket\_acl) | `string` | `"BucketOwnerPreferred"` | no |
| <a name="input_bucket_kms_key_id"></a> [bucket\_kms\_key\_id](#input\_bucket\_kms\_key\_id) | An existing KMS key id used to encrypt this bucket | `string` | n/a | yes |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | The name of the s3 bucket that will be created | `string` | n/a | yes |
| <a name="input_bucket_policy"></a> [bucket\_policy](#input\_bucket\_policy) | A JSON document with the Bucket Policy to be placed on the Bucket | `string` | n/a | yes |
| <a name="input_cors_allowed_headers"></a> [cors\_allowed\_headers](#input\_cors\_allowed\_headers) | Lifecycle policy rule that governs the transition storage class selected based on number of days. This is used after the first rule is met | `list` | `[]` | no |
| <a name="input_cors_allowed_methods"></a> [cors\_allowed\_methods](#input\_cors\_allowed\_methods) | Lifecycle policy rule that governs the transition storage class selected based on number of days. This is used after the first rule is met | `list` | <pre>[<br>  "GET"<br>]</pre> | no |
| <a name="input_cors_allowed_origins"></a> [cors\_allowed\_origins](#input\_cors\_allowed\_origins) | Lifecycle policy rule that governs the transition storage class selected based on number of days. This is used after the first rule is met | `list` | `[]` | no |
| <a name="input_cors_expose_headers"></a> [cors\_expose\_headers](#input\_cors\_expose\_headers) | Lifecycle policy rule that governs the transition storage class selected based on number of days. This is used after the first rule is met | `list` | `[]` | no |
| <a name="input_cors_max_age"></a> [cors\_max\_age](#input\_cors\_max\_age) | Lifecycle policy rule, for older versions, that governs the transition to next storage class based on number of days | `number` | `90` | no |
| <a name="input_cors_rule_is_enabled"></a> [cors\_rule\_is\_enabled](#input\_cors\_rule\_is\_enabled) | True to enable bucket access logging. Defaults to false | `bool` | `false` | no |
| <a name="input_crr_bucket_kms_key_id"></a> [crr\_bucket\_kms\_key\_id](#input\_crr\_bucket\_kms\_key\_id) | An existing KMS key id to be used with the replication bucket | `string` | `""` | no |
| <a name="input_crr_bucket_policy"></a> [crr\_bucket\_policy](#input\_crr\_bucket\_policy) | A JSON document with the Bucket Policy to be placed on the Bucket | `string` | `""` | no |
| <a name="input_crr_role_arn"></a> [crr\_role\_arn](#input\_crr\_role\_arn) | The arn for the role that will handle replicating the bucket. This is only required if replication is enabled | `string` | `null` | no |
| <a name="input_delete_marker_replication_status"></a> [delete\_marker\_replication\_status](#input\_delete\_marker\_replication\_status) | Delete marker replication status for replication configuration | `string` | `"Disabled"` | no |
| <a name="input_enable_bucket_400_error_alarm"></a> [enable\_bucket\_400\_error\_alarm](#input\_enable\_bucket\_400\_error\_alarm) | If true, enable 400 error alarm on the bucket. This has the possibility to generate overwhelming false alarams | `bool` | `true` | no |
| <a name="input_enable_bucket_acl"></a> [enable\_bucket\_acl](#input\_enable\_bucket\_acl) | True to enable the bucket ACL to allow object writers to be owners. Defaults to false | `bool` | `false` | no |
| <a name="input_enable_bucket_keys"></a> [enable\_bucket\_keys](#input\_enable\_bucket\_keys) | True to enable bucket-level key for SSE to reduce the request traffic from Amazon S3 to AWS KMS. Defaults to true | `bool` | `true` | no |
| <a name="input_enable_bucket_versioning"></a> [enable\_bucket\_versioning](#input\_enable\_bucket\_versioning) | Enable versioning on the S3 bucket | `bool` | `true` | no |
| <a name="input_enable_crr"></a> [enable\_crr](#input\_enable\_crr) | True to enable bucket cross region replication. Defaults to false | `bool` | `false` | no |
| <a name="input_enable_expire_current_versions"></a> [enable\_expire\_current\_versions](#input\_enable\_expire\_current\_versions) | If true, current versions will be expired after a specified number of days. | `bool` | `false` | no |
| <a name="input_enable_expire_non_current_versions"></a> [enable\_expire\_non\_current\_versions](#input\_enable\_expire\_non\_current\_versions) | If true, non current versions will be expired after a specified number of days. | `bool` | `false` | no |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | True to enable bucket access logging. Defaults to false | `bool` | `false` | no |
| <a name="input_force_destroy_bucket"></a> [force\_destroy\_bucket](#input\_force\_destroy\_bucket) | Boolean for forcibly destroying the s3 bucket | `bool` | `false` | no |
| <a name="input_force_destroy_crr_bucket"></a> [force\_destroy\_crr\_bucket](#input\_force\_destroy\_crr\_bucket) | Boolean for forcibly destroying the s3 crr bucket | `bool` | `false` | no |
| <a name="input_use_default_lc_configuration"></a> [use\_default\_lc\_configuration](#input\_use\_default\_lc\_configuration) | Set to false if you want to use a custom lifecycle rule configuration for your S3 bucket. | `bool` | `true` | no |
| <a name="input_lc_abort_incomplete_upload_days"></a> [lc\_abort\_incomplete\_upload\_days](#input\_lc\_abort\_incomplete\_upload\_days) | Number of days until failed multipart uploads are deleted | `number` | `7` | no |
| <a name="input_lc_current_expiration_days"></a> [lc\_current\_expiration\_days](#input\_lc\_current\_expiration\_days) | Lifecycle policy rule that expires current versions of objects after specified number of days | `number` | `365` | no |
| <a name="input_lc_non_current_expiration_days"></a> [lc\_non\_current\_expiration\_days](#input\_lc\_non\_current\_expiration\_days) | Lifecycle policy rule that expires non current versions of objects after specified number of days | `number` | `7` | no |
| <a name="input_lc_prefix"></a> [lc\_prefix](#input\_lc\_prefix) | Scope the lifecycle policy to a specific sub directory. Pass in empty string to scope to bucket | `string` | `""` | no |
| <a name="input_lc_remove_expired_deletion_markers"></a> [lc\_remove\_expired\_deletion\_markers](#input\_lc\_remove\_expired\_deletion\_markers) | Flag for S3 to delete expired deletion markers on versioned buckets | `bool` | `true` | no |
| <a name="input_lc_rule_id"></a> [lc\_rule\_id](#input\_lc\_rule\_id) | Unique name of lifecycle rule | `string` | n/a | yes |
| <a name="input_lc_transition_1_days"></a> [lc\_transition\_1\_days](#input\_lc\_transition\_1\_days) | Lifecycle policy rule that governs the transition to next storage class based on number of days | `number` | `90` | no |
| <a name="input_lc_transition_1_storage_class"></a> [lc\_transition\_1\_storage\_class](#input\_lc\_transition\_1\_storage\_class) | Lifecycle policy rule that governs the transition storage class selected based on number of days | `string` | `"INTELLIGENT_TIERING"` | no |
| <a name="input_lc_transition_2_days"></a> [lc\_transition\_2\_days](#input\_lc\_transition\_2\_days) | Lifecycle policy rule that governs the transition to next storage class based on number of days. This is used after the first rule is met | `number` | `2555` | no |
| <a name="input_lc_transition_2_storage_class"></a> [lc\_transition\_2\_storage\_class](#input\_lc\_transition\_2\_storage\_class) | Lifecycle policy rule that governs the transition storage class selected based on number of days. This is used after the first rule is met | `string` | `"GLACIER"` | no |
| <a name="input_lc_version_transition_1_days"></a> [lc\_version\_transition\_1\_days](#input\_lc\_version\_transition\_1\_days) | Lifecycle policy rule, for older versions, that governs the transition to next storage class based on number of days | `number` | `90` | no |
| <a name="input_lc_version_transition_1_storage_class"></a> [lc\_version\_transition\_1\_storage\_class](#input\_lc\_version\_transition\_1\_storage\_class) | Lifecycle policy rule, for older versions, that governs the transition storage class selected based on number of days | `string` | `"INTELLIGENT_TIERING"` | no |
| <a name="input_lc_version_transition_2_days"></a> [lc\_version\_transition\_2\_days](#input\_lc\_version\_transition\_2\_days) | Lifecycle policy rule, for older versions, that governs the transition to next storage class based on number of days. This is used after the first rule is met | `number` | `2555` | no |
| <a name="input_lc_version_transition_2_storage_class"></a> [lc\_version\_transition\_2\_storage\_class](#input\_lc\_version\_transition\_2\_storage\_class) | Lifecycle policy rule, for older versions, that governs the transition storage class selected based on number of days. This is used after the first rule is met | `string` | `"GLACIER"` | no |
| <a name="input_logging_target_bucket"></a> [logging\_target\_bucket](#input\_logging\_target\_bucket) | The name of the bucket that will receive the log objects. This is only required if enable\_logging = true | `string` | `""` | no |
| <a name="input_logging_target_bucket_replicated_bucket"></a> [logging\_target\_bucket\_replicated\_bucket](#input\_logging\_target\_bucket\_replicated\_bucket) | The name of the bucket that will receive the log objects from the replicated bucket. This is only required if enable\_logging = true | `string` | `""` | no |
| <a name="input_logging_target_prefix"></a> [logging\_target\_prefix](#input\_logging\_target\_prefix) | To specify a key prefix for log objects. | `string` | `""` | no |
| <a name="input_optional_data_tags"></a> [optional\_data\_tags](#input\_optional\_data\_tags) | Optional Cigna data at rest tags (reference https://confluence.sys.cigna.com/display/CLOUD/Cloud+Tagging+Requirements+v2.0). | `map(string)` | `{}` | no |
| <a name="input_optional_tags"></a> [optional\_tags](#input\_optional\_tags) | Optional Cigna standard tags (reference https://confluence.sys.cigna.com/display/CLOUD/Cloud+Tagging+Requirements+v2.0). | `map(string)` | `{}` | no |
| <a name="input_required_data_tags"></a> [required\_data\_tags](#input\_required\_data\_tags) | Required tags for data at rest as defined by the CCOE Cloud Tagging Requirements | <pre>object({<br>    BusinessEntity         = string<br>    ComplianceDataCategory = string<br>    DataClassification     = string<br>    DataSubjectArea        = string<br>    LineOfBusiness         = string<br>  })</pre> | n/a | yes |
| <a name="input_required_tags"></a> [required\_tags](#input\_required\_tags) | Required common resource tags as defined by the CCOE Cloud Tagging Requirements | <pre>object({<br>    AssetOwner       = string<br>    CostCenter       = string<br>    SecurityReviewID = string<br>    ServiceNowAS     = string<br>    ServiceNowBA     = string<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | n/a |
| <a name="output_s3_bucket_bucket_domain_name"></a> [s3\_bucket\_bucket\_domain\_name](#output\_s3\_bucket\_bucket\_domain\_name) | The bucket domain name. Will be of format bucketname.s3.amazonaws.com. |
| <a name="output_s3_bucket_bucket_regional_domain_name"></a> [s3\_bucket\_bucket\_regional\_domain\_name](#output\_s3\_bucket\_bucket\_regional\_domain\_name) | The bucket region-specific domain name. |
| <a name="output_s3_bucket_id"></a> [s3\_bucket\_id](#output\_s3\_bucket\_id) | n/a |

# Lifecycle Configuration

It is important to make sure lifecycle attributes are configured correctly based on your known data usage. Lifecycle
policies are configured by default, and they should only be turned off if an advanced custom lifecycle configuration is required. With the default configuration, current
versions of files are transitioned to s3 intelligent tiering after 90 days. This is really important because
intelligent tiering can provide a large cost savings, but is billed 30 days at a time. This means that if data is
transitioned to intelligent tiering and then deleted a day later, your account will receive a prorated bill for 29 days
of data usage. Thought should be put into the lifecycle of your data. How often is the data reloaded? How often is the
data accessed? What's a reasonable timeframe to move to intelligent tiering to save the most money? It's also important
to consider whether data should be expired. If files are updated frequently and versioning is enabled, it is very
important to expire non-current versions. The amount of storage can pile up quickly leading to hefty S3 cost. Both
non-current version expiration and non-current version transition timelines are configurable, so pay close attention
to these values and adjust as needed.

```hcl-terraform
resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket_lifecycle_this" {
  bucket = aws_s3_bucket.this.id
  rule {

    abort_incomplete_multipart_upload {
      days_after_initiation = var.lc_abort_incomplete_upload_days
    }
    status                                 = "Enabled"
    id                                     = var.lc_rule_id
    filter {
      prefix = var.lc_prefix
    }

    dynamic "expiration" {
      for_each = [for enabled in local.expire_non_current_versions_is_enabled : enabled if enabled == true]

      content {
        expired_object_delete_marker = var.lc_remove_expired_deletion_markers
      }
    }

    dynamic "noncurrent_version_expiration" {
      for_each = [for enabled in local.expire_non_current_versions_is_enabled : enabled if enabled == true]

      content {
        noncurrent_days = var.lc_non_current_expiration_days
      }
    }

    transition {
      days          = var.lc_transition_1_days
      storage_class = var.lc_transition_1_storage_class
    }

    transition {
      days          = var.lc_transition_2_days
      storage_class = var.lc_transition_2_storage_class
    }
  }

  dynamic "rule" {
    for_each = [for enabled in local.expire_current_versions_is_enabled : enabled if enabled == true]

    content {
      id      = "${var.lc_rule_id}-expiration"
      filter {
        prefix = var.lc_prefix
      }
      status  = "Enabled"
      expiration {
        days = var.lc_current_expiration_days
      }
    }
  }
}
```


## Building and Deploying Locally

Building in this case is initializing the terraform project and caching the results. This step will only have to happen
once across many builds unless any of the inputs change. The infrastructure is built and deployed using the **please**
build tool, which can be run be executing `plz <command> <target>` or by using the built-in wrapper
`./pleasew <command> <target>`. The **--show_all_output** flag indicates to the **please** build tool that it should
ignore its own output formatting and just show the standard out messages.

### Required Environment Variables

| Var Name          | Var Value                            | Reason                                                                                                      |
|-------------------|--------------------------------------|-------------------------------------------------------------------------------------------------------------|
| AWS_FED_PASSWORD  | your aws console password            | used by aws-fed to login to the environment (requires id has admin access to provision, read only for plan) |
| AWS_FED_USERNAME  | your aws User Name                   | used by aws-fed to login to the environment (requires id has admin access to provision, read only for plan) |


### Local-only configuration

Create file **env.list** that sources the required env vars. This file is already added to the **.gitignore** file
Create file **.plzconfig.local** that changes please configuration for the local environment. This file is already
added to the **.gitignore** file. For the `core-ingestion` project to build a local backend configuration and a
local vars file in `env-config` are also required. Please see the associated README for that project for more detailed
information.

The contents of the **.plzconfig.local** file should look like the following but relevant to your local setup:

```ini
[buildconfig]
app-instance = my-feature
```

It is highly recommended that all builds are done via the Jenkins Agent Docker container that is setup for this build.
It will ensure that builds are executed the same across developer machines and setups, and that builds will execute
the same locally vs on the Jenkins server. If you try to call `please` directly from the command-line you are on your
own to figure out why it does not work properly :).

The please build terraform container: https://quay.sys.cigna.com/repository/imdevops/jenkins-generic-agent

**Example**
```bash
$ docker run -it --rm --entrypoint="" --name terraform_plz -t --env-file env.list -w /opt/devops/jenkins/workspace/cds -v ${PWD}:/opt/devops/jenkins/workspace/cds:rw,z quay.sys.cigna.com/imdevops/jenkins-generic-agent:0.0.24 /bin/bash`
# Cleans out Build Cache does not need to be run everytime
jenkins@c737a1845933:/opt/devops/jenkins/workspace/cds$ plz clean
# Federate
jenkins@c737a1845933:/opt/devops/jenkins/workspace/cds$ plz fed dev
# Run and Test Everything for Module
jenkins@c737a1845933:/opt/devops/jenkins/workspace/cds$ plz test --show_all_output -vvv
```



## CICD Documention

For additional info on the build process and pipeline

Road to Production: https://confluence.sys.cigna.com/display/cloudeng/Roadmap+to+AWS+Production#RoadmaptoAWSProduction-AutoSetup   
Build Tool: https://confluence.sys.cigna.com/display/cloudeng/Cloud+Build+Tool  
Jenkins: https://confluence.sys.cigna.com/display/cloudeng/Jenkins+Cloud+Architecture

## Local Testing
```bash
# If the test complains it cannot find the example file, the directory reference in the test will need to be changed to ../examples instead of examples
cd test
go test -v <test_name>_test.go -timeout 30m
```
