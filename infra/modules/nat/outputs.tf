output "private_route_table_id" {
  description = "ID of the private route table with NAT gateway route"
  value       = aws_route_table.private_rt.id
}

output "nat_gateway_ids" {
  description = "Map of NAT Gateway IDs"
  value       = { for k, v in aws_nat_gateway.nat : k => v.id }
}
