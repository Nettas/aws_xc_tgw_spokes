output "aws_vpc" {
  description = "Spoke 1 (BU1) VPC ID"
  value       = aws_vpc.bu1.id
}

output "private_subnet_id" {
  description = "Spoke 1 (BU1) private subnet ID — used for TGW attachment"
  value       = aws_subnet.private-vpc-bu1.id
}
