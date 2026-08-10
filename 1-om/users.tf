resource null_resource "create_om_user" {
  provisioner "local-exec" {
    command = "bash ${path.root}/../scripts/create_first_user.sh ${module.om_app.instance_public_dns[0]} ${local.first_user.email} ${local.first_user.pwd} ${local.first_user.firstName} ${local.first_user.lastName} om-admin.json"
  }

  depends_on = [null_resource.om_ready]
}