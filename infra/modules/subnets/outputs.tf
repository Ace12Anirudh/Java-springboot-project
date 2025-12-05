output "public_subnet_ids" { value = [for s in aws_subnet.public: s.id] }
output "private_subnet_ids_app" { value = [for s in aws_subnet.private_app: s.id] }
output "private_subnet_ids_db"  { value = [for s in aws_subnet.private_db: s.id] }
output "private_subnet_ids_app_map" { value = { for k, s in aws_subnet.private_app: k => s.id } }
output "private_subnet_ids_db_map"  { value = { for k, s in aws_subnet.private_db: k => s.id } }
