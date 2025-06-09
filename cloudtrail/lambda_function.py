import json
import boto3
import logging
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sns_client = boto3.client('sns')
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

def get_resource_name(cloudtrail_event):
    # Try resources array first (most reliable when present)
    resources = cloudtrail_event.get('resources', [])
    if resources:
        return resources[0].get('resourceName', 'Unknown')
    
    # Check request parameters for any resource identifier
    request_params = cloudtrail_event.get('requestParameters', {})
    
    # Try common resource identifier field names
    common_fields = [
        'name', 'Name', 'id', 'Id', 'identifier', 'Identifier',
        'arn', 'Arn', 'resourceId', 'ResourceId', 'resourceName', 'ResourceName'
    ]
    
    for field in common_fields:
        if field in request_params:
            value = request_params[field]
            if isinstance(value, list) and value:
                return ', '.join(str(v) for v in value)
            elif value:
                return str(value)
    
    # If no common fields found, try to find any field that looks like a resource identifier
    for key, value in request_params.items():
        if value and isinstance(value, str):
            # Look for fields that end with common resource identifier patterns
            if any(key.lower().endswith(suffix) for suffix in ['name', 'id', 'arn', 'identifier']):
                return str(value)
    
    return 'Unknown'

def get_user_name(user_identity):
    user_type = user_identity.get('type', '')
    
    if user_type == 'AssumedRole':
        # Get actual user from principalId (after colon)
        principal_id = user_identity.get('principalId', '')
        if ':' in principal_id:
            return principal_id.split(':')[-1]
        # Fallback to role name
        session_context = user_identity.get('sessionContext', {})
        session_issuer = session_context.get('sessionIssuer', {})
        return session_issuer.get('userName', 'Unknown')
    
    return user_identity.get('userName', user_identity.get('arn', 'Unknown'))

def lambda_handler(event, context):
    try:
        cloudtrail_event = event['detail']
        print(f"cloud trail event details: {cloudtrail_event}")
        event_name = cloudtrail_event.get('eventName', 'Unknown')
        
        # Extract essential details
        resource_name = get_resource_name(cloudtrail_event)
        deletion_time = cloudtrail_event.get('eventTime', 'Unknown')
        region = cloudtrail_event.get('awsRegion', 'Unknown')
        user_identity = cloudtrail_event.get('userIdentity', {})
        user_name = get_user_name(user_identity)
        service = cloudtrail_event.get('eventSource', '').replace('.amazonaws.com', '')
        
        # Simple message with essential details only
        message = f"""AWS Resource Deletion Alert

Resource: {resource_name}
Service: {service}
Event: {event_name}
User: {user_name}
Region: {region}
Time: {deletion_time}
Account: {cloudtrail_event.get('recipientAccountId', 'Unknown')}"""

        # Send notification
        response = sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=message,
            Subject=f"AWS Deletion: {service} - {resource_name}"
        )
        
        logger.info(f"Deletion alert sent: {event_name} - {resource_name} by {user_name}")
        
        return {
            'statusCode': 200,
            'body': json.dumps('Alert sent successfully')
        }
    
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error: {str(e)}")
        }
