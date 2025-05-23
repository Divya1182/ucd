#!/usr/bin/env python3
"""
Terraform Execution Script
This script:
1. Runs terraform init and plan commands
2. Runs terragrunt show -json | tf-summarize
3. Captures only the tf-summarize output and uploads to S3
Usage: python terraform_summarize.py <env_name>
"""

import os
import sys
import subprocess
import argparse
import datetime
import tempfile
import boto3
from botocore.exceptions import ClientError
import re

# S3 bucket details
# S3_BUCKET_NAME will be constructed dynamically from account ID

def get_timestamp():
    """Get current timestamp in format YYYYMMDD-HHMMSS"""
    return datetime.datetime.now().strftime("%Y%m%d-%H%M%S")

def read_account_id_from_tfvars(tfvars_file):
    """Read tf-account-id from the tfvars file"""
    try:
        with open(tfvars_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line.lower().startswith('tf-account-id') and '=' in line:
                    # Split on = and get the value part
                    value = line.split('=', 1)[1].strip()
                    # Remove inline comments
                    value = value.split('#')[0].strip()
                    # Remove quotes manually
                    if value.startswith('"') and value.endswith('"'):
                        value = value[1:-1]
                    elif value.startswith("'") and value.endswith("'"):
                        value = value[1:-1]
                    
                    if value:
                        return value
        
        print("ERROR: tf-account-id not found in tfvars file")
        return None
        
    except Exception as e:
        print(f"ERROR: Failed to read account ID from tfvars file: {e}")
        return None

def upload_to_s3(file_content, file_name, environment, bucket_name):
    """Upload the specified content to S3"""
    try:
        s3_client = boto3.client('s3')
        
        # S3 object key - path in the bucket
        object_key = f"envs-report/{environment}/{file_name}"
        
        print(f"\n=== Uploading tf-summarize output to S3 ===")
        print(f"Bucket: {bucket_name}")
        print(f"Path: {object_key}")
        
        s3_client.put_object(
            Bucket=bucket_name,
            Key=object_key,
            Body=file_content
        )
        print(f"Successfully uploaded to s3://{bucket_name}/{object_key}")
        return True
    except ClientError as e:
        print(f"ERROR: Failed to upload to S3: {e}")
        return False
    except Exception as e:
        print(f"ERROR: Unexpected error uploading to S3: {e}")
        return False

def run_command(command, description):
    """Execute a command and handle errors"""
    print(f"\n=== {description} ===")
    print(f"Running: {' '.join(command)}")
    
    try:
        result = subprocess.run(command, check=True, text=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"ERROR: {description} failed with exit code {e.returncode}")
        return False
    except Exception as e:
        print(f"ERROR: Failed to execute command: {e}")
        return False

def capture_tf_summarize_output(cmd1, cmd2, description):
    """Run terragrunt show and tf-summarize and capture only tf-summarize output"""
    print(f"\n=== {description} ===")
    print(f"Running: {' '.join(cmd1)} | {' '.join(cmd2)}")
    
    try:
        process1 = subprocess.Popen(cmd1, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        process2 = subprocess.Popen(
            cmd2, 
            stdin=process1.stdout, 
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Close stdout of process1
        process1.stdout.close()
        
        # Capture the output from tf-summarize
        stdout_data, stderr_data = process2.communicate()
        
        # Display the tf-summarize output to console
        print(stdout_data)
        
        if stderr_data:
            print("Errors from tf-summarize:")
            print(stderr_data)
        
        if process2.returncode != 0:
            print(f"ERROR: Command failed with exit code {process2.returncode}")
            return False, None
        
        return True, stdout_data
    except Exception as e:
        print(f"ERROR: Failed to execute commands: {e}")
        return False, None

def capture_terraform_plan_output(plan_file):
    """Capture human-readable terraform plan output"""
    print(f"\n=== Capturing Terraform Plan Details ===")
    command = ["terraform", "show", plan_file]
    print(f"Running: {' '.join(command)}")
    
    try:
        result = subprocess.run(
            command, 
            capture_output=True, 
            text=True, 
            check=True
        )
        
        if result.stdout:
            print("Successfully captured terraform plan output")
            return True, result.stdout
        else:
            print("WARNING: No plan output captured")
            return True, "No plan changes detected"
            
    except subprocess.CalledProcessError as e:
        print(f"ERROR: Failed to capture plan output with exit code {e.returncode}")
        if e.stderr:
            print(f"Error details: {e.stderr}")
        return False, None
    except Exception as e:
        print(f"ERROR: Failed to execute terraform show command: {e}")
        return False, None

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="Run Terraform commands with environment configuration")
    parser.add_argument("environment", help="Environment name (e.g., dev, test, prod)")
    args = parser.parse_args()
    
    environment = args.environment
    timestamp = get_timestamp()
    
    # Set paths based on environment
    backend_config = os.path.join("envs", environment, "backend.config")
    tfvars_file = os.path.join("envs", environment, f"{environment}.tfvars")
    plan_file = f"terraform_{environment}.plan"
    
    # Define report filename with timestamp
    report_filename = f"terraform_{environment}_summary_{timestamp}.txt"
    
    print(f"Starting Terraform operations for environment: {environment}")
    print(f"Backend config: {backend_config}")
    print(f"Variables file: {tfvars_file}")
    print(f"Plan file: {plan_file}")
    
    # Check if required files exist
    if not os.path.isfile(backend_config):
        print(f"ERROR: Backend config file not found: {backend_config}")
        return 1
        
    if not os.path.isfile(tfvars_file):
        print(f"ERROR: Terraform vars file not found: {tfvars_file}")
        return 1
    
    # Read account ID from tfvars file to construct bucket name
    account_id = read_account_id_from_tfvars(tfvars_file)
    if not account_id:
        return 1
    
    if environment =='prod':
        bucket_name = f"cigna-tf-state-{account_id}"
    else:
        bucket_name = f"bef-report-{account_id}"

    print(f"Using S3 bucket: {bucket_name}")
    
    # Run terraform init with backend config
    if not run_command(
        ["terraform", "init", f"-backend-config={backend_config}", "-reconfigure"],
        "Terraform Init"
    ):
        return 1
    
    # Run terraform plan with var file and save to plan file
    if not run_command(
        ["terraform", "plan", f"-var-file={tfvars_file}", f"-out={plan_file}"],
        "Terraform Plan"
    ):
        return 1
    
    # Capture tf-summarize output
    success, tf_summarize_output = capture_tf_summarize_output(
        ["terraform", "show", "-json", plan_file],
        ["tf-summarize"],
        "Plan Summary"
    )
    
    if not success or tf_summarize_output is None:
        return 1
    
    # Capture detailed terraform plan output
    plan_success, plan_details = capture_terraform_plan_output(plan_file)
    
    if not plan_success or plan_details is None:
        print("WARNING: Failed to capture plan details, continuing with summary only")
        plan_details = "Failed to capture detailed plan output"
    
    # Add header to the output file
    header = f"Terraform Summary Report\n"
    header += f"Environment: {environment}\n"
    header += f"Date: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
    header += f"{'=' * 80}\n\n"

    # Add tf-summarize section
    summary_section = f"TERRAFORM PLAN SUMMARY\n"
    summary_section += f"{'=' * 80}\n\n"
    summary_section += tf_summarize_output + "\n\n"

    # Add detailed plan section
    plan_summary = f"DETAILED TERRAFORM PLAN\n"
    plan_summary += f"{'=' * 80}\n\n"
    plan_summary += plan_details + "\n"
    
    # Combine all sections
    full_report_content = header + summary_section + plan_summary
    
    # Save complete report to a local file
    with open(report_filename, 'w') as f:
        f.write(full_report_content)
    
    print(f"\nComplete Terraform report saved to {report_filename}")
    
    # Try to upload to S3
    try:
        upload_success = upload_to_s3(full_report_content, report_filename, environment, bucket_name)
        if not upload_success:
            print("WARNING: Failed to upload summary to S3, but Terraform operations were successful.")
    except ImportError:
        print("WARNING: boto3 package is not installed. S3 upload will not work.")
        print("Install it with: pip install boto3")
    
    print(f"\nTerraform operations completed successfully for environment: {environment}")
    return 0

if __name__ == "__main__":
    # Check if boto3 is installed
    try:
        import boto3
    except ImportError:
        print("WARNING: boto3 package is not installed. S3 upload will not work.")
        print("Install it with: pip install boto3")
    
    sys.exit(main())
