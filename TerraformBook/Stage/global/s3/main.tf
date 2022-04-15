provider "aws" {
  profile = "default"
  region  = "ap-southeast-2"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "9144sayterraformremotestate9144"

  # Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = true
  }

  # Enable versioning so we can see the full revision history of our
  # state files
  versioning {
    enabled = true
  }

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "9144sayterraformRemotestate9144-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}


terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "9144sayterraformremotestate9144"
    key            = "global/s3/terraform.tfstate"
    region         = "ap-southeast-2"

    # Replace this with your DynamoDB table name!
    dynamodb_table = "9144sayterraformRemotestate9144-locks"
    encrypt        = true
  }
}