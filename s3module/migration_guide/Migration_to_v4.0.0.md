# Migration Guide for Upgrading AWS provider version to 4.0.0

This document provides steps to safely migrate your S3 bucket resources which are currently running on AWS provider version 3.x to version 4.0.0.

Please use the reference guide to review the changes in [Version 4.0.0](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-4-upgrade).

## Upgrade your provider to 4.0

Upgrade the section in your code that specifies the version for AWS provider.

Old -
```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.x"
    }
  }
}
```
New -
```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
```

## Update your git source to tag to 6.0.0

Old -
```terraform
...
source = "git::https://github.sys.cigna.com/cigna/terraform-aws-s3.git?ref=5.0.1"
...
```

New -
```terraform
...
source = "git::https://github.sys.cigna.com/cigna/terraform-aws-s3.git?ref=6.0.0"
...
```

## terraform init

Execute the terraform init command which will update your aws provider. If required execute it with ```-upgrade``` flag -
```terraform
terraform init -upgrade
```

## Imports for your S3 bucket
You would need to import some resources to make your existing buckets created with version 3.x to be compatible with version 4.0.0.

* Execute the following commands to update your state file -

**NOTE - Use double quotation marks in the import statements as shown below**

```shell
terraform import "module.s3.aws_s3_bucket_acl.bucket_acl_this" ${BUCKET_NAME}
terraform import "module.s3.aws_s3_bucket_lifecycle_configuration.s3_bucket_lifecycle_this" ${BUCKET_NAME}
terraform import "module.s3.aws_s3_bucket_server_side_encryption_configuration.server_side_encryption_configuration_this" ${BUCKET_NAME}
terraform import "module.s3.aws_s3_bucket_versioning.s3_bucket_versioning_this" ${BUCKET_NAME}
```
### If you have cross region replication enabled, execute the following imports
```shell
terraform import "module.s3.aws_s3_bucket_replication_configuration.replication_configuration_this[0]" ${BUCKET_NAME}
terraform import "module.s3.aws_s3_bucket_lifecycle_configuration.s3_bucket_lifecycle_replicated_bucket[0]" ${BUCKET_NAME}-copy
terraform import "module.s3.aws_s3_bucket_acl.bucket_acl_replicated_bucket[0]" ${BUCKET_NAME}-copy
terraform import "module.s3.aws_s3_bucket_server_side_encryption_configuration.server_side_encryption_configuration_replicated_bucket[0]" ${BUCKET_NAME}-copy
terraform import "module.s3.aws_s3_bucket_versioning.s3_bucket_versioning_replicated_bucket[0]" ${BUCKET_NAME}-copy
```
where ```${BUCKET_NAME}``` is the name of your S3 bucket.

<span style="color:red;">**In case of any questions/doubts, Contact CloudCOE team in [Terraform](https://mm.sys.cigna.com/cloud-ops-guild/channels/terraform) mattermost channel**</span>
