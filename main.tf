module "networking" {
  source       = "./modules/networking"
  project_name = "treinamento-aca"
  region       = "eu-central-1"
  vpc_cidr     = "10.0.0.0/16"
  tags = {}
}