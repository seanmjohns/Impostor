output "vpc_id" {
  description = "VPC ID being used"
  value       = data.aws_vpc.selected.id
}

output "subnet_id" {
  description = "Subnet ID being used"
  value       = data.aws_subnet.selected.id
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket containing artifacts"
  value       = aws_s3_bucket.impostor_artifacts.id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.impostor_server.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = var.use_elastic_ip ? aws_eip.impostor_eip[0].public_ip : aws_instance.impostor_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.impostor_server.public_dns
}

output "game_url" {
  description = "URL to access the game"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${var.use_elastic_ip ? aws_eip.impostor_eip[0].public_ip : aws_instance.impostor_server.public_ip}:${var.app_port}"
}

output "ssh_key_name" {
  description = "Name of the SSH key pair"
  value       = var.create_key_pair ? aws_key_pair.impostor_key[0].key_name : var.key_pair_name
}

output "ssh_private_key_path" {
  description = "Path to the private key file (if created by Terraform)"
  value       = var.create_key_pair ? abspath(local_file.private_key[0].filename) : "Using existing key: ${var.key_pair_name}"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = var.create_key_pair ? "ssh -i ${abspath(local_file.private_key[0].filename)} ec2-user@${var.use_elastic_ip ? aws_eip.impostor_eip[0].public_ip : aws_instance.impostor_server.public_ip}" : "ssh -i /path/to/${var.key_pair_name}.pem ec2-user@${var.use_elastic_ip ? aws_eip.impostor_eip[0].public_ip : aws_instance.impostor_server.public_ip}"
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.impostor_sg.id
}
