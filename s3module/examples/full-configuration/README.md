# S3 Module Default Configuration

An example of using the S3 module overriding all the configuration inputs

## Inputs
| Name                                  | Description                                                                                                                                                      | Type    |
|---------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|
| alarm_evaluation_periods              | The number of periods over which data is compared to the specified threshold                                                                                     | string  |
| alarm_period                          | The period in seconds over which the specified statistic is applied                                                                                              | string  |
| alarm_severity_4xx                    | The alarm severity level for 4xx errors                                                                                              | string  |
| alarm_severity_5xx                    | The alarm severity level for 5xx errors                                                                                              | string  |
| alarm_threshold_4xx                   | The number of data points to trigger the alarm for 4xx errors                                                                                                    | string  |
| alarm_threshold_5xx                   | The number of data points to trigger the alarm for 5xx errors                                                                                                    | string  |
| bucket_kms                            | The alias of the KMS key that will be use to apply default bucket level encryption                                                                               | string  |
| bucket_name                           | The name of the s3 bucket that will be created                                                                                                                   | string  |
| bucket_policy                         | A JSON document with the Bucket Policy to be placed on the Bucket                                                                                                | string  |
| required_tags                         | A map of Cigna-specific tags to place on the bucket, based on CIP best practices.                                                | map     |
| required_data_tags                    | A map of data at rest tags to place on the bucket, based on CIP best practices.                                                | map     |
| enable_bucket_versioning              | Flag to enable or disable Versioning on the S3 bucket                                                                                                            | boolean |
| optional_tags                         | Map of any user-defined optional tags to put on the bucket resource                                                                                                 | map     |
| optional_data_tags                    | Map of any user-defined data at rest tags to put on the bucket resource                                                                                                 | map     |
| lc_abort_incomplete_upload_days       | Number of days until failed multipart uploads are deleted                                                                                                        | string  |
| lc_prefix                             | Scope the lifecycle policy to a specific sub directory.  Pass in empty string to scope to bucket                                                                 | string  |
| lc_remove_expired_deletion_markers    | Clean up deletion markers on versioned buckets                                                                                                                   | boolean |
| lc_rule_id                            | Unique name of lifecycle rule                                                                                                                                    | string  |
| lc_transition_1_days                  | Lifecycle policy rule that governs the transition to next storage class based on number of days                                                                  | string  |
| lc_transition_1_storage_class         | Lifecycle policy rule that governs the transition storage class selected based on number of days                                                                 | string  |
| lc_transition_2_days                  | Lifecycle policy rule that governs the transition to next storage class based on number of days. This is used after the first rule is met.                       | string  |
| lc_transition_2_storage_class         | Lifecycle policy rule that governs the transition storage class selected based on number of days. This is used after the first rule is met.                      | string  |
| lc_version_transition_1_days          | Lifecycle policy rule, for older versions, that governs the transition to next storage class based on number of days                                             | string  |
| lc_version_transition_1_storage_class | Lifecycle policy rule, for older versions, that governs the transition storage class selected based on number of days                                            | string  |
| lc_version_transition_2_days          | Lifecycle policy rule, for older versions, that governs the transition to next storage class based on number of days                                             | string  |
| lc_version_transition_2_storage_class | Lifecycle policy rule, for older versions, that governs the transition storage class selected based on number of days. This is used after the first rule is met. | string  |
| module_config                         | Map containing module configuration information. This should contain an attribute 'moduleVersion'                                                                | map     |

## Outpus

| Name         | Description                  | Type    |
|--------------|------------------------------|---------|
| s3_bucket_id | The id of the created bucket | string  | 
