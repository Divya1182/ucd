# Layer used in S3 Query Lambda
resource "aws_lambda_layer_version" "bef-lambda-layer-requests" {
  filename         = "${path.module}/layer-packages/python_layer_requests.zip"
  layer_name       = var.lambda_layer_requests
  source_code_hash = filebase64sha256("${path.module}/layer-packages/python_layer_requests.zip")

  description              = "Lambda Python 3.11 and Python 3.12 layer for requests and requests_aws4auth"
  compatible_architectures = ["arm64", "x86_64"]
  compatible_runtimes      = ["python3.11", "python3.12"]
}
