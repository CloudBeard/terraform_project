provider "aws" {
  region = var.region
}

resource "aws_vpc" "us-east" {
  cidr_block = "10.1.0.0/16"
}

resource "aws_subnet" "Sub1" {
  vpc_id     = aws_vpc.us-east
  cidr_block = "10.1.0.0/24"
  availability_zone = "1a"
}

resource "aws_subnet" "Sub2" {
  vpc_id     = aws_vpc.us-east
  cidr_block = "10.1.1.0/24"
  availability_zone = "1b"
}

resource "aws_subnet" "Sub3" {
  vpc_id     = aws_vpc.us-east
  cidr_block = "10.1.2.0/24"
  availability_zone = "1a"
}

resource "aws_subnet" "Sub4" {
  vpc_id     = aws_vpc.us-east
  cidr_block = "10.1.3.0/24"
  availability_zone = "1b"
}

data "aws_ssm_parameter" "this" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}