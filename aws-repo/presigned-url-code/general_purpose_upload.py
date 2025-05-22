import logging
import os
from general_purpose_helper import Helper
from common_util import Utility
from error_handler import ErrorHandler
import uuid
import json


class GeneralPurposeUpload:
    def handleUpload(event):
        isMultipartCompleteRequest = Utility.isMultipartCompleteRequest(event)
        isMultipartAbortRequest = Utility.isMultipartAbortRequest(event)
        request_body = Utility.extractPayload(event)

        # Here we need to perform validation and also append the bucket name
        request_body['bucket_name'] = os.getenv('general_purpose_bucket')
        logging.info('Setting up the General Purpose Bucket in request object')

        if isMultipartCompleteRequest or isMultipartAbortRequest:
            # In case it's a Multipart Complete or Abort, Consumer will send document_id in request
            # Fetch file details using document ID
            if 'document_id' in request_body and request_body['document_id'] != '':
                # Fetch file details from Dynamo
                document = Helper.getFileIndex(request_body['document_id'])

                # Now that we have the document with us, lets get the upload_id and location of the file
                request_body['location'] = document['location']['S']
                request_body['upload_id'] = document['upload_id']['S']
            else:
                # Send error message
                error_message = "To Complete/Abort Multipart Upload, Document ID of the file is mandatory. Please follow the API documentation - " + ErrorHandler.DOCUMENTATION_URL
                raise Exception(error_message)

        # Checking if it's a complete upload request
        if isMultipartCompleteRequest:
            logging.info('Handling Multipart Upload Completion request')
            if 'location' in request_body:
                request_body['object_name'] = request_body['location']
                response = Utility.completeMultiPartUpload(request_body)
            else:
                # Send error message
                error_message = "Location of file not found in Index using the document ID sent. Without the valid data, Multipart upload cannot be completed"
                response = ErrorHandler.getErrorResponse(error_message, 400)

        # Checking if it's a abort upload request
        elif isMultipartAbortRequest:
            logging.info('Handling Multipart Upload Abort request')
            if 'location' in request_body:
                # First we delete the entry from Dynamo and then remove the parts
                try:
                    # Abort Upload
                    request_body['object_name'] = request_body['location']
                    response = Utility.abortMultiPartUpload(request_body)

                    # Dynamo delete
                    Helper.deleteFileIndex(request_body)
                except Exception as e:
                    logging.error(repr(e))
                    response = ErrorHandler.getErrorResponse(repr(e), 400)
            else:
                # Send error message
                error_message = "Location of file not found in Index using the document ID sent. Without the valid data, Multipart abort can not be completed"
                response = ErrorHandler.getErrorResponse(error_message, 400)

        # Its not complete upload request, so processing to prepare the presigned URL
        else:
            logging.info('Handling Request for Presigned URL')
            # Fetching the type of request (put_object, get_object, upload_part)
            # Lets check what type of request it is
            if 'request_type' in request_body and request_body['request_type'] != '':

                # Setting up default expiration of URL
                if 'expiration' not in request_body and request_body['expiration'] != '':
                    logging.info('No expiration attribute found in Request, setting default expiration of 1 hour')
                    request_body['expiration'] = 3600

                request_type = request_body['request_type']

                # Handle Download
                if request_type == 'get_object':
                    logging.info('Handling Request for Download URL')
                    # Check if mandatory field document_id is present
                    if 'document_id' in request_body and request_body['document_id'] != '':
                        # From Dynamo get the file details
                        try:
                            file = Helper.getFileIndex(request_body['document_id'])

                            # Setting the file details in request Object
                            request_body['location'] = file['location']['S']
                            request_body['object_name'] = file['file_name']['S']
                            request_body['consumer_dir'] = file['consumer_dir']['S']
                            request_body['path'] = file['path']['S']
                            request_body['document_id'] = file['document_id']['S']
                            request_body['parent_doc_id'] = file['parent_document_id']['S']
                            response = Helper.handleSingleOperation(request_body)

                        except Exception as dynamo_error:
                            # Dynamo Exception occurred while extracting file details
                            response = ErrorHandler.getErrorResponse(repr(dynamo_error), 500)
                    else:
                        # Send error message
                        error_message = "For download request, Document ID is mandatory. No document ID found in request body. Please follow the API documentation - " + ErrorHandler.DOCUMENTATION_URL
                        response = ErrorHandler.getErrorResponse(error_message, 400)

                # Handle Single Upload
                elif request_type == 'put_object' or request_type == 'upload_part':
                    logging.info('Handling Request for Upload URL')

                    # Check if there is metadata supplied, if so then check the format is proper JSON
                    if 'metadata' in request_body and request_body['metadata'] != '':
                        metadata = request_body['metadata']
                        logging.info('Metadata Object present: ' + metadata)
                        try:
                            # Checking if its proper JSON format and can be loaded as DICT object
                            # If not that means its improper format
                            json.loads(metadata)

                            # As its proper format so lets create the DICT object
                            metadata_dict = {
                                "metadata": metadata
                            }

                            logging.info('Metadata is in proper format and will be loaded in Dynamo')

                        except Exception as e:
                            error_message = 'The metadata in the payload is not in proper json format. Please correct the format'
                            logging.error(error_message)
                            raise Exception(error_message)
                    else:
                        metadata_dict = {
                            "metadata": "no data"
                        }

                    # Loading the metadata in request
                    request_body['metadata'] = json.dumps(metadata_dict)
                    logging.info('Metadata loaded in request')

                    if (  'object_name' in request_body and request_body['object_name'] != '' and
                        (('parent_doc_id' in request_body and request_body['parent_doc_id'] != '') or
                         ('consumer_dir' in request_body and request_body['consumer_dir'] != ''))):
                        # Generate an unique ID for the new file
                        document_id = str(uuid.uuid4())
                        location = ''

                        # Check if the consumer sent a parent_doc_id, if so then that will be used for storing the new object
                        if 'parent_doc_id' in request_body and request_body['parent_doc_id'] != '':
                            # This is the doc ID of the Parent file
                            parent_doc_id = request_body['parent_doc_id']
                            parent_file = Helper.getFileIndex(parent_doc_id)
                            logging.info(
                                'Parent Document ID found in Request, will be using the parent location for doc storage - ' + parent_doc_id)

                            # Parent document location
                            parent_path = parent_file['path']['S']
                            consumer_dir = parent_file['consumer_dir']['S']

                            # Now let's prepare the path for new file
                            location = consumer_dir + '/' + parent_path + '/'
                            final_path = parent_path
                            if 'path' in request_body and request_body['path'] is not None:
                                final_path = final_path + '/' + request_body['path']
                                location = location + request_body['path'] + '/'
                                logging.info(
                                    'Apart from Parent Path, a separate path entry found in request, will be appending the path to parent path. Final Path - ' + final_path)

                            request_body['path'] = final_path + '/' + document_id

                        # If parent doc ID is not there then Consumer_dir is mandatory
                        elif 'consumer_dir' in request_body and request_body['consumer_dir'] != '':
                            # Parent directory of consumer
                            consumer_dir = request_body['consumer_dir']
                            logging.info('Consumer Dir found in request - ' + consumer_dir)

                            # Need to set parent doc id blank in Dynamo
                            request_body['parent_doc_id'] = ' '

                            # Now let's prepare the path for new file
                            location = consumer_dir + '/'
                            final_path = ''
                            if 'path' in request_body and request_body['path'] is not None:
                                final_path = request_body['path'] + '/'
                                location = location + request_body['path'] + '/'
                                logging.info('Path found in request, so appending path to Consumer Directory')

                            final_path = final_path + document_id
                            request_body['path'] = final_path

                        # Set final location in request_object
                        location = location + document_id + '/' + request_body['object_name']
                        request_body['location'] = location
                        request_body['document_id'] = document_id
                        logging.info('Final Location of Document, - ID:' + document_id + ', is ' + location)

                        # We have the location set, now we need to check if its a single upload call or multi upload call
                        if request_type == 'put_object':
                            response = Helper.handleSingleOperation(request_body)
                            # Default upload_id for single upload
                            request_body["upload_id"] = "Not Multipart"
                        else:
                            response = Helper.handleMultipartOperation(request_body)
                            # Fetch the upload_id from the response
                            request_body["upload_id"] = response["upload_id"]
                            # Remove this redundant item from response
                            del response["upload_id"]

                        # Now that the file URL is generated, we need to save it in Dynamo
                        if 'secret' not in request_body or ('secret' in request_body and request_body['secret'] == ''):
                            request_body['secret'] = 'not set'
                            logging.info('No Secret value sent for callback, setting default value')

                        # In case of Dynamo Insert failure, need to send error response to user even if the url generation is successful
                        try:
                            Helper.saveFileIndex(request_body)
                            logging.info('Saved file details in Dynamo')
                        except Exception as e:
                            # Send error message
                            logging.error(repr(e))
                            response = ErrorHandler.getErrorResponse(repr(e), 500)
                    else:
                        # Send error message
                        error_message = "Mandatory fields missing. Object_name is mandatory along with Either parent_doc_id or consumer_dir. Refer documentation - " + ErrorHandler.DOCUMENTATION_URL
                        response = ErrorHandler.getErrorResponse(error_message, 400)
                        logging.error(error_message)
                else:
                    # Send error message
                    error_message = "Operation type not supported. Its should be one of accepted values : [get_object, put_object, upload_part]. Refer documentation - " + ErrorHandler.DOCUMENTATION_URL
                    response = ErrorHandler.getErrorResponse(error_message, 400)
                    logging.error(error_message)

        # Final response to caller
        return response
