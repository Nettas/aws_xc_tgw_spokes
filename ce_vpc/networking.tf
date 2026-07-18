# ==============================================================================
# Single VPC | 2 subnets (SLO + SLI), same AZ
# ==============================================================================

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.site_labels, { Name = var.vpc_name })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.site_labels, { Name = "${var.vpc_name}-igw" })
}

# -- SLO (outside) subnet --
resource "aws_subnet" "outside" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.outside_subnet_cidr
  availability_zone       = var.aws_az
  map_public_ip_on_launch = false # EIP is attached explicitly to the ENI instead

  tags = merge(var.site_labels, { Name = "${var.site_name}-slo" })
}

# -- SLI (inside) subnet --
resource "aws_subnet" "inside" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.inside_subnet_cidr
  availability_zone = var.aws_az

  tags = merge(var.site_labels, { Name = "${var.site_name}-sli" })
}

# -- Route table: SLO subnet gets a default route to the IGW --
resource "aws_route_table" "slo_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.site_labels, { Name = "${var.vpc_name}-slo-rt" })
}

resource "aws_route_table_association" "slo_assoc" {
  subnet_id      = aws_subnet.outside.id
  route_table_id = aws_route_table.slo_rt.id
}
