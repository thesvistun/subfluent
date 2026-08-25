output "ec2_instance_hostname" {
  value = module.web.instance_hostname
}

output "ec2_instance_instance_id" {
  value = module.web.instance_hostname
}

output "alb_hostname" {
  value = aws_lb.subfluent.dns_name
}

output "inventory" {
  value     = jsondecode(data.ansible_inventory.inventory.json)
  sensitive = true
}
