variable "s3_bucket_name" {
  type = string
  default =  "cloudbeard-prod"
}

variable "s3_folder1_name" {
  type = string
  default =  "images/"
}

variable "s3_folder2_name" {
  type = string
  default =  "logs/"
}

variable "main_region" {
  type    = string
  default = "us-east-1"
}