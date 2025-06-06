#!/usr/bin/env python3
"""
Terraform State File Comparator
Compares the latest and previous versions of Terraform state files stored in S3
Generates a detailed report of resource changes in a table format
"""

import json
import boto3
import argparse
import sys
from datetime import datetime
from typing import Dict, List
from tabulate import tabulate
import textwrap


class TerraformStateComparator:
    def __init__(self, environment: str):
        self.environment = environment
        self.backend_config = {}
        self.s3_client = None
        self.report_data = []

    def parse_backend_config(self) -> bool:
        """Parse the backend configuration file."""
        try:
            with open(f"envs/{self.environment}/backend.config", 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#'):
                        key, value = line.split('=', 1)
                        self.backend_config[key.strip()] = value.strip().strip('"\'')
            
            if not all(k in self.backend_config for k in ['bucket', 'key', 'region']):
                print("Missing required configuration keys in backend.config")
                return False
            return True
        except FileNotFoundError:
            print(f"Configuration file envs/{self.environment}/backend.config not found")
            return False
        except Exception as e:
            print(f"Error reading config: {e}")
            return False

    def initialize_s3_client(self) -> bool:
        """Initialize S3 client."""
        try:
            self.s3_client = boto3.client('s3', region_name=self.backend_config['region'])
            self.s3_client.head_bucket(Bucket=self.backend_config['bucket'])
            return True
        except Exception as e:
            print(f"S3 error: {e}")
            return False

    def get_state_versions(self) -> List[Dict]:
        """Get state file versions."""
        try:
            response = self.s3_client.list_object_versions(
                Bucket=self.backend_config['bucket'],
                Prefix=self.backend_config['key']
            )
            versions = [v for v in response.get('Versions', []) 
                       if v['Key'] == self.backend_config['key']]
            return sorted(versions, key=lambda x: x['LastModified'], reverse=True)
        except Exception as e:
            print(f"Error listing versions: {e}")
            return []

    def download_state(self, version_id: str = None) -> Dict:
        """Download state file."""
        try:
            params = {'Bucket': self.backend_config['bucket'], 'Key': self.backend_config['key']}
            if version_id:
                params['VersionId'] = version_id
            
            response = self.s3_client.get_object(**params)
            state_data = json.loads(response['Body'].read().decode('utf-8'))
            if not state_data:
                print("Downloaded state file is empty")
                return {}
            return state_data
        except Exception as e:
            print(f"Download error: {e}")
            return {}

    def extract_resources(self, state_data: Dict) -> Dict[str, Dict]:
        """Extract all resources from state."""
        resources = {}
        if not state_data.get('resources'):
            print("No resources found in state file")
            return resources
        
        for resource in state_data.get('resources', []):
            base_key = f"{resource.get('type', 'unknown')}.{resource.get('name', 'unknown')}"
            module = resource.get('module', '')
            if module:
                base_key = f"{module}.{base_key}"
            
            for i, instance in enumerate(resource.get('instances', [])):
                key = base_key
                if len(resource['instances']) > 1:
                    if 'index_key' in instance:
                        key += f'["{instance["index_key"]}"]'
                    else:
                        key += f'[{i}]'
                
                attributes = instance.get('attributes', {})
                # Use the 'name' attribute from AWS resource attributes, fallback to Terraform name
                resource_name = attributes.get('name', resource.get('name', 'unknown'))
                
                resources[key] = {
                    'type': resource.get('type', 'unknown'),
                    'name': resource_name,
                    'module': module,
                    'address': key,
                    'attributes': attributes,
                    'arn': attributes.get('arn', 'N/A')
                }
        return resources

    def get_key_attributes(self, attrs: Dict) -> str:
        """Get key identifying attributes for CREATED/DESTROYED resources."""
        priority = ['id', 'name', 'bucket', 'function_name', 'instance_id', 'role_name', 'topic_name']
        key_attrs = []
        
        for attr in priority:
            if attr in attrs and attrs[attr]:
                value = str(attrs[attr])
                key_attrs.append(f"{attr}={value}")
                if len(key_attrs) >= 3:
                    break
        
        if not key_attrs:
            for k, v in list(attrs.items())[:3]:
                if v and k not in ['tags', 'tags_all', 'arn']:
                    key_attrs.append(f"{k}={str(v)}")
        
        return "; ".join(key_attrs) or "N/A"

    def get_changes(self, current_attrs: Dict, previous_attrs: Dict) -> str:
        """Get changed attributes for UPDATED resources."""
        changes = []
        for key in set(current_attrs) | set(previous_attrs):
            if key not in previous_attrs:
                changes.append(f"+{key}: {self.format_value(current_attrs[key])}")
            elif key not in current_attrs:
                changes.append(f"-{key}: {self.format_value(previous_attrs[key])}")
            elif current_attrs[key] != previous_attrs[key]:
                old_val = self.format_value(previous_attrs[key])
                new_val = self.format_value(current_attrs[key])
                changes.append(f"~{key}: {old_val} -> {new_val}")
        
        return "; ".join(changes) or "No attribute changes"

    def format_value(self, value) -> str:
        """Format attribute values for display."""
        if isinstance(value, (dict, list)):
            return json.dumps(value, indent=None, sort_keys=True)
        return str(value)

    def wrap_text(self, text: str, width: int) -> str:
        """Wrap text for console display while preserving newlines."""
        if not text:
            return ""
        lines = text.split('; ')
        wrapped_lines = []
        for line in lines:
            wrapped = textwrap.fill(line, width=width, break_long_words=False, replace_whitespace=False)
            wrapped_lines.append(wrapped)
        return '\n'.join(wrapped_lines)

    def compare_resources(self, current: Dict, previous: Dict):
        """Compare resources and generate report."""
        # Created
        for key in set(current.keys()) - set(previous.keys()):
            r = current[key]
            self.report_data.append({
                'Action': 'CREATED',
                'Address': r['address'],
                'Type': r['type'],
                'Name': r['name'],
                'ARN': r['arn'],
                'Changes': self.get_key_attributes(r['attributes'])
            })
        
        # Destroyed
        for key in set(previous.keys()) - set(current.keys()):
            r = previous[key]
            self.report_data.append({
                'Action': 'DESTROYED',
                'Address': r['address'],
                'Type': r['type'],
                'Name': r['name'],
                'ARN': r['arn'],
                'Changes': self.get_key_attributes(r['attributes'])
            })
        
        # Updated
        for key in set(current.keys()) & set(previous.keys()):
            if current[key]['attributes'] != previous[key]['attributes']:
                r = current[key]
                self.report_data.append({
                    'Action': 'UPDATED',
                    'Address': r['address'],
                    'Type': r['type'],
                    'Name': r['name'],
                    'ARN': r['arn'],
                    'Changes': self.get_changes(r['attributes'], previous[key]['attributes'])
                })

    def generate_report(self) -> str:
        """Generate report."""
        if not self.report_data:
            return "No changes detected."
        
        # Sort by action
        order = {'CREATED': 1, 'UPDATED': 2, 'DESTROYED': 3}
        self.report_data.sort(key=lambda x: order.get(x['Action'], 4))
        
        # Summary
        summary = {}
        for item in self.report_data:
            summary[item['Action']] = summary.get(item['Action'], 0) + 1
        
        report = [
            "=" * 80,
            f"TERRAFORM STATE COMPARISON - {self.environment.upper()}",
            f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "=" * 80,
            "",
            "SUMMARY:",
            f"Total Changes: {len(self.report_data)}"
        ]
        
        for action, count in summary.items():
            report.append(f"{action}: {count}")
        
        report.extend(["", "DETAILED CHANGES:"])
        
        # Table
        table_data = [
            [
                item['Action'],
                self.wrap_text(item['Address'], 50),
                item['Type'],
                self.wrap_text(item['Name'], 30),
                self.wrap_text(item['ARN'], 60),
                self.wrap_text(item['Changes'], 80)
            ] 
            for item in self.report_data
        ]
        
        report.append(tabulate(
            table_data,
            headers=['Action', 'Address', 'Type', 'Name', 'ARN', 'Changes'],
            tablefmt='pipe',
            maxcolwidths=[None, 50, None, 30, 60, 80]
        ))
        
        return "\n".join(report)

    def run(self):
        """Run comparison."""
        if not (self.parse_backend_config() and self.initialize_s3_client()):
            sys.exit(1)
        
        versions = self.get_state_versions()
        if len(versions) < 2:
            print(f"Need at least 2 versions, found: {len(versions)}")
            sys.exit(1)
        
        current = self.download_state()
        previous = self.download_state(versions[1]['VersionId'])
        
        if not (current and previous):
            print("Failed to download state files")
            sys.exit(1)
        
        current_resources = self.extract_resources(current)
        previous_resources = self.extract_resources(previous)
        
        if not (current_resources or previous_resources):
            print("No resources to compare")
            sys.exit(1)
        
        self.compare_resources(current_resources, previous_resources)
        
        report = self.generate_report()
        print(report)
        
        # Save to file
        filename = f"tf_comparison_{self.environment}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        with open(filename, 'w') as f:
            f.write(report)
        print(f"\nReport saved: {filename}")


def main():
    parser = argparse.ArgumentParser(description='Compare Terraform state files')
    parser.add_argument('environment', help='Environment (dev, qa, prod)')
    
    comparator = TerraformStateComparator(parser.parse_args().environment)
    comparator.run()


if __name__ == "__main__":
    main()
