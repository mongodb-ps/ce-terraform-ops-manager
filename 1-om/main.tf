locals {
  # If expire-on tag is not set, set it to 72 hours from now
  expire_on_date = lookup(var.tags, "expire-on", "") != "" ? var.tags["expire-on"] : formatdate("YYYY-MM-DD", timeadd(timestamp(), "72h"))
  tags = merge(var.tags, {"expire-on" = local.expire_on_date})
}

resource "local_file" "tags_json" {
  filename = "${path.root}/../stage-1-output.json"
  content  = jsonencode({
    first_user = var.first_user
    appdb_user = var.backing_db_credentials
    tags = local.tags
    aws_region = var.aws_region
    vpc_id = var.vpc_id
    subnet_id = var.subnet_id
    om_download_url = var.om_download_url
    om_access_url = "http://${module.om_app.instance_public_dns[0]}:8080/"
  })
}

resource "null_resource" "on_destroy" {
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      rm -f ${path.root}/../stage-1-output.json ${path.root}/../om_lead_admin.json
    EOT
  }
}