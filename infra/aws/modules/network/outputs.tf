output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block."
  value       = aws_vpc.this.cidr_block
}

output "availability_zones" {
  description = "AZs used by the subnets."
  value       = local.azs
}

output "public_subnet_ids" {
  description = "Public subnets (load balancers)."
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "Private subnets for ECS tasks."
  value       = aws_subnet.app[*].id
}

output "db_subnet_ids" {
  description = "Isolated subnets for databases (no internet route)."
  value       = aws_subnet.db[*].id
}
