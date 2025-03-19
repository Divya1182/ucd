

import logging
import os
import boto3
import json
from helper import Helper

log_level   = os.getenv('log_level')
secret_name = os.getenv('secret_name')
region_name = os.getenv('aws_region')

def callback(event, context):
    logger = logging.getLogger()
    logger.setLevel(log_level)
    logging.info(event)

    
    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        # Get the secret manager data 
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )

        # Dont change to Info level, it contains sensitive data
        logger.debug('Response from Secret Manager received')

        # Getting the Secret String from the response
        secret_json = get_secret_value_response['SecretString']
        logger.debug('Secret Extracted')

        # Creating a dict from the String
        secret_dict = json.loads(secret_json)

        consumer_id = secret_dict['consumer_id']
        consumer_secret = secret_dict['consumer_secret']

        # Now we have the consumer details, its time to get auth token
        token = Helper.getToken(consumer_id, consumer_secret)

        # Now that we got the token, its time to make the API call
        if token != '':
            artifact_id = Helper.extractArtifactID(event)
            callback_response = Helper.sendCallback(token, artifact_id)
            logger.info('Response from Callback: ' + repr(callback_response))

    except Exception as e:
        logger.error(repr(e))
