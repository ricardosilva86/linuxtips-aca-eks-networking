variable "project_name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type = map(object({
    cidr = string
    az   = string
    acls = optional(object({
      name     = string
      protocol = string
      port     = number
    }))
  }))
  default = {
    public-subnet-1a = {
      cidr = "10.0.48.0/24"
      az   = "a"
    },
    public-subnet-1b = {
      cidr = "10.0.49.0/24"
      az   = "b"
    },
    public-subnet-1c = {
      cidr = "10.0.50.0/24"
      az   = "c"
    }
  }
}
variable "private_subnets" {
  type = map(object({
    cidr = string
    az   = string
    acls = optional(object({
      name     = string
      protocol = string
      port     = number
    }))
  }))
  default = {
    private-subnet-1a = {
      cidr = "10.0.0.0/20"
      az   = "a"
    },
    private-subnet-1b = {
      cidr = "10.0.16.0/20"
      az   = "b"
    },
    private-subnet-1c = {
      cidr = "10.0.32.0/20"
      az   = "c"
    }
  }
}
variable "database_subnets" {
  type = map(object({
    cidr = string
    az   = string
    acls = optional(object({
      name     = string
      protocol = string
      port     = number
    }))
  }))
  default = {
    database-subnet-1a = {
      cidr = "10.0.51.0/24"
      az   = "a"
      acls = {
        name     = "mysql"
        protocol = "tcp"
        port     = 3306
      }
    },
    database-subnet-1b = {
      cidr = "10.0.52.0/24"
      az   = "b"
      acls = {
        name     = "mysql"
        protocol = "tcp"
        port     = 3306
      }
    },
    database-subnet-1c = {
      cidr = "10.0.53.0/24"
      az   = "c"
      acls = {
        name     = "mysql"
        protocol = "tcp"
        port     = 3306
      }
    }
  }
}

variable "vpc_additional_cidr" {
  type    = string
  default = ""
}

variable "tags" {
  type        = map(string)
  description = "The Tags for this project"
}