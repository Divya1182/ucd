import json
import boto3
import logging
import os
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sns_client = boto3.client('sns')

SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

def lambda_handler(event, context):
    try:
        cloudtrail_event = event['detail']
        
        event_name = cloudtrail_event.get('eventName', 'Unknown')
        event_time = cloudtrail_event.get('eventTime', datetime.utcnow().isoformat())
        region = cloudtrail_event.get('awsRegion', 'Unknown')
        user_identity = cloudtrail_event.get('userIdentity', {})
        user_name = user_identity.get('userName', user_identity.get('arn', 'Unknown'))
        
        resources = cloudtrail_event.get('resources', [])
        if resources:
            resource = resources[0]
            resource_type = resource.get('resourceType', 'Unknown')
            resource_name = resource.get('resourceName', 'Unknown')
        else:
            request_params = cloudtrail_event.get('requestParameters', {})
            response_elements = cloudtrail_event.get('responseElements', {})
            
            for key in ['name', 'id', 'resourceId', 'resourceName', 'arn']:
                if key in request_params:
                    resource_name = request_params[key]
                    break
                if key in response_elements:
                    resource_name = response_elements[key]
                    break
            
            if isinstance(resource_name, str) and 'arn:aws' in resource_name:
                try:
                    arn_parts = resource_name.split(':')
                    if len(arn_parts) > 2:
                        resource_type = arn_parts[2]  # e.g., 's3', 'dynamodb', 'ec2'
                        if resource_type:
                            resource_type = resource_type.upper()
                except Exception as e:
                    logger.warning(f"Failed to parse ARN for resource type: {str(e)}")
            
        message = (
            f"AWS Resource Deletion Detected\n"
            f"Event Name: {event_name}\n"
            f"Resource Type: {resource_type}\n"
            f"Resource Name: {resource_name}\n"
            f"Region: {region}\n"
            f"Event Time: {event_time}\n"
            f"User: {user_name}"
        )
        
        response = sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=message,
            Subject=f"AWS Resource Deletion: {resource_type} ({resource_name})"
        )
        
        logger.info(f"Published SNS message: {response['MessageId']}")
        return {
            'statusCode': 200,
            'body': json.dumps('Notification sent successfully')
        }
    
    except Exception as e:
        logger.error(f"Error processing event: {str(e)}")
        logger.error(f"Event details: {json.dumps(event, default=str)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error: {str(e)}")
        }