# S3 Module Default Configuration

An example of using the S3 module taking all of the defaults and only providing values for the inputs that are required.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_s3"></a> [s3](#module\_s3) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_kms_key.key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_kms_accounts"></a> [kms\_accounts](#input\_kms\_accounts) | n/a | `list(string)` | n/a | yes |
| <a name="input_kms_key_administrators"></a> [kms\_key\_administrators](#input\_kms\_key\_administrators) | n/a | `list(string)` | n/a | yes |
| <a name="input_kms_key_users"></a> [kms\_key\_users](#input\_kms\_key\_users) | n/a | `list(string)` | n/a | yes |
| <a name="input_s3_default_resources"></a> [s3\_default\_resources](#input\_s3\_default\_resources) | n/a | `list(string)` | n/a | yes |
| <a name="input_s3_default_users"></a> [s3\_default\_users](#input\_s3\_default\_users) | n/a | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_s3_bucket_id"></a> [s3\_bucket\_id](#output\_s3\_bucket\_id) | n/a |