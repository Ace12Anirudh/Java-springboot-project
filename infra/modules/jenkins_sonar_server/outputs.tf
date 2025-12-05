output "instance_id" {
  description = "ID of the Jenkins/SonarQube instance"
  value       = aws_instance.jenkins_sonar.id
}

output "private_ip" {
  description = "Private IP address of the Jenkins/SonarQube instance"
  value       = aws_instance.jenkins_sonar.private_ip
}

output "instance_state" {
  description = "State of the instance"
  value       = aws_instance.jenkins_sonar.instance_state
}
