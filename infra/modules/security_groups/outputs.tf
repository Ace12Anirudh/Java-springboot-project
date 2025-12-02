output "alb_sg" { value = aws_security_group.alb_sg.id }
output "bastion_sg" { value = aws_security_group.bastion_sg.id }
output "frontend_sg" { value = aws_security_group.frontend_sg.id }
output "backend_sg" { value = aws_security_group.backend_sg.id }
output "rds_sg" { value = aws_security_group.rds_sg.id }
