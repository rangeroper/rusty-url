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

# Data Source to Check for Existing Security Group
data "aws_security_group" "existing_rustyurl_sg" {
  filter {
    name   = "group-name"
    values = ["rustyurl-sg"]
  }
}

# Security Group for EC2 Instance
resource "aws_security_group" "rustyurl_sg" {
  count       = length(data.aws_security_group.existing_rustyurl_sg.ids) == 0 ? 1 : 0
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
}
