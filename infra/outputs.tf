output "alb_dns" { value = module.alb.alb_dns }
output "frontend_asg_name" { value = module.asg_frontend.asg_name }
output "backend_asg_name" { value = module.asg_backend.asg_name }
output "bastion_public_ip" { value = module.bastion.bastion_public_ip }
output "rds_endpoint" { value = module.rds.endpoint }
output "jenkins_sonar_instance_id" { value = module.jenkins_sonar.instance_id }
output "jenkins_sonar_private_ip" { value = module.jenkins_sonar.private_ip }

