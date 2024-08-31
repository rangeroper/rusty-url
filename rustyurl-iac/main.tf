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

# IAM Policy for EC2 to access ECR
resource "aws_iam_policy" "ecr_policy" {
  name        = "RustyURL_ECR_Policy"
  description = "Policy to allow EC2 instance to access ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "RustyURL_EC2_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

# IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "RustyURL_EC2_Instance_Profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance to Run Rust Backend
resource "aws_instance" "rustyurl_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.rustyurl_sg.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

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
