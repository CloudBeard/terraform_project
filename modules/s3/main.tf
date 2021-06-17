provider "aws" {
  region = var.main_region
}

resource "aws_s3_bucket" "prod_s3_bucket" {
  bucket = var.s3_bucket_name
  acl = "private"

  lifecycle_rule {
    id = "iamges"
    enabled = true

    transition {
      days = 90
      storage_class = "GLACIER"
    }
  }

  lifecycle_rule {
    id = "logs"
    enabled = true

    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_object" "images_folder" {
  bucket = aws_s3_bucket.prod_s3_bucket.id
  acl = "private"
  key = var.s3_folder1_name
  source = "/dev/null"
}

resource "aws_s3_bucket_object" "logs_folder" {
  bucket = aws_s3_bucket.prod_s3_bucket.id
  acl = "private"
  key = var.s3_folder2_name
  source = "/dev/null"
}