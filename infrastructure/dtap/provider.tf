# Use the Amazon Web Services (AWS) provider to interact with the many resources supported by AWS.
provider "aws" {
  region = var.region
  default_tags {
    tags = local.common_tags
  }  
}
