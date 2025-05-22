import logging
import boto3
import json
import base64
from botocore.config import Config
from error_handler import ErrorHandler


class Utility:
    # Method is to check if its a General Purpose upload request
    def isGeneralPurposeUploadRequest(event):
        isGeneralPurposeUploadRequest = False

        logging.info('Checking if its a Request for General Purpose Upload')
        if 'purpose' in event['headers']:
            header_context = event['headers']['purpose']
            logging.info('Requested Context: ' + header_context)

            # If the path contains the specific key then its a Multipart Complete request
            if 'general-storage' == header_context:
                isGeneralPurposeUploadRequest = True

        logging.info('Is it a General Purpose Upload Request ? ' + str(isGeneralPurposeUploadRequest))

        return isGeneralPurposeUploadRequest

    # Method is to check if its a Multipart complete upload request
    def isMultipartCompleteRequest(event):
        logging.info('Checking if its a Multipart Complete Request')
        route_requested = event['requestContext']['http']['path']

        logging.info('Requested Path: ' + route_requested)
        isMultipartCompleteRequest = False
        path_tokens = route_requested.split('/')

        # If the path contains the specific key then its a Multipart Complete request
        if 'completeUpload' in path_tokens:
            isMultipartCompleteRequest = True

        logging.info('Is it a Multipart Complete Request ? ' + str(isMultipartCompleteRequest))

        return isMultipartCompleteRequest

    # Method is to check if its a Multipart upload Abort request
    def isMultipartAbortRequest(event):
        logging.info('Checking if its a Multipart Upload Abort Request')
        route_requested = event['requestContext']['http']['path']

        logging.info('Requested Path: ' + route_requested)
        isMultipartAbortRequest = False
        path_tokens = route_requested.split('/')

        # If the path contains the specific key then its a Multipart Complete request
        if 'abortUpload' in path_tokens:
            isMultipartAbortRequest = True

        logging.info('Is it a Multipart Abort Request ? ' + str(isMultipartAbortRequest))

        return isMultipartAbortRequest

    # Extract Payload from the event
    def extractPayload(event):
        logging.info('Extracting payload sent to API')
        request_body = ''
        if 'body' in event:
            # This comes from Authinator
            is_encoded = event['isBase64Encoded']
            if (is_encoded):
                encoded_body = event['body']
                request_body = json.loads(base64.b64decode(encoded_body))
            else:
                request_body = json.loads(event['body'])

        logging.info("Request Parameters received from Consumer -- ")
        logging.info(request_body)

        return request_body

    # Method to complete Multipart Upload
    def completeMultiPartUpload(request_body):
        s3_client = boto3.client('s3', config=Config(signature_version='s3v4'))
        logging.info('Request to complete Multipart Upload')

        try:
            if 'bucket_name' in request_body and 'object_name' in request_body and 'parts' in request_body and 'upload_id' in request_body:
                response = {
                    "isBase64Encoded": "true",
                    "statusCode": "200",
                    "headers": {
                        "content-type": "application/json"
                    }
                }
                # Body section of Response
                response_body = {
                    "statusCode": "200"
                }
                s3_response = s3_client.complete_multipart_upload(
                    Bucket=request_body['bucket_name'],
                    Key=request_body['object_name'],
                    MultipartUpload={'Parts': request_body['parts']},
                    UploadId=request_body['upload_id']
                )
                response_body['body'] = s3_response

                logging.info('Response from Complete Multipart: ' + json.dumps(response_body))
                response_body = base64.b64encode(json.dumps(response_body).encode())
                response["body"] = response_body.decode()
            else:
                error_message = 'bucket_name, object_name, parts and upload_id are mandatory fields. Please follow the API documentation - ' + ErrorHandler.DOCUMENTATION_URL
                response = ErrorHandler.getErrorResponse(error_message, 400)
        except Exception as e:
            logging.error(repr(e))
            response = ErrorHandler.getErrorResponse(repr(e), 500)

        return response

    # Method to Abort Multipart Upload
    def abortMultiPartUpload(request_body):
        s3_client = boto3.client('s3', config=Config(signature_version='s3v4'))
        logging.info('Request to Abort Multipart Upload')

        try:
            if 'bucket_name' in request_body and 'object_name' in request_body and 'upload_id' in request_body:
                response = {
                    "isBase64Encoded": "true",
                    "statusCode": "200",
                    "headers": {
                        "content-type": "application/json"
                    }
                }
                # Body section of Response
                response_body = {
                    "statusCode": "200"
                }
                s3_response = s3_client.abort_multipart_upload(
                    Bucket=request_body['bucket_name'],
                    Key=request_body['object_name'],
                    UploadId=request_body['upload_id']
                )
                response_body['body'] = s3_response

                logging.info('Response from Abort Multipart: ' + json.dumps(response_body))
                response_body = base64.b64encode(json.dumps(response_body).encode())
                response["body"] = response_body.decode()
            else:
                error_message = 'bucket_name, object_name and upload_id are mandatory fields. Please follow the API documentation - ' + ErrorHandler.DOCUMENTATION_URL
                response = ErrorHandler.getErrorResponse(error_message, 400)

        except Exception as e:
            logging.error(repr(e))
            response = ErrorHandler.getErrorResponse(repr(e), 500)

        return response
