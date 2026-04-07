variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "impostor-game"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for artifacts (must be globally unique)"
  type        = string
  default     = "cypress-studios"
}

variable "vpc_id" {
  description = "VPC ID where the EC2 instance will be deployed (leave empty to use default VPC)"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Subnet ID where the EC2 instance will be deployed (leave empty to auto-select public subnet)"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t4g.nano"
}

variable "key_pair_name" {
  description = "Name of existing EC2 key pair (leave empty to create new one)"
  type        = string
  default     = ""
}

variable "create_key_pair" {
  description = "Whether to create a new key pair (true) or use existing one (false)"
  type        = bool
  default     = false
}

variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH into the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Restrict this in production!
}

variable "app_port" {
  description = "Port on which the application will run"
  type        = number
  default     = 8080
}

variable "domain_name" {
  description = "Domain name for Let's Encrypt SSL certificate (e.g., game.example.com). Leave empty to use HTTP only."
  type        = string
  default     = "cypress-studios.net"
}

variable "use_elastic_ip" {
  description = "Whether to attach an Elastic IP to the instance"
  type        = bool
  default     = true
}
