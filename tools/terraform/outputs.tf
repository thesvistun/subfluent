output "ec2_instance_hostname" {
  value = module.web.instance_hostname
}

output "inventory" {
  value     = jsondecode(data.ansible_inventory.inventory.json)
  sensitive = true
}
