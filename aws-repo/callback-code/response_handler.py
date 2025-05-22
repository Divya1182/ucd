import json

class HandleResponse:

    def getResponse(response_body):
        response = {
            "statusCode": "200",
            "headers": {
                "content-type": "application/json"
            },
            "body": json.dumps(response_body)
        }
        return response
