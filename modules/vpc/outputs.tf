output "subnet_id1" {
  value = aws_subnet.Sub1.id
}

output "subnet_id2" {
  value = aws_subnet.Sub2.id
}

output "subnet_id3" {
  value = aws_subnet.Sub3.id
}

output "subnet_id4" {
  value = aws_subnet.Sub4.id
}

output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}

output "web_alb_sg_id" {
  value = aws_security_group.web_alb_sg.id
}

output "asg_template_id" {
  value = aws_launch_configuration.web_asg.id
}

output "backend_web_id" {
  value = aws_security_group.backend_web.id
}

output "alb_id" {
  value = aws_lb.web_alb.id
}

output "alb_arn" {
  value = aws_lb.web_alb.arn
}