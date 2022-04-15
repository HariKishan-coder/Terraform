provider "aws" {
  profile = "default"
  region  = "ap-southeast-2"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0916f5ee07e7b15d6"
  instance_type = "t2.micro"
  key_name= "id_rsa"
  vpc_security_group_ids = [aws_security_group.main.id]
  user_data       = data.template_file.user_data.rendered


  tags = {
    Name = "terraform-example"
  }


}


data "template_file" "user_data" {

  template = file("userdata.sh")

  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = "9144sayterraformremotestate9144"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "ap-southeast-2"
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
    },
    {
      cidr_blocks      = [ "0.0.0.0/0", ]
      description      = "http from vpc"
      from_port        = var.server_port
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = var.server_port
    }
  ]
}

data "aws_vpc" "default"{
  default = true
}


data aws_subnet_ids "default"{
  vpc_id = data.aws_vpc.default.id
}

resource "aws_lb" "AppLB"{
  name = "terraform-alb-example"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.AppLBSG.id]
}

resource aws_security_group "AppLBSG"{

  ingress                = [
    {
      from_port        = 80
      protocol         = "tcp"
      to_port          = 80
      cidr_blocks = ["0.0.0.0/0"]
      description = "Ingress rules for application load balancer"
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false

    }]
    # Allow all outbound requests
    egress = [{
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "outbound rules for application load balancer"
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    }]
}

resource aws_lb_listener "AppLBListener"{
  load_balancer_arn = aws_lb.AppLB.arn
  port = var.server_port
  protocol = "HTTP"
  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource aws_lb_listener_rule "AppLBListenerRule"{
  listener_arn = aws_lb_listener.AppLBListener.arn
  priority = 100

  condition{
    path_pattern {
      values = ["*"]
    }

  }
  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.AppLBListenerTG.arn
  }
}

resource aws_alb_target_group "AppLBListenerTG"{
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval= 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }

}

resource aws_launch_configuration "launchconfig"{
  image_id = "ami-0916f5ee07e7b15d6"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.main.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd.x86_64
              systemctl start httpd.service
              systemctl enable httpd.service
              echo “Hello World from $(hostname -f)” > /var/www/html/index.html
              EOF

  # Required when using a launch configuration with an auto scaling group.
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle {
    create_before_destroy = true
  }
}

resource aws_autoscaling_group "asg"{
  launch_configuration = aws_launch_configuration.launchconfig.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids
  target_group_arns = [aws_alb_target_group.AppLBListenerTG.arn]

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }

}


terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "9144sayterraformremotestate9144"
    key            = "stage/services/webserver-cluster/terraform.tfstate"
    region         = "ap-southeast-2"

    # Replace this with your DynamoDB table name!
    dynamodb_table = "9144sayterraformRemotestate9144-locks"
    encrypt        = true
  }
}