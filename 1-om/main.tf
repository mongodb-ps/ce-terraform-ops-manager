locals {
  # If expire-on tag is not set, set it to 72 hours from now
  expire_on_date = lookup(var.tags, "expire-on", "") != "" ? var.tags["expire-on"] : formatdate("YYYY-MM-DD", timeadd(timestamp(), "72h"))
  tags           = merge(var.tags, { "expire-on" = local.expire_on_date })
}

resource "local_file" "vars_json" {
  filename = "${path.root}/../stage-1-output.json"
  content = jsonencode({
    first_user             = var.first_user
    backing_db_credentials = var.backing_db_credentials
    tags                   = local.tags
    aws_region             = var.aws_region
    vpc_id                 = var.vpc_id
    subnet_id              = var.subnet_id
    om_download_url        = var.om_download_url
    om_access_url          = "http://${module.om_app.instance_public_dns[0]}:8080/"
    ami_id                 = var.ami_id
    key_name               = var.key_name
    snapshot_size          = var.snapshot_size
    metastore_version      = var.metastore_version
    metastore_fcv          = "${split(".", var.metastore_version)[0]}.0"
  })
}

resource "null_resource" "on_destroy" {
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      rm -f ${path.root}/../stage-1-output.json ${path.root}/../om-admin.json
    EOT
  }
}
