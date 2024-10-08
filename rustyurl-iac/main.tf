provider "aws" {
  region = var.aws_region
}

# Data Source to Check for Existing DynamoDB Table
data "aws_dynamodb_table" "existing_url_shortener" {
  name = var.dynamodb_table_name
}

# Data Source to Check for Existing Security Group
data "aws_security_group" "existing_rustyurl_sg" {
  filter {
    name   = "group-name"
    values = ["rustyurl-sg"]
  }
}

# DynamoDB Table for URL Shortener
resource "aws_dynamodb_table" "url_shortener" {
  count          = length(data.aws_dynamodb_table.existing_url_shortener.id) == 0 ? 1 : 0
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "short_url"

  attribute {
    name = "short_url"
    type = "S"
  }

  tags = {
    Name = "RustyURLTable"
  }
}

# Security Group for EC2 Instance (only create if it does not already exist)
resource "aws_security_group" "rustyurl_sg" {
  count = length(data.aws_security_group.existing_rustyurl_sg.id) == 0 ? 1 : 0

  name        = "rustyurl-sg"
  description = "Security group for RustyURL EC2 instance"

  # Allow inbound traffic on port 8080 for the URL shortener application
  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound SSH access on port 22
  ingress {
    description = "Allow SSH traffic on port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RustyURL-SG"
  }
}

# EC2 Instance to Run Rust Backend
resource "aws_instance" "rustyurl_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = length(aws_security_group.rustyurl_sg) > 0 ? [aws_security_group.rustyurl_sg[0].id] : []
  key_name               = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install docker -y
              sudo service docker start
              aws ecr get-login-password --region ${var.aws_region} | sudo docker login --username AWS --password-stdin ${aws_ecr_repository.rustyurl_backend.repository_url}
              sudo docker pull ${aws_ecr_repository.rustyurl_backend.repository_url}:latest
              sudo docker run -d -p ${var.app_port}:${var.app_port} ${aws_ecr_repository.rustyurl_backend.repository_url}:latest
              EOF

  tags = {
    Name = "RustyURL-Instance"
  }
}

# ECR Repository for Docker Images
resource "aws_ecr_repository" "rustyurl_backend" {
  name = "rustyurl-backend"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "RustyURL ECR Repository"
  }
}
