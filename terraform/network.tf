
# Data sources to retrieve VPC and subnet
data "aws_vpc" "selected" {
  id      = var.vpc_id != "" ? var.vpc_id : null
  default = var.vpc_id == "" ? true : null
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  # Try to find public subnets (ones with map_public_ip_on_launch enabled)
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

# Use the first available public subnet, or fallback to any subnet if no public ones found
data "aws_subnet" "selected" {
  id = var.subnet_id != "" ? var.subnet_id : (
    length(data.aws_subnets.public.ids) > 0 ? data.aws_subnets.public.ids[0] : null
  )
}


# Security group for EC2 instance
resource "aws_security_group" "impostor_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for Impostor game server"
  vpc_id      = data.aws_vpc.selected.id

  # HTTP access from anywhere (for Let's Encrypt validation and HTTP redirect)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere (optional)
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access
  #ingress {
  #  description = "SSH"
  #  from_port   = 22
  #  to_port     = 22
  #  protocol    = "tcp"
  #  cidr_blocks = var.allowed_ssh_cidr_blocks
  #}

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name} Security Group"
    Environment = var.environment
  }
}

# Elastic IP for stable public IP
resource "aws_eip" "impostor_eip" {
  count    = var.use_elastic_ip ? 1 : 0
  instance = aws_instance.impostor_server.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name} EIP"
    Environment = var.environment
  }
}