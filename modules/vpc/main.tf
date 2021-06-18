provider "aws" {
  region = var.region
}

resource "aws_vpc" "us-east-prod" {
  cidr_block = var.vpc-cidr
  tags = {
    Name = "US_East_Prod"
  }
}

resource "aws_subnet" "Sub1" {
  vpc_id     = aws_vpc.us-east-prod.id
  cidr_block = var.sub1-cidr
  availability_zone = var.az1
  tags = {
    Name = "Sub1_Public"
  }
}

resource "aws_subnet" "Sub2" {
  vpc_id     = aws_vpc.us-east-prod.id
  cidr_block = var.sub2-cidr
  availability_zone = var.az2
  tags = {
    Name = "Sub2_Public"
  }
}

resource "aws_subnet" "Sub3" {
  vpc_id     = aws_vpc.us-east-prod.id
  cidr_block = var.sub3-cidr
  availability_zone = var.az1
  tags = {
    Name = "Sub3_Private"
  }
}

resource "aws_subnet" "Sub4" {
  vpc_id     = aws_vpc.us-east-prod.id
  cidr_block = var.sub4-cidr
  availability_zone = var.az2
  tags = {
    Name = "Sub4_Private"
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

  tags = {
    Name = "Private_RouteTable"
  }
}

resource "aws_route_table_association" "private_sub3" {
  subnet_id = aws_subnet.Sub3.id
   route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_sub4" {
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
  vpc_id = aws_vpc.us-east-prod.id

  ingress {
    description = "HTTP port 80 from WebALBSG"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = ["${aws_security_group.web_alb_sg.id}"]
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

resource "aws_lb" "web_alb" {
  name = "web-alb"
  internal = false 
  load_balancer_type = "application"
  security_groups = [aws_security_group.web_alb_sg.id]
  subnets = [
    aws_subnet.Sub1.id,
    aws_subnet.Sub2.id
  ]

  tags = {
    Enviroment = "Prod"
  }
}

resource "aws_lb_target_group" "web_tg" {
  name = "web-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.us-east-prod.id
}

resource "aws_lb_listener" "alb-listner" {
  load_balancer_arn = aws_lb.web_alb.id
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  alb_target_group_arn = aws_lb_target_group.web_tg.arn
}

resource "aws_launch_configuration" "web_asg" {
  name = "webserver"
  image_id = "ami-0b0af3577fe5e3532"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.backend_web.id]
  root_block_device {
    volume_size = 20
  }

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install httpd -y
    systemctl enable httpd
    systemctl start httpd
    echo "<h1>TEST WEB PAGE</h1>" > /var/www/html/index.html
    EOF
}

resource "aws_autoscaling_group" "asg" {
  name = "web-backend-asg"
  max_size = 6
  min_size = 2
  desired_capacity = 2
  health_check_type = "EC2"
  launch_configuration = aws_launch_configuration.web_asg.name
  vpc_zone_identifier = [aws_subnet.Sub4.id]
  target_group_arns = [aws_lb_target_group.web_tg.arn]
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "Sub2_Instance" {
  ami           = "ami-0b0af3577fe5e3532"
  subnet_id     = aws_subnet.Sub2.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name = var.key-pair
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 20
  }
  tags = {
    Name = "Bastion"
  }
}

resource "aws_eip" "sub2_instance_eip" {
  instance = aws_instance.Sub2_Instance.id
  vpc = true
}