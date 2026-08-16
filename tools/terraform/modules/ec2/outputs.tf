output "instance_hostname" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.this.public_dns
}