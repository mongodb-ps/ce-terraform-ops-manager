# VPC resources created only when aws_config.vpc_id/subnet_id are not provided.
# By validation in variables.tf they are either both set or both null.

resource "aws_vpc" "om" {
  count = var.aws_config.vpc_id == null ? 1 : 0

  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, {
    Name = "om-vpc"
  })
}

resource "aws_subnet" "om" {
  count = var.aws_config.subnet_id == null ? 1 : 0

  vpc_id                  = aws_vpc.om[0].id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "${var.aws_config.region}a"
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "om-subnet"
  })
}

resource "aws_internet_gateway" "om" {
  count = var.aws_config.vpc_id == null ? 1 : 0

  vpc_id = aws_vpc.om[0].id

  tags = merge(local.tags, {
    Name = "om-igw"
  })
}

resource "aws_route_table" "om" {
  count = var.aws_config.vpc_id == null ? 1 : 0

  vpc_id = aws_vpc.om[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.om[0].id
  }

  tags = merge(local.tags, {
    Name = "om-rt"
  })
}

resource "aws_route_table_association" "om" {
  count = var.aws_config.subnet_id == null ? 1 : 0

  subnet_id      = aws_subnet.om[0].id
  route_table_id = aws_route_table.om[0].id
}
