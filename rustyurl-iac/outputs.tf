# outputs.tf

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.rustyurl_backend.repository_url
}

output "instance_public_ip" {
  description = "Public IP address of the RustyURL EC2 instance"
  value       = aws_instance.rustyurl_instance.public_ip
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.url_shortener.name
}

output "security_group_id" {
  description = "Security Group ID of the RustyURL instance"
  value       = aws_security_group.rustyurl_sg.id
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance running the RustyURL backend"
  value       = aws_instance.rustyurl_instance.id
}
