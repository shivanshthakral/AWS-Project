variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_pair_name" {
  type = string
}

variable "ssh_allowed_cidr" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "create_jenkins_server" {
  type    = bool
  default = false
}
