provider "aws" {
  region = "us-east-1"
  # profile = "saml"
}

provider "aws" {
  alias  = "crr"
  region = "us-west-1"
  # profile = "saml"
}