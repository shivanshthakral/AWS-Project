output "ec2_public_ip" {
  value = module.ec2.public_ip
}

output "ec2_instance_id" {
  value = module.ec2.instance_id
}

output "jenkins_public_ip" {
  value = module.ec2.jenkins_public_ip
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "app_url" {
  value = "http://${module.alb.alb_dns_name}"
}
