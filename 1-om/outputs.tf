output "backing_db_credentials" {
  value     = local.backing_db_credentials
  sensitive = true
}

output "first_user" {
  description = "Credentials of the first Ops Manager user"
  value = {
    email = local.first_user.email
    pwd   = local.first_user.pwd
  }
  sensitive = true
}

output "om_access_url" {
  description = "Access URL for Ops Manager"
  value       = "http://${module.om_app.instance_public_dns[0]}:8080/"
}

output "my_ip" {
  description = "Your current public IP address"
  value       = data.http.my_ip.response_body
}