data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "custom" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${var.vpc_name}"
  }
}

resource "aws_subnet" "private" {
  count             = length(data.aws_availability_zones.available.zone_ids)
  vpc_id            = aws_vpc.custom.id
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 1)

  tags = {
    Name                                        = "private-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

resource "aws_subnet" "public" {
  count                   = length(data.aws_availability_zones.available.zone_ids)
  vpc_id                  = aws_vpc.custom.id
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  cidr_block              = cidrsubnet(var.vpc_cidr, 12, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "public-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_internet_gateway" "custom_igw" {
  vpc_id = aws_vpc.custom.id

  tags = {
    Name = "IGW"
  }
}

resource "aws_route_table" "public_routes" {
  vpc_id = aws_vpc.custom.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.custom_igw.id
  }

  tags = {
    Name = "Public"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public.*.id)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_routes.id
}

resource "aws_eip" "nat_ips" {
  count = var.nat_count
  vpc   = true

  tags = {
    Name = "NAT-EIP-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "custom_nat" {
  count         = var.nat_count
  allocation_id = aws_eip.nat_ips[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "NAT-${count.index + 1}"
  }
}

resource "aws_route_table" "private_routes" {
  count      = length(aws_subnet.private.*.id)
  vpc_id     = aws_vpc.custom.id
  depends_on = [aws_nat_gateway.custom_nat]

  tags = {
    Name = "Private-${count.index + 1}"
  }
}

resource "aws_route" "private" {
  count                  = length(aws_subnet.private.*.id)
  route_table_id         = aws_route_table.private_routes[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.custom_nat.*.id, count.index)
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private.*.id)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_routes[count.index].id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.custom.id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  tags = {
    Environment = "${var.environment}"
  }
}

resource "aws_vpc_endpoint_route_table_association" "this" {
  count           = length(aws_subnet.private.*.id)
  route_table_id  = aws_route_table.private_routes[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}