# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources to"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The EC2 instance type"
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance (64-bit x86)"
  default     = "ami-02c21308fed24a8ab"  # Use this for x86-based instances
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for URL shortener"
  default     = "UrlShortener"
}

variable "app_port" {
  description = "The port on which the Rust application will run"
  default     = 8080
}

variable "key_name" {
  description = "The name of the SSH key pair to use for EC2 instance"
  default     = "rustyurl"  # Replace with your EC2 key pair name, if you have one
}

variable "ecr_repository_name" {
  description = "The name of the ECR repository to store the Docker image"
  default     = "rustyurl-backend"  # Default repository name for Docker images
}