# This file was used to setup the S3 bucket and DynamoDB table for Terraform state management. 
# It has been removed to avoid accidentally destroying these critical resources.

# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "cypress-studios-terraform-state"

#   tags = {
#     Name        = "Terraform State"
#     Environment = "infrastructure"
#   }
# }

# resource "aws_s3_bucket_versioning" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# resource "aws_s3_bucket_public_access_block" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# # DynamoDB table for state locking
# resource "aws_dynamodb_table" "terraform_locks" {
#   name         = "terraform-state-lock"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"

#   attribute {
#     name = "LockID"
#     type = "S"
#   }

#   tags = {
#     Name        = "Terraform State Lock"
#     Environment = "infrastructure"
#   }
# }

# output "terraform_state_bucket" {
#   value = aws_s3_bucket.terraform_state.id
# }

# output "terraform_lock_table" {
#   value = aws_dynamodb_table.terraform_locks.id
# }


removed {
  from = aws_s3_bucket.terraform_state

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_s3_bucket_versioning.terraform_state

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_s3_bucket_server_side_encryption_configuration.terraform_state

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_s3_bucket_public_access_block.terraform_state

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_dynamodb_table.terraform_locks

  lifecycle {
    destroy = false
  }

}