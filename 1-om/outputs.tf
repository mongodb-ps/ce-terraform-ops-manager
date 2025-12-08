output "backing_db_credentials" {
  value = var.backing_db_credentials
  sensitive = true
}

output "om_access_url" {
  description = "Access URL for Ops Manager"
  value       = "http://${module.om_app.instance_public_dns[0]}:8080/"
}

output "my_ip" {
  description = "Your current public IP address"
  value       = data.http.my_ip.body
}