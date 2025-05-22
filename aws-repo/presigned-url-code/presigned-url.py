import logging
import os
from common_util import Utility
from intent_upload import IntentUpload
from general_purpose_upload import GeneralPurposeUpload
from error_handler import ErrorHandler


def presigned_url(event, context):
    logger = logging.getLogger()
    logger.setLevel(os.getenv('log_level'))
    logging.info(event)

    try:
        # First we will check if it's a request for General Purpose storage from other consumers
        isGeneralPurposeUploadRequest = Utility.isGeneralPurposeUploadRequest(event)

        if isGeneralPurposeUploadRequest:
            # It's a General Purpose upload
            logger.info("It's a request for General-Purpose document storage")
            response = GeneralPurposeUpload.handleUpload(event)
        else:
            # It's a Intent Artifact upload
            logger.info("It's a request for Intent-Artifact storage")
            response = IntentUpload.handleUpload(event)
    except Exception as ex:
        logger.error(repr(ex))
        response = ErrorHandler.getErrorResponse(repr(ex), 500)

    # Sending response back to caller
    return response
