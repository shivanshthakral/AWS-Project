variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "app_sg_id" {
  type = string
}

variable "target_instance_id" {
  type = string
}

variable "certificate_arn" {
  type    = string
  default = ""
}

variable "tags" {
  type = map(string)
}
