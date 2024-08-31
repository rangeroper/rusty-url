provider "aws" {
  region = var.aws_region
}

# DynamoDB Table for URL Shortener
resource "aws_dynamodb_table" "url_shortener" {
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

# Security Group for EC2 Instance
resource "aws_security_group" "rustyurl_sg" {
  name        = "rustyurl-sg"
  description = "Security group for RustyURL EC2 instance"

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance to Run Rust Backend
resource "aws_instance" "rustyurl_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.rustyurl_sg.id]
  key_name               = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install docker.io -y
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
