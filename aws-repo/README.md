# Presigned URL Solution
Intent Artifact Storage Solution [Documentation](https://confluence.sys.cigna.com/display/BECOE/BEF+-+Intent+Artifacts+Storage+Solution)<br>
General Purpose Storage Solution [Documentation](https://confluence.sys.cigna.com/display/BECOE/General+Purpose+Storage)

<hr/>

### How to create secret manager for new consumer
1. Add new SM resource block in ```bef-presgined-url-callback-sm.tf``` file
2. Add the secret text in pipeline variable
3. Update Jenkins file to read the secret text from pipeline var and assign the value to TFVAR

#### Secret test format to add in pipeline variable:
```JSON
{
  "enable_token"      : boolean,
  "consumer_id"       : string,
  "consumer_secret"   : string,
  "token_endpoint"    : string,
  "callback_endpoint" : string
}
```
##### Dictionary
``enable_token:``<br>
If value is True that means that the endpoint is behind protected Gateway and Token is needed to access the endpoint
If value is False then the ``callback_endpoint`` will be invoked directly without TOKEN generation step

``consumer_id/consumer_secret:``<br>
Used in case enable_token is set tot true. The consumer_id and consumer_secret will be used to generate the TOKEN to access endpoint

``token_endpoint:``<br>
This is gateway endpoint to generate TOKEN using the ``consumer_id/consumer_secret`` values provided

``callback_endpoint:``<br>
Consumer API Endpoint to be invoked to notify successful upload of file in S3 bucket

<hr>
