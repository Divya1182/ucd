

import logging
import os
from helper import Helper
from error_handler import ErrorHandler

log_level   = os.getenv('log_level')

def presigned_url(event, context):
    logger = logging.getLogger()
    logger.setLevel(log_level)
    logging.info(event)
    
    response = {}
    
    isMultipartCompleteRequest  = Helper.isMultipartCompleteRequest(event)
    isMultipartAbortRequest     = Helper.isMultipartAbortRequest(event)
    request_body = Helper.extractPayload(event)

    # Checking if its a complete upload request
    if isMultipartCompleteRequest:
        response = Helper.completeMultiPartUpload(request_body)
    
    # Checking if its a abort upload request
    elif isMultipartAbortRequest:
        response = Helper.completeMultiPartAbort(request_body)
    
    # Its not complete upload request, so processing to prepare the presigned URL
    else:
        # Fetching the type of request (put_object, get_object, upload_part)
        if 'request_type' in request_body:

            # Process Multipart Upload
            if request_body['request_type'] == 'upload_part':
                # Code for multipart upload
                response = Helper.getMultiPartURL(request_body)
            
            # Process simple upload
            else:
                response = Helper.getSingleUploadURL(request_body)
        
        # Bad payload
        else:
            # Send error message
            error_message = "request_type missing in Payload, cannot complete operation"
            response = ErrorHandler.getErrorResponse(error_message, 400)

    # Final response to caller
    return response