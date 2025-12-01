resource null_resource "create_om_lead_user" {
  provisioner "local-exec" {
    command = "bash ${path.root}/../scripts/create_first_user.sh ${module.om_app.instance_public_dns[0]} ${var.first_user.email} ${var.first_user.pwd} ${var.first_user.firstName} ${var.first_user.lastName} om_lead_admin.json"
  }

  depends_on = [null_resource.om_ready]
}