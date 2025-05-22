import logging
import os
import json
from endpoint_helper import Helper
from dynamo_helper import DynamoCRUD
from sm_helper import SecretManager

log_level   = os.getenv('log_level')

def handle_callback(event, context):
    logger = logging.getLogger()
    logger.setLevel(log_level)
    logger.info(event)

    # Get the details of file upload
    # Extract the document details from Dynamo
    # check the secret settings in Dynamo for the file
    # if secret value is there then read the secret value
    # Format of Secret is below -
    # {
    #     "enable_token"        : boolean,
    #     "consumer_id"         : string,
    #     "consumer_secret"     : string,
    #     "token_endpoint"      : string,
    #     "callback_endpoint"   : string
    # }
    # Generate Token
    # Invoke callback endpoint
    # Update the status of the Dynamo entry with status

    # Get the uploaded document key from the event payload
    document_location = event['detail']['object']['key']

    # Fetch the file details from Dynamo DB
    document = DynamoCRUD.fetchFileDetailsUsingLocation(document_location)

    # Check if an entry found
    if document is not None:
        upload_status = 'Uploaded'
        # Fetching the secret attribute of the file
        secret_manager_name = document['secret']['S']

        # Checking if the value is default text
        if secret_manager_name != 'not set':
            # Now we have to fetch the endpoint configuration
            try:
                endpoint_config = SecretManager.fetchSecret(secret_manager_name)
                logger.debug('Got details of Endpoint Configuration of callback: ' + json.dumps(endpoint_config))

                # Setting default token value
                token = 'not-needed'

                # Now that we got the endpoint configuration it's time to invoke endpoint
                if 'enable_token' in endpoint_config and endpoint_config['enable_token']:
                    if 'consumer_id' in endpoint_config and 'consumer_secret' in endpoint_config and 'token_endpoint' in endpoint_config:
                        # Token enabled, invoking token provider
                        consumer_id = endpoint_config['consumer_id']
                        consumer_sc = endpoint_config['consumer_secret']
                        token_endpoint = endpoint_config['token_endpoint']

                        # Get token
                        token = Helper.getToken(consumer_id=consumer_id, consumer_secret=consumer_sc, token_service_url=token_endpoint)
                    else:
                        # Token configuration not correct
                        logger.debug("Token configuration is not correct. Skipping the step")
                if 'callback_endpoint' in endpoint_config:
                    # Now we need to invoke the callback endpoint
                    callback_endpoint = endpoint_config['callback_endpoint']

                    # Get the file data in Dict format
                    file = {
                        'document_id'       : document['document_id']['S'],
                        'aws_eTag'          : event['detail']['object']['etag'],
                        'consumer_dir'      : document['consumer_dir']['S'],
                        'file_name'         : document['file_name']['S'],
                        'location'          : document['location']['S'],
                        'parent_document_id': document['parent_document_id']['S'],
                        'path'              : document['path']['S'],
                        'file_size_bytes'   : event['detail']['object']['size'],
                        'secret'            : document['secret']['S'],
                        'stage'             : 'Uploaded'
                    }

                    logger.info('Sending file details to callback endpoint: ' + json.dumps(file))

                    # Let's invoke the endpoint
                    response = Helper.sendCallback(token, callback_endpoint, file)
                    logger.info("Response from Callback Endpoint: " + response)
                    upload_status = 'Uploaded (Callback Successful)'
                else:
                    logger.debug("Callback endpoint configuration incorrect. Skipping callback step.")
                    upload_status = 'Uploaded (Callback Config Error)'

            except Exception as e:
                logger.error("Unexpected Error occurred: " + repr(e))
                upload_status = 'Uploaded (Callback Error: ' + repr(e) + ')'
        else:
            logger.debug("No callback requested, will be updating Dynamo entry only")
            upload_status = 'Uploaded (NO Callback)'

        # Now that the callback is done, we need to update the upload status in Dynamo
        try:
            DynamoCRUD.updateUploadStatus(document['document_id']['S'], upload_status)
        except Exception as e:
            logger.error("Unexpected Error occurred while updating status in Dynamo: " + repr(e))
    else:
        logger.error("Document entry not found in Dynamo with location: " + document_location)
