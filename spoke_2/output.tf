output "aws_vpc" {
  description = "Spoke 2 (BU2) VPC ID"
  value       = aws_vpc.bu2.id
}

output "private_subnet_id" {
  description = "Spoke 2 (BU2) private subnet ID — used for TGW attachment"
  value       = aws_subnet.private-vpc-bu2.id
}
