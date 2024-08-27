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
  key_name  = "netta-aws-ca-cent-xc"

  tags = {
    Name  = "tgw-spoke-bu1-node-1"
    Owner = "s.iannetta@f5.com"
  }

}
// Sends your public key to the instance
# resource "aws_key_pair" "aws-tgw-key-pair" {
#   key_name   = "aws-tgw-key-pair"
#   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIths+oieeZLnASfZHDRxd7FeipnbenmZDyaDp5SkYI795uGMK02PUvaqiI4ZY//ORkUDUdSLsiYa+BAgLDuWN0Ny+LJbxTtvrLJb62qIVRG5cEIAGRzpYzwNREheELGleCkU4fu7yqJJ9glczFlS12mZRaKENKqy5XaD9tNwa1Qb5kaJ5QuX0R83fuxuy1klJGLzFIm4TMKDEnhNWQj3lcsSu+V2DTGlq4f72ndGxoOFR6oZNVRWHoiLby7JB3ac2AlZ9R4/r+cb+xWhto2b2tBh4NpRi7BGg4YPWKuK1KCXmZL5dXNfxFJ2pGL3gKclsOurcStKKNUorRb8ch4LPB2d3ug4g+mFc/KpUMW3pi5tZqeGP+nfYZDGxLdYOFC7CbUf8prMz7QqE5itY5a5IGyJxCcnaY9atMgnsI45E0nL9W29UQFtNaBkQddfosSqd0tnjQC8eCR5ss4BAqXd8qMBZhlJYZZok89+dFCN7nZncGmTooEktVAJ9HKkCXBk= generated-by-azure"
# }