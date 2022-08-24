locals {
  environment = "development"
  service_name = "IaC"
  owner        = "AppOps Team"
  common_tags = {
    Service = local.service_name
    Owner   = local.owner
    Environment = local.environment
  }
}