provider "aws" {
  region = var.aws_region
}

# Data Source to Check for Existing DynamoDB Table
data "aws_dynamodb_table" "existing_url_shortener" {
  name = var.dynamodb_table_name
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

# Always create the Security Group for EC2 Instance
resource "aws_security_group" "rustyurl_sg" {
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
  vpc_security_group_ids = [aws_security_group.rustyurl_sg.id]
  key_name               = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install docker -y
              sudo service docker start
              sudo yum install -y aws-cli
              
              # Configure AWS CLI with static credentials
              mkdir -p ~/.aws
              echo "[default]" > ~/.aws/credentials
              echo "aws_access_key_id=${AWS_ACCESS_KEY_ID}" >> ~/.aws/credentials
              echo "aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}" >> ~/.aws/credentials
              echo "[default]" > ~/.aws/config
              echo "region=${var.aws_region}" >> ~/.aws/config
              
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
