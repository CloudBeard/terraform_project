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
  ebs_block_device {
    device_name = "dev/sda1"
    volume_size = 20
  }

resource "aws_"
}