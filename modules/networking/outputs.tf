output "vpc_id" {
  description = "ID do VPC armazenado no AWS Systems Manager Parameter Store. Este ID é usado para identificar o VPC onde os recursos serão provisionados."
  value       = aws_vpc.main.id
}

output "subnet_private" {
  description = "ID da subnet privada na zona de disponibilidade 1a. Valor armazenado no AWS Systems Manager Parameter Store, utilizado para provisionar recursos em uma subnet privada específica."
  value       = [for s in aws_subnet.private_subnets : s.id]
}

output "subnet_public" {
  description = "ID da subnet pública na zona de disponibilidade 1a. Este ID, proveniente do AWS Systems Manager Parameter Store, é utilizado para provisionar recursos acessíveis publicamente nesta zona."
  value       = [for s in aws_subnet.public_subnets : s.id]
}

output "subnet_database" {
  description = "ID da subnet de bancos de dados na zona de disponibilidade 1c, proveniente do AWS Systems Manager Parameter Store. Utilizado no provisionamento de instâncias de banco de dados que requerem isolamento nesta zona."
  value       = [for s in aws_subnet.databases_subnets : s.id]
}