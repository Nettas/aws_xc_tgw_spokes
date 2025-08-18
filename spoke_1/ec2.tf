resource "aws_instance" "bu1-web" {
  ami           = var.ami
  instance_type = "t2.micro"
  # VPC
  subnet_id = aws_subnet.private-vpc-bu1.id

  vpc_security_group_ids = [aws_security_group.allow_all.id]
  # aws_security_group = aws_security_group.ssh_allowed.id
  # Security Group
  # security_groups = aws_security_group.ssh_allowed.id
  # the Public SSH key
  # key_name  = "netta-aws-east2-xc-account"
  key_name  = "netta-aws-east2-xc-account"

  tags = {
    Name  = "tgw-spoke-bu1-node-1"
    Owner = "s.iannetta@f5.com"
  }

}
