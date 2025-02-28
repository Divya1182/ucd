package test

import (
	"testing"
	"fmt"
	"os"
	"log"

	"github.com/stretchr/testify/assert"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestS3DefaultConfiguration(t *testing.T) {
	fmt.Println("Entered test function.")
	t.Parallel()

	targetRegions := []string{"us-east-1"}

	awsRegion := aws.GetRandomStableRegion(t, targetRegions, nil)
	dir, err := os.Getwd()
    if err != nil {
    	log.Fatal(err)
    }
    fmt.Println(dir)

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../examples/default-configuration",

		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"s3.auto.tfvars"},

		// Disable colors in Terraform commands so its easier to parse stdout/stderr
		NoColor: true,

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}
	fmt.Println("Attempting to Run Inint and Plan")
	planOut := terraform.InitAndPlan(t, terraformOptions)

	assert.Contains(t, planOut, "module.s3.aws_cloudwatch_metric_alarm.s3_alarm_4xx[0] will be created")
	assert.Contains(t, planOut, "module.s3.aws_cloudwatch_metric_alarm.s3_alarm_5xx will be created")
	assert.Contains(t, planOut, "module.s3.aws_s3_bucket.this will be created")
	assert.Contains(t, planOut, "module.s3.aws_s3_bucket_metric.s3_bucket_metric will be created")
	assert.Contains(t, planOut, "module.s3.aws_s3_bucket_policy.s3_bucket_policy will be created")
	assert.Contains(t, planOut, "kms_master_key_id = (known after apply)")
	assert.Contains(t, planOut, "Plan: 7 to add, 0 to change, 0 to destroy.")
}
