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
  description = "The name of the DynamoDB table used for the URL shortener."
  value       = length(aws_dynamodb_table.url_shortener) > 0 ? aws_dynamodb_table.url_shortener[0].name : data.aws_dynamodb_table.existing_url_shortener.name
}

output "security_group_id" {
  value = length(aws_security_group.rustyurl_sg) > 0 ? aws_security_group.rustyurl_sg[0].id : data.aws_security_group.existing_rustyurl_sg.id
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance running the RustyURL backend"
  value       = aws_instance.rustyurl_instance.id
}
