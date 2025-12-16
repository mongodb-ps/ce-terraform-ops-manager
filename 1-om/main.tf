locals {
  # If expire-on tag is not set, set it to 72 hours from now
  expire_on_date        = lookup(var.tags, "expire-on", "") != "" ? var.tags["expire-on"] : formatdate("YYYY-MM-DD", timeadd(timestamp(), "72h"))
  tags                  = merge(var.tags, { "expire-on" = local.expire_on_date })
  s3_config             = {
    prefix   = var.s3_config.prefix != null ? var.s3_config.prefix : split("@", lower(var.tags["owner"]))[0]
    endpoint = var.s3_config.endpoint != null ? var.s3_config.endpoint : "https://s3.${var.aws_config.region}.amazonaws.com"
  }
  oplog_store_bucket    = "${local.s3_config.prefix}-oplog-store"
  snapshot_store_bucket = "${local.s3_config.prefix}-snapshot-store"
  om_config = merge(var.om_config, {
    ami_id = var.om_config.ami_id != null ? var.om_config.ami_id : var.default_ami_id,
    appdb = merge(var.om_config.appdb, {
      ami_id = var.om_config.appdb.ami_id != null ? var.om_config.appdb.ami_id : var.default_ami_id,
    }),
    backing_db = merge(var.om_config.backing_db, {
      ami_id = var.om_config.backing_db.ami_id != null ? var.om_config.backing_db.ami_id : var.default_ami_id,
    })
  })
  test_instance_config = merge(var.test_instance_config, {
    ami_id = var.test_instance_config.ami_id != null ? var.test_instance_config.ami_id : var.default_ami_id,
  })
}

resource "local_file" "vars_json" {
  filename = "${path.root}/../stage-1-output.json"
  content = jsonencode({
    first_user             = var.first_user
    backing_db_credentials = var.backing_db_credentials
    tags                   = local.tags
    aws_config             = var.aws_config
    om_config              = local.om_config
    test_instance_config   = local.test_instance_config
    default_ami_id         = var.default_ami_id
    s3_config              = local.s3_config
    om_access_url          = "http://${module.om_app.instance_public_dns[0]}:8080/"
    backup_type            = var.backup_type
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
