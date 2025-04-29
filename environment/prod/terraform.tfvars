project_name = "eks-vpc"
region       = "eu-central-1"

vpc_cidr = "10.0.0.0/16"
vpc_additional_cidr = [
  "100.64.0.0/16",
  "",
]