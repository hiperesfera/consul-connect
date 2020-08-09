# create the VPC
resource "aws_vpc" "public" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

}

# create the Public Subnet
resource "aws_subnet" "consult_connect_subnet_public" {
  vpc_id                  = aws_vpc.public.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       =  var.availabilityZone
}

# create the Private Subnet
resource "aws_subnet" "consult_connect_subnet_private" {
  vpc_id                  = aws_vpc.public.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = var.availabilityZone
}


# create the Public Route Table
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.public.id
}


# create the Private Route Table
resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.public.id
}


# create the Internet Gateway
resource "aws_internet_gateway" "consult_connect_igw" {
  vpc_id = aws_vpc.public.id
}


# create EIP + NAT instance for consult_connect Private Subnet
resource "aws_eip" "nat" {
   vpc      = true
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.consult_connect_subnet_public.id
  depends_on = [aws_internet_gateway.consult_connect_igw]
}


# create the Internet Access route in the Public routing table
resource "aws_route" "internet" {
  route_table_id        = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.consult_connect_igw.id
}


# create the Internet Access route in the Private routing table - NAT GW
resource "aws_route" "nat_gw" {
  route_table_id           = aws_route_table.private_route_table.id
  destination_cidr_block   = "0.0.0.0/0"
  nat_gateway_id           = aws_nat_gateway.nat_gw.id
}


# associate the Route Table with the Public Subnet
resource "aws_route_table_association" "route_table_association_public" {
  subnet_id      = aws_subnet.consult_connect_subnet_public.id
  route_table_id = aws_route_table.public_route_table.id
}


# associate the Route Table with the Private Subnet
resource "aws_route_table_association" "route_table_association_private" {
  subnet_id      = aws_subnet.consult_connect_subnet_private.id
  route_table_id = aws_route_table.private_route_table.id
}
