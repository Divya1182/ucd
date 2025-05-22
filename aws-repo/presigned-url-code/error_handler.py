import json


class ErrorHandler:
    # Prepare Error Response
    DOCUMENTATION_URL = str("https://confluence.sys.cigna.com/display/BECOE/General+Purpose+Storage")

    def getErrorResponse(message, error_code):
        body = {
            "statusCode": error_code,
            "error": message
        }
        response = {
            "isBase64Encoded": "false",
            "statusCode": error_code,
            "headers": {
                "content-type": "application/json"
            },
            "body": json.dumps(body)
        }

        return response
