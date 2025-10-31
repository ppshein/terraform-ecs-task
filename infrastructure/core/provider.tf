variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

# AWS Provider
provider "aws" {
  region = var.region
}