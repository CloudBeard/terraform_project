variable "main_region" {
  type    = string
  default = "us-east-1"
}

provider "aws" {
  region = var.main_region
}

module "vpc" {
  source = "./modules/vpc"
  region = var.main_region
}

resource "aws_instance" "Sub2_Instance" {
  ami           = "ami-0b0af3577fe5e3532"
  subnet_id     = module.vpc.subnet_id2
  instance_type = "t2.micro"
  vpc_security_group_ids = [module.vpc.bastion_sg_id]
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 20
  }
  tags = {
    Name = "Bastion"
  }
}

resource "aws_autoscaling_group" "asg" {
  name = "web-backend-asg"
  max_size = 6
  min_size = 2
  desired_capacity = 2
  launch_configuration = module.vpc.asg_template_id
  tags = {
    Name = "webASG"
  }
}