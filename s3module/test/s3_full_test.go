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

func TestS3FullConfiguration(t *testing.T) {
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
		TerraformDir: "../examples/full-configuration",

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

	assert.Contains(t, planOut, "pvs|WARN|s3-default-app|cigna-us-devops-pipeline-dev|s3-default-example-bucket-500 errors threshold met")
	assert.Contains(t, planOut, "AsaqId")
	assert.Contains(t, planOut, "kms_master_key_id = (known after apply)")
	assert.Contains(t, planOut, "Plan: 6 to add, 0 to change, 0 to destroy.")
}
