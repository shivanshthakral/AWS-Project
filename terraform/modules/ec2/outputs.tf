output "instance_id" {
  value = aws_instance.app_server.id
}

output "public_ip" {
  value = aws_instance.app_server.public_ip
}

output "security_group_id" {
  value = aws_security_group.app.id
}

output "jenkins_public_ip" {
  value = try(aws_instance.jenkins_server[0].public_ip, null)
}
