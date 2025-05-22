import os
import logging
import boto3
import json

dynamo_client = boto3.client('dynamodb')
dynamo_db_table = os.getenv('dynamo_db')
dynamo_db_gsi = 'FilePathIndex'

class DynamoCRUD:

    # Fetch file from Dynamo using file location
    def fetchFileDetailsUsingLocation(document_location):
        response = dynamo_client.query(
            TableName = dynamo_db_table,
            IndexName = dynamo_db_gsi,
            KeyConditionExpression = '#gsi = :value',
            ExpressionAttributeValues = {
                ':value': {'S': document_location}
            },
            ExpressionAttributeNames = { '#gsi': 'location' }
        )

        # Fetch document_id using the location of the file
        # This fetch wont return entire table item as its gsi so we need to do another fetch using the document_id
        item = response['Items'][0]
        logging.info('Got Dynamo Item: ' + json.dumps(item))
        document_id = item['document_id']['S']

        # Now we have to fetch all details using the key
        response = dynamo_client.get_item(
            TableName=dynamo_db_table,
            Key={
                "document_id": {'S': document_id}
            })

        # Table item
        item = response['Item']
        logging.info('Got item from Dynamo: ' + json.dumps(item))

        # Returning the File Data to caller
        return item

    # Update the upload status
    def updateUploadStatus(document_id, upload_status):
        # Now lets update the item
        dynamo_client.update_item(
            TableName = dynamo_db_table,
            Key = {
                "document_id"  : {'S': document_id}
            },
            UpdateExpression = "set #A = :stage",
            ExpressionAttributeNames={
                '#A': 'stage'
            },
            ExpressionAttributeValues = {
                ":stage"          : {'S': upload_status}
            },
            ReturnValues = "NONE",
        )