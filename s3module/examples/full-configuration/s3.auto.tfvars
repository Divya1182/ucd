kms_accounts           = ["arn:aws:iam::535306282211:root"]
kms_key_administrators = ["arn:aws:iam::535306282211:role/ServiceCatalogTestManual"]
kms_key_users          = ["arn:aws:iam::535306282211:role/ServiceCatalogTestManual"]
s3_default_key_users   = ["arn:aws:iam::643101592424:user/bdrserviceaccount", "arn:aws:iam::643101592424:role/S3INFRASTRUCTURESETUP"]
s3_default_resources   = ["arn:aws:s3:::s3-default-test.dev-cignasplithorizon", "arn:aws:s3:::s3-default-test.dev-cignasplithorizon/*"]
s3_replicated_bucket_default_resources   = ["arn:aws:s3:::s3-default-test.dev-cignasplithorizon-copy", "arn:aws:s3:::s3-default-test.dev-cignasplithorizon-copy/*"]
s3_default_users       = ["arn:aws:iam::643101592424:role/S3INFRASTRUCTURESETUP"]
