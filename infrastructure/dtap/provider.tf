# Use the Amazon Web Services (AWS) provider to interact with the many resources supported by AWS.
provider "aws" {
  region = var.region
  assume_role {
    role_arn = var.assume_role_arn
  }
  default_tags {
    tags = local.common_tags
  }  
}
