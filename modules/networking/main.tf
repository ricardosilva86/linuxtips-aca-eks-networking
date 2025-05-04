locals {
  database_subnets = { for idx, key in keys(var.database_subnets) : key => 100 + idx }
}

##### VPC #####
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = var.tags
}

resource "aws_vpc_ipv4_cidr_block_association" "main" {
  count      = length(var.vpc_additional_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.vpc_additional_cidr
}

##### Internet Gateway #####
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = format("%s-igw", var.project_name)
  }
}

##### IAM for API Gateway Setup #####
resource "aws_iam_role" "logging" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "logging" {
  role       = aws_iam_role.logging.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.logging.arn
}

##### PUBLIC SUBNETS #####
# Subnets
resource "aws_subnet" "public_subnets" {
  for_each          = var.public_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = format("%s%s", var.region, each.value.az)
  tags = {
    Name = each.key
  }
}

# Public Internet Access
resource "aws_route_table" "public_internet_access" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = format("%s-public", var.project_name)
  }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public_internet_access.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  for_each       = var.public_subnets
  route_table_id = aws_route_table.public_internet_access.id
  subnet_id      = aws_subnet.public_subnets[each.key].id
}

##### NAT Gateways #####
resource "aws_eip" "vpc_eips" {
  for_each = var.public_subnets
  domain   = "vpc"
  tags = {
    Name = format("%s-eip", each.key)
  }
}

resource "aws_nat_gateway" "nat_gateways" {
  for_each      = var.public_subnets
  allocation_id = aws_eip.vpc_eips[each.key].id
  subnet_id     = aws_subnet.public_subnets[each.key].id
  tags = {
    Name = format("%s-nat", each.key)
  }
}

##### PRIVATE SUBNETS #####
# Subnets
resource "aws_subnet" "private_subnets" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = format("%s%s", var.region, each.value.az)
  tags = {
    Name = each.key
  }
}

# Private Internet Access
resource "aws_route_table" "private_internet_access" {
  for_each = var.private_subnets
  vpc_id   = aws_vpc.main.id
  tags = {
    Name = format("%s-private", each.key)
  }
}

resource "aws_route" "private_internet_access" {
  for_each               = var.private_subnets
  route_table_id         = aws_route_table.private_internet_access[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gateways[
    [for key, value in var.public_subnets : key if value.az == var.private_subnets[each.key].az][0]
  ].id
}

resource "aws_route_table_association" "private_association" {
  for_each       = var.private_subnets
  subnet_id      = aws_subnet.private_subnets[each.key].id
  route_table_id = aws_route_table.private_internet_access[each.key].id
}

##### DATABASE SUBNETS #####
# Subnets
resource "aws_subnet" "databases_subnets" {
  for_each          = var.database_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = format("%s%s", var.region, each.value.az)

  tags = {
    Name = format("%s-databases-subnet", each.key)
  }
}

# NACLs
resource "aws_network_acl" "database" {
  vpc_id = aws_vpc.main.id

  egress {
    rule_no    = 200
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = format("%s-databases", var.project_name)
  }
}

resource "aws_network_acl_rule" "deny" {
  network_acl_id = aws_network_acl.database.id
  protocol       = "-1"
  rule_action    = "deny"
  rule_number    = 300
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "allow_ports" {
  for_each       = var.database_subnets
  network_acl_id = aws_network_acl.database.id
  protocol       = each.value.acls.protocol
  rule_action    = "allow"
  rule_number    = local.database_subnets[each.key]
  cidr_block     = aws_subnet.private_subnets["private-subnet-1${each.value.az}"].cidr_block
  from_port      = 0
  to_port        = each.value.acls.port
}

### EXPORTANDO OS IDS PARA SSM PARAMETERS ###
resource "aws_ssm_parameter" "vpc_id" {
  name  = format("/%s/vpc/vpc_id", var.project_name)
  type  = "String"
  value = aws_vpc.main.id
}

resource "aws_ssm_parameter" "private_subnets" {
  for_each = aws_subnet.private_subnets
  name     = format("/%s/vpc/subnet_private_%s", var.project_name, split("-", aws_subnet.private_subnets[each.key].availability_zone)[2])
  type     = "String"
  value    = aws_subnet.private_subnets[each.key].id
}

resource "aws_ssm_parameter" "public_subnets" {
  for_each = aws_subnet.public_subnets
  name     = format("/%s/vpc/subnet_public_%s", var.project_name, split("-", aws_subnet.public_subnets[each.key].availability_zone)[2])
  type     = "String"
  value    = aws_subnet.public_subnets[each.key].id
}

resource "aws_ssm_parameter" "database_subnets" {
  for_each = aws_subnet.databases_subnets
  name     = format("/%s/vpc/subnet_database_%s", var.project_name, split("-", aws_subnet.databases_subnets[each.key].availability_zone)[2])
  type     = "String"
  value    = aws_subnet.databases_subnets[each.key].id
}

