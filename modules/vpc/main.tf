provider "aws" {
  region = var.region
}

resource "aws_vpc" "us-east-prod" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "US_East_Prod"
  }
}

resource "aws_subnet" "Sub1" {
  vpc_id     = aws_vpc.us-east-prod.id
  cidr_block = "10.1.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Sub1_Public"
  }
}

resource "aws_subnet" "Sub2" {
  vpc_id     = aws_vpc.us-east-prod.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "Sub2_Public"
  }
}

resource "aws_subnet" "Sub3" {
  vpc_id     = aws_vpc.us-east-prod.id
  cidr_block = "10.1.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Sub3_Private"
  }
}

resource "aws_subnet" "Sub4" {
  vpc_id     = aws_vpc.us-east-prod.id
  cidr_block = "10.1.3.0/24"
  availability_zone = "us-east-1b"
  tags = {
    "Sub4_Private"
  }
}

resource "aws_internet_gateway" "us_east_prod" {
  vpc_id = aws_vpc.us-east-prod.id
  tags = {
    Name = "IGW"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.us-east-prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.us_east_prod.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.us_east_prod.id
  }

    tags = {
    Name = "Public_RouteTable"
  }
}

resource "aws_route_table_association" "public_sub1" {
  subnet_id = aws_subnet.Sub1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_sub2" {
  subnet_id = aws_subnet.Sub2.id
   route_table_id = aws_route_table.public_rt.id
}

resource "aws_eip" "eip" {
  vpc = true
  tags = {
    Name = "NatGW-eip"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id = aws_subnet.Sub1.id
  tags = {
    Name = "NatGW"
  }

  depends_on = [
    aws_eip.eip
  ]

}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.us-east-prod.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "Private_RouteTable"
  }
}

resource "aws_route_table_association" "public_sub3" {
  subnet_id = aws_subnet.Sub3.id
   route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "public_sub4" {
  subnet_id = aws_subnet.Sub4.id
   route_table_id = aws_route_table.private_rt.id
}

resource "aws_security_group" "web_alb_sg" {
  name = "http_access_from_internet"
  description = "Allows HTTP Access From Internet"
  vpc_id = aws_vpc.us-east-prod.id

  ingress {
    description = "HTTP port 80 from internet"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "WebALBSG"
  }
}

resource "aws_security_group" "bastion_sg" {
  name = "ssh_access_from_internet"
  description = "Allows SSH access from internet"
  vpc_id = aws_vpc.us-east-prod.id

  ingress {
    description = "SSH port 22 from internet"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "BastionSG"
  }
} 

resource "aws_security_group" "backend_web" {
  name = "backend_web"
  description = "Allows HTTP on port 80 from WebALBSG"
  vpc_id = aws_vpc.us_east_prod.id

  ingress {
    description = "HTTP port 80 from WebALBSG"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = aws_security_group.web_alb_sg.id
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "BackendWebSG"
  }
}

resource "aws_launch_template" "web_asg" {
    name = "web_asg"
    image_id = "ami-0b0af3577fe5e3532"
    instance_type = "t2.micro"
    block_device_mappings {
      device_name = "/dev/sda1"
      ebs{
        volume_size = 20
      }
    }
    placement {
      availability_zone = "us-east-1b"
    }
    vpc_security_group_ids = aws_security_group.backend_web.id
    user_data = <<-EOF
    #!//bin/bash -ex
    dnf update -y
    dnf install httpd
    systemctl enable httpd
    systemctl start httpd
    echo "<h1>TEST WEB PAGE</h1>" > /var/www/html/index.html
    EOF

    tags = {
      Name = "webASG"
    }
  }