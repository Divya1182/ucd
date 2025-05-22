import logging
import boto3
import os
import json

region_name = os.getenv('aws_region')
class SecretManager:

    # Fetch Secret Manager text and return a DICT
    def fetchSecret(secret_manager_name):
        # Create a Secrets Manager client
        session = boto3.session.Session()
        client = session.client(
            service_name='secretsmanager',
            region_name = region_name
        )
        # Get the secret manager data
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_manager_name
        )

        # Dont change to Info level, it contains sensitive data
        logging.debug('Response from Secret Manager received')

        # Getting the Secret String from the response
        secret_json = get_secret_value_response['SecretString']
        logging.debug('Secret Extracted: ' + secret_json)

        # Creating a dict from the String
        secret_dict = json.loads(secret_json)

        return  secret_dict