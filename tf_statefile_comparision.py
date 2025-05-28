"""
Terraform State File Comparator
Compares the latest and previous versions of Terraform state files stored in S3
"""

import json
import boto3
import argparse
import sys
from datetime import datetime
from typing import Dict, List
from tabulate import tabulate


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
                    if '=' in line and not line.startswith('#'):
                        key, value = line.split('=', 1)
                        self.backend_config[key.strip()] = value.strip().strip('"\'')
            
            if not all(k in self.backend_config for k in ['bucket', 'key', 'region']):
                print("Missing required configuration keys")
                return False
            return True
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
            return json.loads(response['Body'].read().decode('utf-8'))
        except Exception as e:
            print(f"Download error: {e}")
            return {}

    def extract_resources(self, state_data: Dict) -> Dict[str, Dict]:
        """Extract all resources from state."""
        resources = {}
        for resource in state_data.get('resources', []):
            base_key = f"{resource.get('type', 'unknown')}.{resource.get('name', 'unknown')}"
            
            for i, instance in enumerate(resource.get('instances', [])):
                key = base_key
                if len(resource['instances']) > 1:
                    if 'index_key' in instance:
                        key += f'["{instance["index_key"]}"]'
                    else:
                        key += f'[{i}]'
                
                resources[key] = {
                    'type': resource.get('type', 'unknown'),
                    'name': resource.get('name', 'unknown'),
                    'attributes': instance.get('attributes', {})
                }
        return resources

    def get_key_attributes(self, attrs: Dict) -> str:
        """Get key identifying attributes."""
        priority = ['id', 'arn', 'name', 'bucket', 'function_name', 'instance_id']
        key_attrs = []
        
        for attr in priority:
            if attr in attrs and attrs[attr]:
                key_attrs.append(f"{attr}={str(attrs[attr])[:30]}")
                if len(key_attrs) >= 2:
                    break
        
        if not key_attrs:
            for k, v in list(attrs.items())[:2]:
                if v and k not in ['tags', 'tags_all']:
                    key_attrs.append(f"{k}={str(v)[:30]}")
        
        return "; ".join(key_attrs) or "N/A"

    def find_changes(self, current: Dict, previous: Dict) -> List[str]:
        """Find attribute changes."""
        changes = []
        for k, v in current.items():
            if k not in previous:
                changes.append(f"+{k}")
            elif v != previous[k]:
                changes.append(f"~{k}")
        
        for k in previous:
            if k not in current:
                changes.append(f"-{k}")
        
        return changes

    def compare_resources(self, current: Dict, previous: Dict):
        """Compare resources and generate report."""
        # Created
        for key in set(current.keys()) - set(previous.keys()):
            r = current[key]
            self.report_data.append({
                'Action': 'CREATED', 'Type': r['type'], 'Name': r['name'],
                'Key Attributes': self.get_key_attributes(r['attributes']),
                'Details': f"New {r['type']} created"
            })
        
        # Destroyed  
        for key in set(previous.keys()) - set(current.keys()):
            r = previous[key]
            self.report_data.append({
                'Action': 'DESTROYED', 'Type': r['type'], 'Name': r['name'],
                'Key Attributes': self.get_key_attributes(r['attributes']),
                'Details': f"{r['type']} removed"
            })
        
        # Updated
        for key in set(current.keys()) & set(previous.keys()):
            changes = self.find_changes(current[key]['attributes'], previous[key]['attributes'])
            if changes:
                r = current[key]
                details = f"Modified: {', '.join(changes[:3])}"
                if len(changes) > 3:
                    details += f" and {len(changes) - 3} more"
                
                self.report_data.append({
                    'Action': 'UPDATED', 'Type': r['type'], 'Name': r['name'],
                    'Key Attributes': self.get_key_attributes(r['attributes']),
                    'Details': details
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
        table_data = [[item['Action'], item['Type'], item['Name'], 
                      item['Key Attributes'][:40], item['Details'][:50]] 
                     for item in self.report_data]
        
        report.append(tabulate(table_data, 
                              headers=['Action', 'Type', 'Name', 'Key Attributes', 'Details'],
                              tablefmt='grid'))
        
        return "\n".join(report)

    def run(self):
        """Run comparison."""
        if not (self.parse_backend_config() and self.initialize_s3_client()):
            sys.exit(1)
        
        versions = self.get_state_versions()
        if len(versions) < 2:
            print(f"Need 2+ versions, found: {len(versions)}")
            sys.exit(1)
        
        current = self.download_state()
        previous = self.download_state(versions[1]['VersionId'])
        
        if not (current and previous):
            print("Failed to download states")
            sys.exit(1)
        
        self.compare_resources(self.extract_resources(current), 
                              self.extract_resources(previous))
        
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
