import json
import boto3
import logging
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sns_client = boto3.client('sns')
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

def get_resource_name(cloudtrail_event):
    logger.info("Starting resource name extraction")
    
    # Try resources array first (most reliable when present)
    resources = cloudtrail_event.get('resources', [])
    logger.info(f"Resources array: {resources}")
    
    if resources:
        resource_name = resources[0].get('resourceName', 'Unknown')
        logger.info(f"Found resource name from resources array: {resource_name}")
        return resource_name
    
    # Check request parameters for any resource identifier
    request_params = cloudtrail_event.get('requestParameters')
    logger.info(f"Request parameters: {request_params}")
    logger.info(f"Request parameters type: {type(request_params)}")
    
    if request_params is None:
        logger.warning("Request parameters is None, skipping parameter extraction")
        return 'Unknown'
    
    if not isinstance(request_params, dict):
        logger.warning(f"Request parameters is not a dict, it's {type(request_params)}")
        return 'Unknown'
    
    # Try common resource identifier field names
    common_fields = [
        'name', 'Name', 'id', 'Id', 'identifier', 'Identifier',
        'arn', 'Arn', 'resourceId', 'ResourceId', 'resourceName', 'ResourceName'
    ]
    
    logger.info(f"Checking common fields: {common_fields}")
    for field in common_fields:
        if field in request_params:
            value = request_params[field]
            logger.info(f"Found field '{field}' with value: {value}")
            if isinstance(value, list) and value:
                result = ', '.join(str(v) for v in value)
                logger.info(f"Returning list value: {result}")
                return result
            elif value:
                result = str(value)
                logger.info(f"Returning single value: {result}")
                return result
    
    # If no common fields found, try to find any field that looks like a resource identifier
    logger.info("No common fields found, checking pattern matching")
    try:
        for key, value in request_params.items():
            logger.debug(f"Checking key: {key}, value: {value}, type: {type(value)}")
            if value and isinstance(value, str):
                # Look for fields that end with common resource identifier patterns
                if any(key.lower().endswith(suffix) for suffix in ['name', 'id', 'arn', 'identifier']):
                    logger.info(f"Found pattern match - key: {key}, value: {value}")
                    return str(value)
    except Exception as e:
        logger.error(f"Error during pattern matching: {str(e)}")
    
    logger.warning("No resource name found, returning 'Unknown'")
    return 'Unknown'

def get_user_name(user_identity):
    logger.info(f"Extracting user name from identity: {user_identity}")
    
    user_type = user_identity.get('type', '')
    logger.info(f"User type: {user_type}")
    
    if user_type == 'AssumedRole':
        # Get actual user from principalId (after colon)
        principal_id = user_identity.get('principalId', '')
        logger.info(f"Principal ID: {principal_id}")
        
        if ':' in principal_id:
            user_name = principal_id.split(':')[-1]
            logger.info(f"Extracted user from principal ID: {user_name}")
            return user_name
        
        # Fallback to role name
        session_context = user_identity.get('sessionContext', {})
        session_issuer = session_context.get('sessionIssuer', {})
        role_name = session_issuer.get('userName', 'Unknown')
        logger.info(f"Using role name as fallback: {role_name}")
        return role_name
    
    user_name = user_identity.get('userName', user_identity.get('arn', 'Unknown'))
    logger.info(f"Using direct user name: {user_name}")
    return user_name

def lambda_handler(event, context):
    try:
        logger.info("=== Lambda function started ===")
        logger.info(f"Received event: {json.dumps(event, default=str, indent=2)}")
        
        cloudtrail_event = event.get('detail')
        if not cloudtrail_event:
            logger.error("No 'detail' found in event")
            return {'statusCode': 400, 'body': 'Invalid event structure'}
        
        logger.info(f"CloudTrail event: {json.dumps(cloudtrail_event, default=str, indent=2)}")
        
        event_name = cloudtrail_event.get('eventName', 'Unknown')
        logger.info(f"Event name: {event_name}")
        
        # Check for error conditions in the event
        error_code = cloudtrail_event.get('errorCode')
        error_message = cloudtrail_event.get('errorMessage')
        
        if error_code:
            logger.warning(f"Event contains error - Code: {error_code}, Message: {error_message}")
            # You might want to skip processing error events or handle them differently
            if error_code == 'Client.DryRunOperation':
                logger.info("Skipping DryRun operation")
                return {'statusCode': 200, 'body': 'DryRun operation skipped'}
        
        # Extract essential details
        logger.info("=== Starting data extraction ===")
        
        try:
            resource_name = get_resource_name(cloudtrail_event)
            logger.info(f"Extracted resource name: {resource_name}")
        except Exception as e:
            logger.error(f"Error extracting resource name: {str(e)}")
            resource_name = 'Unknown'
        
        deletion_time = cloudtrail_event.get('eventTime', 'Unknown')
        logger.info(f"Deletion time: {deletion_time}")
        
        region = cloudtrail_event.get('awsRegion', 'Unknown')
        logger.info(f"Region: {region}")
        
        user_identity = cloudtrail_event.get('userIdentity', {})
        try:
            user_name = get_user_name(user_identity)
            logger.info(f"Extracted user name: {user_name}")
        except Exception as e:
            logger.error(f"Error extracting user name: {str(e)}")
            user_name = 'Unknown'
        
        service = cloudtrail_event.get('eventSource', '').replace('.amazonaws.com', '')
        logger.info(f"Service: {service}")
        
        account_id = cloudtrail_event.get('recipientAccountId', 'Unknown')
        logger.info(f"Account ID: {account_id}")
        
        # Simple message with essential details only
        message = f"""AWS Resource Deletion Alert

Resource: {resource_name}
Service: {service}
Event: {event_name}
User: {user_name}
Region: {region}
Time: {deletion_time}
Account: {account_id}"""

        if error_code:
            message += f"\nError: {error_code} - {error_message}"

        logger.info(f"Prepared message: {message}")
        
        # Send notification
        logger.info("=== Sending SNS notification ===")
        try:
            response = sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=message,
                Subject=f"AWS Deletion: {service} - {resource_name}"
            )
            logger.info(f"SNS response: {response}")
            
            logger.info(f"Deletion alert sent successfully: {event_name} - {resource_name} by {user_name}")
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Alert sent successfully',
                    'messageId': response.get('MessageId'),
                    'eventName': event_name,
                    'resourceName': resource_name,
                    'user': user_name
                })
            }
        except Exception as sns_error:
            logger.error(f"Error sending SNS notification: {str(sns_error)}")
            raise sns_error
    
    except Exception as e:
        logger.error(f"=== ERROR IN LAMBDA HANDLER ===")
        logger.error(f"Error type: {type(e).__name__}")
        logger.error(f"Error message: {str(e)}")
        logger.error(f"Full traceback:", exc_info=True)
        logger.error(f"Event that caused error: {json.dumps(event, default=str, indent=2)}")
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'errorType': type(e).__name__,
                'message': 'Failed to process deletion event'
            })
        }
