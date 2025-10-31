locals {
  common_tags = {
    BusinessUnit = var.business_unit
    Project      = var.project
    Environment  = var.environment
    ManagedBy    = "terraform"
  }
}