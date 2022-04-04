provider "aws" {
  region = "ap-southeast--2"
}

resource "aws_instance" "example" {
  ami           = "ami-0916f5ee07e7b15d6"
  instance_type = "t2.micro"

  tags = {
    Name = "terraform-example"
  }
}
