resource "aws_instance" "bu2-web" {
  ami           = var.ami
  instance_type = "t2.micro"
  # VPC
  subnet_id = aws_subnet.private-vpc-bu2.id

  vpc_security_group_ids = [aws_security_group.allow_all.id]
  # aws_security_group = aws_security_group.ssh_allowed.id
  # Security Group
  # security_groups = aws_security_group.ssh_allowed.id
  # the Public SSH key
  key_name  = var.key_name
  tags = {
    Name  = "tgw-spoke-bu2-node-1"
    Owner = "s.iannetta@f5.com"
  }

}