provider "aws" {
  region = "ap-southeast-2"

}

resource "aws_db_instance" "example" {
  identifier_prefix   = "terraform-up-and-running"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t2.micro"
  db_name                = "SqlDB9144"
  username            = "admin"
  skip_final_snapshot       = "true"

  # How should we set the password?
  password            = var.db_password
}


terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "9144sayterraformremotestate9144"
    key            = "stage/data-stores/mysql/terraform.tfstate"
    region         = "ap-southeast-2"

    # Replace this with your DynamoDB table name!
    dynamodb_table = "9144sayterraformRemotestate9144-locks"
    encrypt        = true
  }
}