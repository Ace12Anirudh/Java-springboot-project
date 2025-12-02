
# Public subnets
resource "aws_subnet" "public" {
  for_each = toset(var.azs)
  vpc_id = var.vpc_id
  availability_zone = each.key
  cidr_block = element(var.public_cidrs, index(var.azs, each.key))
  map_public_ip_on_launch = true
  tags = merge(var.tags, { Name = "${each.key}-public" })
}

# Private app subnets
resource "aws_subnet" "private_app" {
  for_each = toset(var.azs)
  vpc_id = var.vpc_id
  availability_zone = each.key
  cidr_block = element(var.private_cidrs["app"], index(var.azs, each.key))
  map_public_ip_on_launch = false
  tags = merge(var.tags, { Name = "${each.key}-private-app" })
}

# Private db subnets
resource "aws_subnet" "private_db" {
  for_each = toset(var.azs)
  vpc_id = var.vpc_id
  availability_zone = each.key
  cidr_block = element(var.private_cidrs["db"], index(var.azs, each.key))
  map_public_ip_on_launch = false
  tags = merge(var.tags, { Name = "${each.key}-private-db" })
}

# Route table for public subnets -> IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = var.vpc_id
  tags = merge(var.tags, { Name = "igw-${var.vpc_id}" })
}

resource "aws_route_table" "public_rt" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public
  subnet_id = each.value.id
  route_table_id = aws_route_table.public_rt.id
}
