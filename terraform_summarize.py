#!/usr/bin/env python3
"""
Terraform Execution Script
This script:
1. Runs terraform init and plan commands
2. Runs terragrunt show -json | tf-summarize
3. Captures the tf-summarize output and uploads to S3
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

S3_BUCKET_NAME = "bef-report-364685145795"

def get_timestamp():
    """Get current timestamp in format YYYYMMDD-HHMMSS"""
    return datetime.datetime.now().strftime("%Y%m%d-%H%M%S")

def upload_to_s3(file_content, file_name, environment):
    """Upload the specified content to S3"""
    try:
        s3_client = boto3.client('s3')
        
        # S3 object key - path in the bucket
        object_key = f"envs-report/{environment}/{file_name}"
        
        print(f"\n=== Uploading tf-summarize output to S3 ===")
        print(f"Bucket: {S3_BUCKET_NAME}")
        print(f"Path: {object_key}")
        
        s3_client.put_object(
            Bucket=S3_BUCKET_NAME,
            Key=object_key,
            Body=file_content
        )
        print(f"Successfully uploaded to s3://{S3_BUCKET_NAME}/{object_key}")
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
        
        process1.stdout.close()
        
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

def main():
    parser = argparse.ArgumentParser(description="Run Terraform commands with environment configuration")
    parser.add_argument("environment", help="Environment name (e.g., dev, test, prod)")
    args = parser.parse_args()
    
    environment = args.environment
    timestamp = get_timestamp()
    
    backend_config = os.path.join("envs", environment, "backend.config")
    tfvars_file = os.path.join("envs", environment, f"{environment}.tfvars")
    plan_file = f"terraform_{environment}.plan"
    
    report_filename = f"terraform_{environment}_summary_{timestamp}.txt"
    
    print(f"Starting Terraform operations for environment: {environment}")
    print(f"Backend config: {backend_config}")
    print(f"Variables file: {tfvars_file}")
    print(f"Plan file: {plan_file}")
    
    if not os.path.isfile(backend_config):
        print(f"ERROR: Backend config file not found: {backend_config}")
        return 1
        
    if not os.path.isfile(tfvars_file):
        print(f"ERROR: Terraform vars file not found: {tfvars_file}")
        return 1
    
    if not run_command(
        ["terraform", "init", f"-backend-config={backend_config}"],
        "Terraform Init"
    ):
        return 1
    
    if not run_command(
        ["terraform", "plan", f"-var-file={tfvars_file}", f"-out={plan_file}"],
        "Terraform Plan"
    ):
        return 1
    
    success, tf_summarize_output = capture_tf_summarize_output(
        ["terraform", "show", "-json", plan_file],
        ["tf-summarize"],
        "Plan Summary"
    )
    
    if not success or tf_summarize_output is None:
        return 1
    
    header = f"Terraform Summary Report\n"
    header += f"Environment: {environment}\n"
    header += f"Date: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
    header += f"{'=' * 50}\n\n"
    
    full_report_content = header + tf_summarize_output
    
    with open(report_filename, 'w') as f:
        f.write(full_report_content)
    
    print(f"\nTerraform summary saved to {report_filename}")
    
    try:
        upload_success = upload_to_s3(full_report_content, report_filename, environment)
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
