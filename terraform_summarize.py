#!/usr/bin/env python3
"""
Terraform Execution Script
This script runs terraform init, plan, and summarizes the plan
It also saves the output to a timestamped file and uploads it to S3
Usage: python terraform_summarize.py <env_name>
"""

import os
import sys
import subprocess
import argparse
import datetime
import boto3
from botocore.exceptions import ClientError
import io

S3_BUCKET_NAME = "bef-report-364685145795"

def get_timestamp():
    """Get current timestamp in format YYYYMMDD-HHMMSS"""
    return datetime.datetime.now().strftime("%Y%m%d-%H%M%S")

class OutputCapture:
    """Capture terminal output and also write to file"""
    def __init__(self, output_file):
        self.terminal = sys.stdout
        self.output_file = output_file
        self.buffer = io.StringIO()
    
    def write(self, message):
        self.terminal.write(message)
        self.output_file.write(message)
        self.buffer.write(message)
        
    def flush(self):
        self.terminal.flush()
        self.output_file.flush()
    
    def get_content(self):
        return self.buffer.getvalue()

def upload_to_s3(file_path, environment, s3_client=None):
    """Upload the specified file to S3"""
    if s3_client is None:
        try:
            s3_client = boto3.client('s3')
        except Exception as e:
            print(f"ERROR: Failed to create S3 client: {e}")
            return False
    
    try:
        # S3 object key - path in the bucket
        object_key = f"envs-report/{environment}/{os.path.basename(file_path)}"
        
        print(f"\n=== Uploading report to S3 ===")
        print(f"Bucket: {S3_BUCKET_NAME}")
        print(f"Path: {object_key}")
        
        s3_client.upload_file(file_path, S3_BUCKET_NAME, object_key)
        print(f"Successfully uploaded report to s3://{S3_BUCKET_NAME}/{object_key}")
        return True
    except ClientError as e:
        print(f"ERROR: Failed to upload to S3: {e}")
        return False
    except Exception as e:
        print(f"ERROR: Unexpected error uploading to S3: {e}")
        return False

def run_command(command, description, output_capture):
    """Execute a command and handle errors"""
    print(f"\n=== {description} ===", file=output_capture)
    print(f"Running: {' '.join(command)}", file=output_capture)
    
    try:
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )
        
        # Stream output to both console and file
        for line in process.stdout:
            print(line.rstrip(), file=output_capture)
        
        process.wait()
        
        if process.returncode != 0:
            print(f"ERROR: {description} failed with exit code {process.returncode}", 
                  file=output_capture)
            return False
        return True
    except Exception as e:
        print(f"ERROR: Failed to execute command: {e}", file=output_capture)
        return False

def pipe_commands(cmd1, cmd2, description, output_capture):
    """Run two commands with pipe between them"""
    print(f"\n=== {description} ===", file=output_capture)
    print(f"Running: {' '.join(cmd1)} | {' '.join(cmd2)}", file=output_capture)
    
    try:
        process1 = subprocess.Popen(cmd1, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        process2 = subprocess.Popen(
            cmd2, 
            stdin=process1.stdout, 
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )
        
        # Close stdout of process1
        process1.stdout.close()
        
        # Stream output to both console and file
        for line in process2.stdout:
            print(line.rstrip(), file=output_capture)
        
        # Wait for completion
        process2.wait()
        
        # Check stderr from first process if second process succeeded
        if process2.returncode == 0:
            stderr1 = process1.stderr.read()
            if stderr1:
                print(f"WARNING: Stderr from {cmd1[0]}:", file=output_capture)
                print(stderr1.rstrip(), file=output_capture)
        
        if process2.returncode != 0:
            print(f"ERROR: Command failed with exit code {process2.returncode}", 
                  file=output_capture)
            # Check stderr from failed command
            stderr1 = process1.stderr.read()
            if stderr1:
                print(f"ERROR details from {cmd1[0]}:", file=output_capture)
                print(stderr1.rstrip(), file=output_capture)
            return False
        return True
    except Exception as e:
        print(f"ERROR: Failed to execute commands: {e}", file=output_capture)
        return False

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
    
    # Create output file with timestamp
    report_filename = f"terraform_{environment}_report_{timestamp}.log"
    
    # Check if required files exist
    if not os.path.isfile(backend_config):
        print(f"ERROR: Backend config file not found: {backend_config}")
        return 1
        
    if not os.path.isfile(tfvars_file):
        print(f"ERROR: Terraform vars file not found: {tfvars_file}")
        return 1
    
    try:
        # Initialize S3 client early to check credentials
        s3_client = boto3.client('s3')
    except Exception as e:
        print(f"WARNING: Failed to initialize S3 client: {e}")
        print("The script will continue, but uploading to S3 will be skipped.")
        s3_client = None
    
    # Open output file and redirect stdout
    with open(report_filename, 'w') as report_file:
        output_capture = OutputCapture(report_file)
        old_stdout = sys.stdout
        sys.stdout = output_capture
        
        try:
            print(f"Terraform Report - Environment: {environment} - Date: {timestamp}")
            print(f"Backend config: {backend_config}")
            print(f"Variables file: {tfvars_file}")
            print(f"Plan file: {plan_file}")
            
            # Run terraform init with backend config
            success = run_command(
                ["terraform", "init", f"-backend-config={backend_config}"],
                "Terraform Init",
                output_capture
            )
            if not success:
                return 1
            
            # Run terraform plan with var file and save to plan file
            success = run_command(
                ["terraform", "plan", f"-var-file={tfvars_file}", f"-out={plan_file}"],
                "Terraform Plan",
                output_capture
            )
            if not success:
                return 1
            
            # Run terragrunt show and tf-summarize
            success = pipe_commands(
                ["terraform", "show", "-json", plan_file],
                ["tf-summarize"],
                "Plan Summary",
                output_capture
            )
            if not success:
                return 1
            
            print(f"\nTerraform operations completed successfully for environment: {environment}")
            
            # Restore original stdout before completing
            sys.stdout = old_stdout
            
            # Upload report to S3
            if s3_client:
                upload_success = upload_to_s3(report_filename, environment, s3_client)
                if not upload_success:
                    print("WARNING: Failed to upload report to S3, but Terraform operations were successful.")
            
            return 0

        except Exception as e:
            print(f"ERROR: Unexpected error occurred: {e}", file=output_capture)
            return 1
        finally:
            # Ensure stdout is restored
            sys.stdout = old_stdout

if __name__ == "__main__":
    # Make sure boto3 is installed
    try:
        import boto3
    except ImportError:
        print("WARNING: boto3 package is not installed. S3 upload will not work.")
        print("Install it with: pip install boto3")
    
    sys.exit(main())