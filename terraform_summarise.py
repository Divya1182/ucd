#!/usr/bin/env python3
"""
Terraform Execution Script
This script runs terraform init, plan, and summarizes the plan
Usage: python run_terraform.py <env_name>
"""

import os
import sys
import subprocess
import argparse

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

def pipe_commands(cmd1, cmd2, description):
    """Run two commands with pipe between them"""
    print(f"\n=== {description} ===")
    print(f"Running: {' '.join(cmd1)} | {' '.join(cmd2)}")
    
    try:
        process1 = subprocess.Popen(cmd1, stdout=subprocess.PIPE, text=True)
        process2 = subprocess.Popen(cmd2, stdin=process1.stdout, text=True)
        
        # Close stdout of process1 to allow process1 to receive SIGPIPE if process2 exits
        process1.stdout.close()
        
        # Wait for completion
        result = process2.wait()
        if result != 0:
            print(f"ERROR: Command failed with exit code {result}")
            return False
        return True
    except Exception as e:
        print(f"ERROR: Failed to execute commands: {e}")
        return False

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="Run Terraform commands with environment configuration")
    parser.add_argument("environment", help="Environment name (e.g., dev, test, prod)")
    args = parser.parse_args()
    
    environment = args.environment
    
    # Set paths based on environment
    backend_config = os.path.join("envs", environment, "backend.config")
    tfvars_file = os.path.join("envs", environment, f"{environment}.tfvars")
    plan_file = f"terraform_{environment}.plan"
    
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
    
    # Run terraform init with backend config
    if not run_command(
        ["terraform", "init", f"-backend-config={backend_config}"],
        "Terraform Init"
    ):
        return 1
    
    # Run terraform plan with var file and save to plan file
    if not run_command(
        ["terraform", "plan", f"-var-file={tfvars_file}", f"-out={plan_file}"],
        "Terraform Plan"
    ):
        return 1
    
    # Run terragrunt show and tf-summarize
    if not pipe_commands(
        ["terragrunt", "show", "-json", plan_file],
        ["tf-summarize"],
        "Plan Summary"
    ):
        return 1
    
    print(f"\nTerraform operations completed successfully for environment: {environment}")
    return 0

if __name__ == "__main__":
    sys.exit(main())