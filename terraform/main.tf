# TLS private key for SSH (if creating new key pair)
resource "tls_private_key" "ssh_key" {
  count     = var.create_key_pair ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# AWS key pair (create new or use existing)
resource "aws_key_pair" "impostor_key" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = var.key_pair_name != "" ? var.key_pair_name : "${var.project_name}-key"
  public_key = tls_private_key.ssh_key[0].public_key_openssh

  tags = {
    Name        = "${var.project_name} SSH Key"
    Environment = var.environment
  }
}

# Save private key to local file (if creating new key pair)
resource "local_file" "private_key" {
  count           = var.create_key_pair ? 1 : 0
  content         = tls_private_key.ssh_key[0].private_key_pem
  filename        = "${path.module}/${var.key_pair_name != "" ? var.key_pair_name : "${var.project_name}-key"}.pem"
  file_permission = "0400"
}

# IAM role for EC2 instance
resource "aws_iam_role" "impostor_ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name} EC2 Role"
    Environment = var.environment
  }
}

# IAM policy to allow S3 read access
resource "aws_iam_role_policy" "impostor_s3_policy" {
  name = "${var.project_name}-s3-policy"
  role = aws_iam_role.impostor_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.impostor_artifacts.arn,
          "${aws_s3_bucket.impostor_artifacts.arn}/*"
        ]
      }
    ]
  })
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "impostor_profile" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.impostor_ec2_role.name
}

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 instance
resource "aws_instance" "impostor_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.selected.id
  vpc_security_group_ids = [aws_security_group.impostor_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.impostor_profile.name
  key_name               = var.create_key_pair ? aws_key_pair.impostor_key[0].key_name : var.key_pair_name

  user_data = templatefile("${path.module}/user_data.sh", {
    s3_bucket = aws_s3_bucket.impostor_artifacts.id
    port      = var.app_port
    domain    = var.domain_name
  })

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name        = "${var.project_name} Server"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

