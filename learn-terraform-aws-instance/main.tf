terraform {

  cloud {
    organization = "DevopsOrg"
    workspaces {
      name = "Example-Workspace"
    }
  }


  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "ap-southeast-2"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0916f5ee07e7b15d6"
  instance_type = "t2.micro"
  key_name= "id_rsa"
  vpc_security_group_ids = [aws_security_group.main.id]

  tags = {
    Name = var.instance_name
  }
  

}
resource "aws_security_group" "main" {
  egress = [
    {
      cidr_blocks      = [ "0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
 ingress                = [
   {
     cidr_blocks      = [ "0.0.0.0/0", ]
     description      = ""
     from_port        = 22
     ipv6_cidr_blocks = []
     prefix_list_ids  = []
     protocol         = "tcp"
     security_groups  = []
     self             = false
     to_port          = 22
  }
  ]
}


resource "aws_key_pair" "deployer" {
  key_name   = "id_rsa"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCvFnC30br6qKEP436KL15dl4fIK1UXP+Pd871KQyDAf62b/mMDjd7vsL5PvTYMA2rTia6i8jqWvvDJmt70Qg1nvZB87ZeZKGniOPJFrRu/K0xNeNYVz+U/UW/z4END/cTvhX6dLcuRMcnMqV4XIKLO6K49ouyfLC4LWwAm9P1l5vwSPtlkCVLy39iEYmSkKED51/jVxvxTM44waOhwBmKLdtgM8t9RkgLeq4R5DnYYvaxLGZDCAa6svWGrWYTksjsva0PKzrUTVjmkms1wuV65rBBIPCDgjpgXkWEKLl0r1TYZAMl+kn7BKrQQHl/nwHM4OP1Cumtnob3c/IFbdAx hpunati@HPUNATI-7420"
}
