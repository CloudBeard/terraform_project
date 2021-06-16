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

output "asg_template_id" {
  value = aws_launch_template.web_asg.id
}