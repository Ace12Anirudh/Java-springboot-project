
resource "aws_db_subnet_group" "this" {
  name = "${var.name}-db-subnet-group"
  subnet_ids = var.subnet_ids
  tags = var.tags
}

resource "aws_db_instance" "this" {
  allocated_storage    = 20
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  identifier           = "${var.name}-db"
  username             = var.username
  password             = var.password
  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.vpc_security_group_ids
  skip_final_snapshot  = true
  publicly_accessible  = false
  tags = var.tags
}

output "endpoint" { value = aws_db_instance.this.address }
output "port" { value = aws_db_instance.this.port }
