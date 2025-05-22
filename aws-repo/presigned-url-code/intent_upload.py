import logging
from intent_helper import Helper
from common_util import Utility
from error_handler import ErrorHandler


class IntentUpload:
    def handleUpload(event):
        isMultipartCompleteRequest = Utility.isMultipartCompleteRequest(event)
        isMultipartAbortRequest = Utility.isMultipartAbortRequest(event)
        request_body = Utility.extractPayload(event)

        # Checking if its a complete upload request
        if isMultipartCompleteRequest:
            response = Utility.completeMultiPartUpload(request_body)

        # Checking if its a abort upload request
        elif isMultipartAbortRequest:
            response = Utility.abortMultiPartUpload(request_body)

        # Its not complete upload request, so processing to prepare the presigned URL
        else:
            # Fetching the type of request (put_object, get_object, upload_part)
            if 'request_type' in request_body:

                # Process Multipart Upload
                if request_body['request_type'] == 'upload_part':
                    logging.error('Request is for Multipart Upload URL')
                    # Code for multipart upload
                    response = Helper.getMultiPartURL(request_body)

                # Process simple upload
                else:
                    logging.error('Request is for Single Upload/Download URL')
                    response = Helper.getSingleUploadURL(request_body)

            # Bad payload
            else:
                # Send error message
                error_message = "request_type missing in Payload, cannot complete operation"
                response = ErrorHandler.getErrorResponse(error_message, 400)
                logging.error(error_message)

        # Final response to caller
        return response
