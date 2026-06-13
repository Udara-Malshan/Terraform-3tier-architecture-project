# Create VPC
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "3tier-vpc"
  }
}

# Create public subnet a
resource "aws_subnet" "public_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-subnet-a"
  }
}

# Create public subnet b (in another AZ)
resource "aws_subnet" "public_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-subnet-b"
  }
}

# Careate Private Subnet a
resource "aws_subnet" "private_app_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private-app-a"
  }
}

# Create Private Subnet b
resource "aws_subnet" "private_app_b" {

  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.12.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-app-b"
  }
}

# Create DB Subnet a
resource "aws_subnet" "private_db_a" {

  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.21.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-db-a"
  }
}

# Create DB Subnet b
resource "aws_subnet" "private_db_b" {

  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.22.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-db-b"
  }
}

# Create IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Create Public Route table (for IGW)
resource "aws_route_table" "public_rt" {
  
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Associate Public Subnet a to IGW
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

# Associate Public subnet b to IGW
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Create Private-rt
resource "aws_route_table" "private_rt" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-rt"
  }
}

# Associate Private Subnets to private rt
resource "aws_route_table_association" "private_app_a" {
  subnet_id      = aws_subnet.private_app_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "public_app_b" {
  subnet_id      = aws_subnet.private_app_b.id
  route_table_id = aws_route_table.private_rt.id
}

# Associate DB subnets also to private rt
resource "aws_route_table_association" "private_db_a" {
  subnet_id      = aws_subnet.private_db_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_db_b" {
  subnet_id      = aws_subnet.private_db_b.id
  route_table_id = aws_route_table.private_rt.id
}

# Create EIP for NAT gateway
resource "aws_eip" "nat" {
  domain   = "vpc"

  tags = {
    Name = "nat-eip"
  }
}

# Create NAT gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "main-NAT"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Add route to Private rt for NGW (0.0.0.0/0 -> NAT Gateway)
resource "aws_route" "private_default" {

  route_table_id = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.main.id
}