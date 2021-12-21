terraform {
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
  region  = "us-west-2"
}

resource "aws_instance" "app_server" {
  ami                         = "${data.aws_ami.amazon-linux-2.id}"
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  key_name                    = "simon-green-uswest2"

  tags = {
    Name = "SimonGreen_AmznLinux2"
  }
}

output "arn" {
  description = "ARN of the server"
  value = aws_instance.app_server.arn

}

output "server_name" {
  description = "Name (id) of the server"
  value = aws_instance.app_server.id
}

output "public_ip" {
  description = "Public IP of the server"
  value = aws_instance.app_server.public_ip
}

data "aws_ami" "amazon-linux-2" {
 most_recent = true
 owners = ["amazon"]

 filter {
   name   = "owner-alias"
   values = ["amazon"]
 }


 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}