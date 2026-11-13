variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "infra-monitor"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "owner" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_pair_name" {
  type        = string
  description = "AWS key pair for SSH access"
}

variable "ssh_allowed_cidr" {
  type        = string
  description = "Public CIDR allowed to SSH to EC2 (example: 203.0.113.10/32)"
}

variable "alb_certificate_arn" {
  type        = string
  default     = ""
  description = "ACM certificate ARN for HTTPS listener on ALB"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "RDS MySQL root password"
  validation {
    condition     = length(var.db_password) >= 8 && length(var.db_password) <= 41
    error_message = "The RDS MySQL password must contain between 8 and 41 characters."
  }
}

variable "create_jenkins_server" {
  type        = bool
  default     = false
  description = "Reserve a separate EC2 server for Jenkins; the supplied setup uses the local Jenkins controller."
}
