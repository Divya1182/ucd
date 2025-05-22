import logging
import boto3
import json
import base64
import os
from botocore.config import Config
from error_handler import ErrorHandler
from datetime import datetime

dynamo_client = boto3.client('dynamodb')
dynamo_db_table = os.getenv('dynamo_db')
dynamo_db_gsi = 'FilePathIndex'


class Helper:
    # Method to send single presigned URL
    def handleSingleOperation(request_body):
        # Generate a presigned URL for the S3 object
        s3_client = boto3.client('s3', config=Config(signature_version='s3v4'))
        params = {
            'Bucket': request_body['bucket_name'],
            'Key': request_body['location']
        }

        logging.info('Parameters Passed to Presgined URL (General Purpose) : ' + json.dumps(params))

        try:
            # request_body['request_type'] valid values = put_object or get_object
            response = s3_client.generate_presigned_url(request_body['request_type'],
                                                        Params=params,
                                                        ExpiresIn=request_body['expiration'])
            response_body = {
                "statusCode": "200",
                "bucket": request_body['bucket_name'],
                "file_name": request_body['object_name'],
                "expiration": request_body['expiration'],
                "document_id": request_body['document_id'],
                "file_location": request_body['location'],
                "consumer_dir": request_body['consumer_dir'],
                "path": request_body['path'],
                "parent_document_id": request_body['parent_doc_id'],
                "s3_url": response
            }

            logging.info('Response to Consumer: ' + json.dumps(response_body))

            # Encoding the response body
            response_body = base64.b64encode(json.dumps(response_body).encode())
            response = {
                "isBase64Encoded": "true",
                "statusCode": "200",
                "headers": {
                    "content-type": "application/json"
                },
                "body": response_body.decode()
            }
        except Exception as e:
            logging.error(repr(e))
            response = ErrorHandler.getErrorResponse(repr(e), 500)

            # The response contains the presigned URL
        return response

    # Method to generate Multipart Upload URL
    def handleMultipartOperation(request_body):
        s3_client = boto3.client('s3', config=Config(signature_version='s3v4'))

        logging.info('Handling Multipart Upload request')
        try:
            # Check how many parts are there
            if 'no_of_parts' in request_body:
                response = {
                    "isBase64Encoded": "true",
                    "statusCode": "200",
                    "headers": {
                        "content-type": "application/json"
                    }
                }
                # Body section of Response
                response_body = {
                    "statusCode": "200",
                    "bucket": request_body['bucket_name'],
                    "file_name": request_body['object_name'],
                    "expiration": request_body['expiration'],
                    "document_id": request_body['document_id'],
                    "file_location": request_body['location'],
                    "consumer_dir": request_body['consumer_dir'],
                    "path": request_body['path'],
                    "parent_document_id": request_body['parent_doc_id'],
                }

                # First we need to create the upload ID
                upload_id_response = s3_client.create_multipart_upload(
                    Bucket=request_body['bucket_name'],
                    Key=request_body['location']
                )

                # Unique Upload ID for file parts
                upload_id = upload_id_response['UploadId']

                logging.info('Upload ID Generated for Multipart Upload: ' + str(upload_id))

                # Put the Upload ID in the Response
                response_body['upload_id'] = upload_id

                # Check the no of Parts for which presigned URLs requested
                no_of_parts = int(request_body['no_of_parts'])

                # Dict to keep the URLs
                urls = {}

                # Generate URL for each Part
                for part_no in range(1, no_of_parts + 1):
                    signed_url = s3_client.generate_presigned_url(
                        ClientMethod='upload_part',
                        Params={
                            'Bucket': request_body['bucket_name'],
                            'Key': request_body['location'],
                            'UploadId': upload_id,
                            'PartNumber': part_no
                        }
                    )
                    urls[part_no] = signed_url

                response_body['s3_url'] = urls
                logging.info('Response to Consumer: ' + json.dumps(response_body))

                # Encode the Response Message
                response_body = base64.b64encode(json.dumps(response_body).encode())
                response["body"] = response_body.decode()

                # This is for saving the details in Dynamo and will be removed before sending response back to consumer
                response["upload_id"] = upload_id
            else:
                error_message = 'no_of_parts missing in Payload for Multipart Upload, its mandatory field'
                response = ErrorHandler.getErrorResponse(error_message, 400)

        except Exception as e:
            logging.error(repr(e))
            response = ErrorHandler.getErrorResponse(repr(e), 500)

        return response

    # Get details from Dynamo
    def getFileIndex(document_id):
        # Lets extract the record
        response = dynamo_client.get_item(
            TableName=dynamo_db_table,
            Key={
                "document_id": {'S': document_id}
            })

        # Table item
        if response is not None and 'Item' in response:
            item = response['Item']
            logging.info('Got item from Dynamo: ' + json.dumps(item))
        else:
            error_message = 'No item found with Document_ID: ' + document_id
            logging.error(error_message)
            raise Exception('No item found with Document_ID: ' + document_id)

        # Returning the File Data to caller
        return item

    # Save file tracking information
    def saveFileIndex(request_body):
        logging.info('Control passed to Dynamo Helper to insert item with param: ' + json.dumps(request_body))
        try:
            date = datetime.now()
            item = {
                "document_id": {"S": request_body['document_id']},
                "bucket": {"S": request_body['bucket_name']},
                "consumer_dir": {"S": request_body['consumer_dir']},
                "file_name": {"S": request_body['object_name']},
                "path": {"S": request_body['path']},
                "location": {"S": request_body['location']},
                "upload_id": {"S": request_body['upload_id']},
                "metadata": {"S": request_body['metadata']},
                "stage": {"S": "Pending Upload"},
                "secret": {"S": request_body['secret']},
                "parent_document_id": {"S": request_body['parent_doc_id']},
                "created_on": {"S": str(date)}
            }
            logging.info('Payload to Dynamo: ' + json.dumps(item))

            # Now lets update the item
            dynamo_client.put_item(
                TableName=dynamo_db_table,
                Item=item,
                ReturnValues="NONE",
            )

            logging.info('Data Inserted in Dynamo')

        except Exception as ex:
            logging.error('Exception while saving file details in Dynamo')
            logging.error(repr(ex))
            raise ex

    # Delete the Dynamo entry when Abort requested
    def deleteFileIndex(request_body):
        # Delete Item using Index Key
        dynamo_client.delete_item(
            TableName=dynamo_db_table,
            Key={
                "document_id": {'S': request_body["document_id"]}
            })

        logging.info('Item deleted with document_id' + request_body["document_id"])
