# When email is not provided, derive it from the ARN of the AWS identity running Terraform,
# e.g. arn:aws:iam::123456789012:user/joe@example.com (same value as `aws sts get-caller-identity`).
data "aws_caller_identity" "current" {
  count = var.email != null ? 0 : 1
}

# Random password used when backing_db_credentials.pwd is not provided.
# Alphanumeric only: the password is embedded in single-quoted shell scripts.
resource "random_password" "backing_db" {
  count   = var.backing_db_credentials.pwd == null ? 1 : 0
  length  = 24
  special = false
}

locals {
  email = var.email != null ? var.email : regex(".*/([^/]+)$", data.aws_caller_identity.current[0].arn)[0]
  # If key_name is not provided, use the local part of the email (before @)
  key_name = var.aws_config.key_name != null ? var.aws_config.key_name : split("@", local.email)[0]
  # If expire-on tag is not set, set it to 72 hours from now
  expire_on_date = lookup(var.tags, "expire-on", "") != "" ? var.tags["expire-on"] : formatdate("YYYY-MM-DD", timeadd(timestamp(), "72h"))
  tags           = merge(var.tags, { owner = local.email, "expire-on" = local.expire_on_date })
  s3_config = {
    prefix   = var.s3_config.prefix != null ? var.s3_config.prefix : split("@", lower(local.email))[0]
    endpoint = var.s3_config.endpoint != null ? var.s3_config.endpoint : "https://s3.${var.aws_config.region}.amazonaws.com"
  }
  # Resolve the VPC/subnet to use: existing ones when provided, otherwise the ones created in vpc.tf
  aws_config = merge(var.aws_config, {
    key_name  = local.key_name
    vpc_id    = var.aws_config.vpc_id != null ? var.aws_config.vpc_id : aws_vpc.om[0].id
    subnet_id = var.aws_config.subnet_id != null ? var.aws_config.subnet_id : aws_subnet.om[0].id
  })
  backing_db_credentials = {
    name = var.backing_db_credentials.name != null ? var.backing_db_credentials.name : "root"
    pwd  = var.backing_db_credentials.pwd != null ? var.backing_db_credentials.pwd : random_password.backing_db[0].result
  }
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
  first_user = merge(var.first_user, {
    email = var.first_user.email != null ? var.first_user.email : local.email
  })
}

resource "local_file" "vars_json" {
  filename = "${path.root}/../stage-1-output.json"
  content = jsonencode({
    first_user             = local.first_user
    backing_db_credentials = local.backing_db_credentials
    tags                   = local.tags
    aws_config             = local.aws_config
    om_config              = local.om_config
    test_instance_config   = local.test_instance_config
    default_ami_id         = var.default_ami_id
    s3_config              = local.s3_config
    om_access_url          = "http://${module.om_app.instance_public_dns[0]}:8080/"
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
