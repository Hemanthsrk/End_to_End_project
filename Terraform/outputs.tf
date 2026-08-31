output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "frontend_ecr_repository" {
  description = "Frontend ECR repository"
  value       = aws_ecr_repository.frontend.repository_url
}

output "backend_ecr_repository" {
  description = "Backend ECR repository"
  value       = aws_ecr_repository.backend.repository_url
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.postgres.port
}

output "rds_database_name" {
  description = "Database name"
  value       = aws_db_instance.postgres.db_name
}

output "rds_username" {
  description = "Database username"
  value       = aws_db_instance.postgres.username
}
