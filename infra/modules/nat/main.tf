# Build a stable map so for_each keys are known at plan time.
locals {
  public_subnets_map = { for idx, id in var.public_subnet_ids : tostring(idx) => id }
  common_tags        = coalesce(var.tags, {})
}

# Elastic IPs for NAT gateways (one EIP per public subnet)
resource "aws_eip" "nat_eip" {
  for_each = local.public_subnets_map

  tags = merge(local.common_tags, {
    Name = "nat-eip-${each.key}"
  })
}

# NAT Gateways (one per public subnet)
resource "aws_nat_gateway" "nat" {
  for_each = local.public_subnets_map

  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id     = each.value

  tags = merge(local.common_tags, {
    Name = "nat-${each.key}"
  })

  # ensure the EIP is associated before NAT gateway creation
  depends_on = [aws_eip.nat_eip]
}

# Create a private route table (single route table)
resource "aws_route_table" "private_rt" {
  vpc_id = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.vpc_id}-private-rt"
  })
}

# Create 0.0.0.0/0 route that points to one of the NAT gateways.
# We pick the first NAT gateway from the map values to avoid referencing unknown set order.
# If you want one route table per private subnet/az, create per-AZ route tables instead.
resource "aws_route" "private_default" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = length(values(aws_nat_gateway.nat)) > 0 ? values(aws_nat_gateway.nat)[0].id : null

  # If there are no NATs (empty list), nat_gateway_id will be null which is invalid at apply.
  # Ensure you pass at least one public_subnet_id.
  depends_on = [aws_nat_gateway.nat]
}

# Associate private app subnets with the private route table
resource "aws_route_table_association" "private_app_assoc" {
  for_each       = var.private_app_subnet_ids
  subnet_id      = each.value
  route_table_id = aws_route_table.private_rt.id
}

# Associate private db subnets with the private route table
resource "aws_route_table_association" "private_db_assoc" {
  for_each       = var.private_db_subnet_ids
  subnet_id      = each.value
  route_table_id = aws_route_table.private_rt.id
}
