resource "aws_internet_gateway" "bu2-igw" {
  vpc_id = aws_vpc.bu2.id
  tags = {
      Name = "bu2-igw"
  }
}

resource "aws_route_table" "prod-public-crt" {
  vpc_id = aws_vpc.bu2.id

  route {
    //associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0"
    //CRT uses this IGW to reach internet
    gateway_id = aws_internet_gateway.bu2-igw.id
  }

  # tags {
  #     Name = "bu1-public-2-igw"
  # }
}

resource "aws_route_table_association" "prod-crta-public-sub" {
  subnet_id      = aws_subnet.private-vpc-bu2.id
  route_table_id = aws_route_table.prod-public-crt.id
}