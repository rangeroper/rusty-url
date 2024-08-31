output "dynamodb_table_name" {
  description = "The name of the DynamoDB table for URL shortener"
  value       = aws_dynamodb_table.url_shortener[0].name
  condition   = length(aws_dynamodb_table.url_shortener) > 0
}

output "security_group_id" {
  description = "The ID of the security group for the RustyURL EC2 instance"
  value       = aws_security_group.rustyurl_sg.id
}

output "ec2_instance_id" {
  description = "The ID of the EC2 instance running the Rust backend"
  value       = aws_instance.rustyurl_instance.id
}

output "instance_public_ip" {
  description = "The public IP of the EC2 instance running the Rust backend"
  value       = aws_instance.rustyurl_instance.public_ip
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository for Docker images"
  value       = aws_ecr_repository.rustyurl_backend.repository_url
}
