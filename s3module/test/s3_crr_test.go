package test

import (
	"github.com/stretchr/testify/assert"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestS3CRRConfiguration(t *testing.T) {
	t.Parallel()

	targetRegions := []string{"us-east-1","us-west-1"}

	awsRegion := aws.GetRandomStableRegion(t, targetRegions, nil)

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../examples/crr",

		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"s3.auto.tfvars"},

		// Disable colors in Terraform commands so its easier to parse stdout/stderr
		NoColor: true,

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	planOut := terraform.InitAndPlan(t, terraformOptions)

	assert.Contains(t, planOut, "module.s3.aws_cloudwatch_metric_alarm.s3_alarm_4xx[0] will be created")
	assert.Contains(t, planOut, "module.s3.aws_cloudwatch_metric_alarm.s3_alarm_5xx will be created")
	assert.Contains(t, planOut, "module.s3.aws_s3_bucket.replicated_bucket[0] will be created")
	assert.Contains(t, planOut, "module.s3.aws_s3_bucket.this will be created")
	assert.Contains(t, planOut, "replication_configuration {")
	assert.Contains(t, planOut, "module.s3.aws_s3_bucket_metric.s3_bucket_metric will be created")
	assert.Contains(t, planOut, "module.s3.aws_s3_bucket_policy.s3_bucket_policy will be created")
	assert.Contains(t, planOut, "module.s3.aws_s3_bucket_public_access_block.public_access_block will be created")
	assert.Contains(t, planOut, "module.s3.aws_s3_bucket_metric.crr_bucket_metric[0] will be created")
	assert.Contains(t, planOut, "module.s3.aws_s3_bucket_policy.crr_bucket_policy[0] will be created")
	assert.Contains(t, planOut, "module.s3.aws_s3_bucket_public_access_block.crr_public_access_block[0] will be created")
	assert.Contains(t, planOut, "kms_master_key_id = (known after apply)")
	assert.Contains(t, planOut, "Plan: 11 to add, 0 to change, 0 to destroy.")
}
