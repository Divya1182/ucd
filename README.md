# DEV AWS (feature/greeting)
branch is based on work performed by Pin Koh which can be found on confluence at 
[API Gateway AWS Lambda Integration](https://confluence.sys.cigna.com/pages/viewpage.action?spaceKey=AUT&title=API+Gateway+AWS+Lambda+Integration)
and the [GIT REPOSITORY](https://git.express-scripts.com/ExpressScripts/greetings-lambda-nodejs)

## Notes
* main.zip was built externally and added to this feature branch, once familiar with deployment hoping to get rid of it*

## External Docs
* AWS Documentation for the [Lambda Proxy](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-lambda.html) referenced in core engineering docs
* [API to Lambda to S3](https://aws.amazon.com/blogs/compute/patterns-for-building-an-api-to-upload-files-to-amazon-s3/)
* [Lambda max payload size is 6MB](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html)

## Terraform Commands
```
terraform init -backend-config=envs/dev/backend.config
terraform plan -var-file=./envs/dev/dev.tfvars
terraform apply -var-file=./envs/dev/dev.tfvars
terraform destroy -var-file=./envs/dev/dev.tfvars
```

##
greetings uri: ```/evernorth/v1/intents/awstest/greetings```

## EDITS

*removed envs besides dev and setup for our account*

### main.tf
* commented out ```data "archive_file" "deployment_zip"``` block
* removed ```depends_on``` in ```custom_lambda```

### envs/dev/tf.vars
* modified ```lambda_deployment_zip_path``` to point to main.zip in root of feature

# ----------
[this git repo](https://git.express-scripts.com/ExpressScripts/aws-terraform-hs-bef-intentapi) 

