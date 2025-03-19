import logging
import boto3
import json
import base64
from botocore.config import Config
from error_handler import ErrorHandler

class Helper:
    # Method is to check if its a Multipart complete upload request
    def isMultipartCompleteRequest(event):
        logging.info('Checking if its a Multipart Complete Request')
        route_requested = event['requestContext']['http']['path']

        logging.info('Requested Path: ' + route_requested)
        isMultipartCompleteRequest = False
        path_tokens = route_requested.split('/')

        # If the path contains the specific key then its a Multipart Complete request
        if('completeUpload' in path_tokens):
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
        if('abortUpload' in path_tokens):
            isMultipartAbortRequest = True
        
        logging.info('Is it a Multipart Abort Request ? ' + str(isMultipartAbortRequest))
        
        return isMultipartAbortRequest
    

    # Extract Payload from the event
    """Generate a presigned URL to share an S3 object
    :param bucket_name: string
    :param object_name: string
    :param content_type: string
    :param expiration: Time in seconds for the presigned URL to remain valid
    :return: Presigned URL as string. If error, returns None.
    :JSON Structure to invoke the API 
    {
        "bucket_name": "intents-artifacts-364685145795",
        "object_name": "response.txt",
        "expiration": "3600",
        "content_type": "application/xml",
        "request_type": "<operation*>"
    }

    <operation*> = put_object/get_object
    """
    def extractPayload(event):
        logging.info('Extracting payload sent to API')
        request_body = ''
        if 'body'in event:
            # This comes from Authinator
            is_encoded = event['isBase64Encoded']
            if (is_encoded):
                encoded_body = event['body']
                request_body = json.loads(base64.b64decode(encoded_body))
            else:
                request_body = json.loads(event['body'])
        
        logging.info(request_body)
        return request_body
    
    # Method to send single presigned URL
    def getSingleUploadURL(request_body):
        # Generate a presigned URL for the S3 object
        s3_client = boto3.client('s3', config=Config(signature_version='s3v4'))
        params = {
                    'Bucket': request_body['bucket_name'],
                    'Key': request_body['object_name']
                 }
        
        # Content Type is needed only for Put 
        if(request_body['request_type'] == 'put_object'):
            if 'content_type' in request_body:
                params['ContentType'] = request_body['content_type']

        logging.info('Parameters Passed to Presgined URL: ' + json.dumps(params))

        try:
            # request_body['request_type'] valid values = put_object or get_object
            response = s3_client.generate_presigned_url(request_body['request_type'],
                                                        Params = params,
                                                        ExpiresIn=request_body['expiration'])
            response_body = {
                "statusCode": "200",
                "expiration": request_body['expiration'],
                "s3_url"    : response
            }

            logging.info('Presigned URL: ' + str(response))

            response_body = base64.b64encode(json.dumps(response_body).encode())
            response = {
                "isBase64Encoded" : "true", 
                "statusCode": "200", 
                "headers": {
                    "content-type":"application/json"
                },
                "body": response_body.decode()
            }
        except Exception as e:
            logging.error(e)
            response = ErrorHandler.getErrorResponse(repr(e), 500) 
            
        logging.info(json.dumps(response))
        # The response contains the presigned URL
        return response
    
    # Method to generate Multipart Upload URL
    def getMultiPartURL(request_body):
        s3_client = boto3.client('s3', config=Config(signature_version='s3v4'))
        # Final Response
        response = {}

        try:
            # Check how many parts are there
            if 'no_of_parts' in request_body:
                response = {
                                "isBase64Encoded" : "true", 
                                "statusCode": "200", 
                                "headers": {
                                    "content-type":"application/json"
                                }
                            }
                # Body section of Response
                response_body = {
                    "statusCode": "200"
                }

                # First we need to create the upload ID
                upload_id_response = s3_client.create_multipart_upload(
                                                                Bucket = request_body['bucket_name'],
                                                                Key    = request_body['object_name']
                                                            )

                # Unique Upload ID for file parts
                upload_id = upload_id_response['UploadId']

                # Put the Upload ID in the Response
                response_body['upload_id'] = upload_id
                
                # Check the no of Parts for which presigned URLs requested
                no_of_parts = int(request_body['no_of_parts'])

                # Dict to keep the URLs
                urls = {}

                # Generate URL for each Part
                for part_no in range(1, no_of_parts + 1):
                    signed_url  = s3_client.generate_presigned_url(
                                                        ClientMethod ='upload_part',
                                                        Params = {
                                                                    'Bucket'    : request_body['bucket_name'],
                                                                    'Key'       : request_body['object_name'], 
                                                                    'UploadId'  : upload_id, 
                                                                    'PartNumber': part_no
                                                                }
                                                    )
                    urls[part_no] = signed_url
                
                response_body['s3_url'] = urls
                logging.info('Generated URLs: ' + json.dumps(response_body))

                # Encode the Response Message
                response_body = base64.b64encode(json.dumps(response_body).encode())
                response["body"] = response_body.decode()
            else:
                error_message = 'no_of_parts missing in Payload for Multipart Upload, its mandatory field'
                response = ErrorHandler.getErrorResponse(error_message, 400)
        
        except Exception as e:
            logging.error(e)
            response = ErrorHandler.getErrorResponse(repr(e), 500) 
        

        return response

    # Method to complete Multipart Upload
    def completeMultiPartUpload(request_body):
        s3_client = boto3.client('s3', config=Config(signature_version='s3v4'))
        response = {}
        try:
            if 'bucket_name' in request_body and 'object_name' in request_body and 'parts' in request_body and 'upload_id' in request_body:
                response = {
                                "isBase64Encoded" : "true", 
                                "statusCode": "200", 
                                "headers": {
                                    "content-type":"application/json"
                                }
                            }
                # Body section of Response
                response_body = {
                    "statusCode": "200"
                }
                s3_response = s3_client.complete_multipart_upload(
                                                                Bucket          = request_body['bucket_name'],
                                                                Key             = request_body['object_name'],
                                                                MultipartUpload = {'Parts': request_body['parts']},
                                                                UploadId        = request_body['upload_id']
                                                            )
                response_body['body'] = s3_response

                logging.info('Response from Complete Multipart: ' + json.dumps(response_body))
                response_body = base64.b64encode(json.dumps(response_body).encode())
                response["body"] = response_body.decode()
            else:
                error_message = 'bucket_name, object_name, parts and upload_id are mandatory fields'
                response = ErrorHandler.getErrorResponse(error_message, 400)
        except Exception as e:
            logging.error(e)
            response = ErrorHandler.getErrorResponse(repr(e), 500) 
        
        return response
    

    # Method to Abort Multipart Upload
    def abortMultiPartUpload(request_body):
        s3_client = boto3.client('s3', config=Config(signature_version='s3v4'))
        response = {}
        try:
            if 'bucket_name' in request_body and 'object_name' in request_body and 'upload_id' in request_body:
                response = {
                                "isBase64Encoded" : "true", 
                                "statusCode": "200", 
                                "headers": {
                                    "content-type":"application/json"
                                }
                            }
                # Body section of Response
                response_body = {
                    "statusCode": "200"
                }
                s3_response = s3_client.abort_multipart_upload(
                                                                Bucket          = request_body['bucket_name'],
                                                                Key             = request_body['object_name'],
                                                                UploadId        = request_body['upload_id']
                                                            )
                response_body['body'] = s3_response

                logging.info('Response from Abort Multipart: ' + json.dumps(response_body))
                response_body = base64.b64encode(json.dumps(response_body).encode())
                response["body"] = response_body.decode()
            else:
                error_message = 'bucket_name, object_name and upload_id are mandatory fields'
                response = ErrorHandler.getErrorResponse(error_message, 400)

        except Exception as e:
            logging.error(e)
            response = ErrorHandler.getErrorResponse(repr(e), 500) 
        
        return response
    