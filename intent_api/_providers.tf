provider "aws" {
  region = var.region
  # profile = "saml"
}

provider "aws" {
  alias  = "crr"
  region = "us-west-1"
  # profile = "saml"
}