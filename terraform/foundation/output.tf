output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "server_public_ips" {
  value = { for name, s in aws_instance.server : name => s.public_ip }
}

output "server_private_ips" {
  value = { for name, s in aws_instance.server : name => s.private_ip }
}
