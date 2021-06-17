variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc-cidr" {
  type = string
  default = "10.1.0.0/16"
}

variable "sub1-cidr" {
  type = string
  default = "10.1.0.0/24"
}

variable "sub2-cidr" {
  type = string
  default = "10.1.1.0/24"
}

variable "sub3-cidr" {
  type = string
  default = "10.1.2.0/24"
}

variable "sub4-cidr" {
  type = string
  default = "10.1.3.0/24"
}

variable "az1" {
  type = string
  default = "us-east-1a"
}

variable "az2" {
  type = string
  default = "us-east-1b"
}

variable "key-pair" {
  type = string
  default = "newkp1"
}