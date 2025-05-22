import requests
import logging
import json
from response_handler import HandleResponse

class Helper:

    # Get token from ID Provider
    def getToken(consumer_id, consumer_secret, token_service_url):
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
            # Convert response to string and split into parts
            response_string = response.text
            #logging.info('Token Response String: ' + response_string)

            token_dict = json.loads(response_string)

            # Extract the token from the response
            token = token_dict['access_token']
            logging.info('Token Length: ' + str(len(token)))

        return token

    # Callback the consumer API once file is uploaded
    def sendCallback(token, callback_endpoint, file_details):
        # Lets check if the Token is enabled or not
        if token != 'not-needed':
            # Token enabled so add the Bearer token in Header
            header = {
                "Content-type"    : "application/json",
                "Authorization"   : "Bearer " + token
            }
        else:
            # No Token needed
            header = {
                "Content-type"    : "application/json"
            }
        logging.info('Invoking Callback Endpoint: ' + callback_endpoint)
        # Now let's prepare the response body
        response_body =  HandleResponse.getResponse(file_details) # This holds the information on the file uploaded

        # Now invoke the callback endpoint
        response = requests.post(callback_endpoint, headers=header, verify=False, data=response_body)
        logging.info('Response from callback: ' + response.text)

        return response.text
