provider "aws" {
  region = var.region
  # profile = "saml"
}

provider "aws" {
  alias  = "crr"
  region = "us-east-2"
  # profile = "saml"
}
