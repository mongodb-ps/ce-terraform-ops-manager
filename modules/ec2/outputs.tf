output "instance_ids" {
  description = "IDs of the created EC2 instances"
  value       = aws_instance.vm[*].id
}

output "instance_public_ips" {
  description = "Public IP addresses of the created EC2 instances"
  value       = aws_instance.vm[*].public_ip
}

output "instance_private_ips" {
  description = "Private IP addresses of the created EC2 instances"
  value       = aws_instance.vm[*].private_ip
}

output "instance_public_dns" {
  description = "Public DNS names of the created EC2 instances"
  value       = aws_instance.vm[*].public_dns
}

output "instance_private_dns" {
  description = "Private DNS names of the created EC2 instances"
  value       = aws_instance.vm[*].private_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.vm_sg.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = data.aws_vpc.selected.cidr_block
}

output "ssh_connection_strings" {
  description = "SSH connection strings for the instances"
  value = [
    for idx, instance in aws_instance.vm :
    "ssh -i <your-key.pem> ec2-user@${instance.public_ip}"
  ]
}
