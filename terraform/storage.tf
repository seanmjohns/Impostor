# S3 bucket for storing the application artifacts
resource "aws_s3_bucket" "impostor_artifacts" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = "Impostor Game Artifacts"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "impostor_artifacts" {
  bucket = aws_s3_bucket.impostor_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}