# Terraform module configuration
module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  region       = var.region
  vpc_cidr     = var.vpc_cidr
  tags         = var.tags
}