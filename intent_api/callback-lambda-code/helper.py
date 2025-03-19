import requests
from urllib.parse import urlencode
import os
import logging
import json

class Helper:

    # Get token from Authinator
    def getToken(consumer_id, consumer_secret):
        # Token Service URL
        token_service_url = os.getenv('token_service_url')
        token = ""

        # Cleaning the leading and trailing spaces
        consumer_id = consumer_id.strip()
        consumer_secret = consumer_secret.strip()

        # Checking length if got valid details from SM
        consumer_id_len = len(consumer_id)
        consumer_secret_len = len(consumer_secret)

        logging.info('Length of Consumer Key: ' + str(consumer_id_len))
        logging.info('Length of Consumer Sec: ' + str(consumer_secret_len))

        # Masking the information for security as its sensitive data
        replacement = '********************'
        replace_len = 20

        if consumer_id_len > replace_len:
            consumer_id_masked = consumer_id[:-replace_len] + replacement
            logging.info('Masked Consumer Key: ' + consumer_id_masked)

        if consumer_secret_len > replace_len:
            consumer_secret_masked = consumer_secret[:-replace_len] + replacement
            logging.info('Masked Consumer Sec: ' + consumer_secret_masked)
        
        data = {
            "grant_type"    : "client_credentials",
            "client_id"     : consumer_id,
            "client_secret" : consumer_secret,
        }
        
        response = requests.post(token_service_url, data=data, verify=False)
        logging.info('Response received from Authinator')

        if response is not None:
            try:
                # Convert response to string and split into parts
                response_string = response.text
                #logging.info('Token Response String: ' + response_string)


                token_dict = json.loads(response_string)
                
                # Extract the token from the response
                token = token_dict['access_token']
                logging.info('Token Length: ' + str(len(token)))

            except Exception as ex:
                logging.error('Error while getting token: ' + repr(ex))

        return token
    

    # Extracts the Artifact ID from the Object key came in the event
    def extractArtifactID(event):
        artifact_id = ""
        try:
            # Sample object_key format
            # '/2025/02/06/MEDD_CMS_BID/67a4001e8e23184639b2f5d0/CMS_BID/67a4001e8e23184639b2f5d1/file.txt'
            object_key = event['detail']['object']['key']

            if '/' in object_key:
                artifact_id = object_key.rsplit('/', 2)[1]
            else:
                artifact_id = object_key

            logging.info('Extracted Artifact ID: ' + artifact_id)

        except Exception as e:
            logging.error('Error while getting token: ' + repr(e))
        
        return artifact_id


    # Callback the Intent API once file is uploaded
    def sendCallback(token, artifactId):

        callback_url = os.getenv('callback_url')
        callback_url = callback_url.replace(':artifact_id:', artifactId)
        logging.info('Callback URL: ' + callback_url)

        header = {
            "Content-type"    : "application/json",
            "Authorization"   : "Bearer " + token
        }

        response = requests.post(callback_url, headers=header, verify=False)

        return response.text

