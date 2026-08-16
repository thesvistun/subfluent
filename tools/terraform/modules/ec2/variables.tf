variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(any)
}

variable "key_name" {
  type = string
}

variable "name" {
  type = string
  description = "Instance tag name"
}