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

# Random password used when first_user.pwd is not provided. Ops Manager requires
# upper/lowercase, digits, special characters and at least 8 characters. The special
# charset excludes characters that would break the shell quoting in create_first_user.sh.
resource "random_password" "first_user" {
  count            = var.first_user.pwd == null ? 1 : 0
  length           = 24
  special          = true
  override_special = "!@#%^+=-_.,:/~"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
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
  # Resolve the VPC/subnet to use: existing ones when provided, otherwise the
  # default VPC (or the first VPC in the region) and one of its public subnets.
  aws_config = merge(var.aws_config, {
    key_name  = local.key_name
    vpc_id    = var.aws_config.vpc_id != null ? var.aws_config.vpc_id : local.fallback_vpc_id
    subnet_id = var.aws_config.subnet_id != null ? var.aws_config.subnet_id : local.fallback_subnet_id
  })
  backing_db_credentials = {
    name = var.backing_db_credentials.name != null ? var.backing_db_credentials.name : "root"
    pwd  = var.backing_db_credentials.pwd != null ? var.backing_db_credentials.pwd : random_password.backing_db[0].result
  }
  # Resolve the Ops Manager package download URL from the release archive page:
  # the newest package whose name contains om_config.version, or the newest
  # overall when no version is provided. Only the main Ops Manager package in the
  # current naming scheme (mongodb-mms-<major>.<minor>.<patch>.<build>.<timestamp>.amd64.deb)
  # is considered; legacy 1.x-5.x and mongodb-mms-backup-daemon links are excluded.
  om_deb_urls = distinct(regexall("https://downloads\\.mongodb\\.com/on-prem-mms/deb/mongodb-mms-(?:[0-9]+)\\.(?:[0-9]+)\\.(?:[0-9]+)\\.(?:[0-9]+)\\.(?:[0-9TZ]+)\\.amd64\\.deb", data.http.om_releases.response_body))
  om_deb_parsed = [for u in local.om_deb_urls : {
    url  = u
    caps = regex("mongodb-mms-([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.([0-9TZ]+)\\.amd64\\.deb$", u)
  }]
  # Zero-pad the numeric components so lexicographic order matches version order.
  om_deb_by_key = {
    for p in local.om_deb_parsed :
    format("%03d.%03d.%03d.%03d.%s", tonumber(p.caps[0]), tonumber(p.caps[1]), tonumber(p.caps[2]), tonumber(p.caps[3]), p.caps[4]) => p.url
  }
  om_deb_candidates = var.om_config.version != null ? { for k, v in local.om_deb_by_key : k => v if strcontains(v, var.om_config.version) } : local.om_deb_by_key
  om_deb_url        = local.om_deb_candidates[element(sort(keys(local.om_deb_candidates)), -1)]
  # Resolve the backing database MongoDB version: when backing_db.version is not
  # provided, use the latest patch of the same major.minor as the Ops Manager
  # version, looked up from the MongoDB Enterprise Advanced release archive.
  om_version             = var.om_config.version != null ? var.om_config.version : join(".", regex("mongodb-mms-([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.([0-9TZ]+)\\.amd64\\.deb$", local.om_deb_url))
  om_version_major_minor = join(".", slice(split(".", local.om_version), 0, 2))
  enterprise_versions    = distinct(regexall("mongodb-linux-x86_64-enterprise-ubuntu2204-([0-9]+)\\.([0-9]+)\\.([0-9]+)", data.http.mongodb_enterprise_releases.response_body))
  enterprise_by_key = {
    for v in local.enterprise_versions :
    format("%03d.%03d.%03d", tonumber(v[0]), tonumber(v[1]), tonumber(v[2])) => join(".", v)
    if "${v[0]}.${v[1]}" == local.om_version_major_minor
  }
  backing_db_version = var.om_config.backing_db.version != null ? var.om_config.backing_db.version : "${local.enterprise_by_key[element(sort(keys(local.enterprise_by_key)), -1)]}-ent"
  om_config = merge(var.om_config, {
    ami_id       = var.om_config.ami_id != null ? var.om_config.ami_id : var.default_ami_id,
    download_url = local.om_deb_url,
    appdb = merge(var.om_config.appdb, {
      ami_id = var.om_config.appdb.ami_id != null ? var.om_config.appdb.ami_id : var.default_ami_id,
    }),
    backing_db = merge(var.om_config.backing_db, {
      ami_id  = var.om_config.backing_db.ami_id != null ? var.om_config.backing_db.ami_id : var.default_ami_id,
      version = local.backing_db_version,
    })
  })
  test_instance_config = merge(var.test_instance_config, {
    ami_id = var.test_instance_config.ami_id != null ? var.test_instance_config.ami_id : var.default_ami_id,
  })
  # Derive firstName/lastName from the local part of the email (before @), split on ".":
  # the first part is the first name and the rest the last name; "Doe" when no ".".
  name_parts = split(".", split("@", local.email)[0])
  first_user = merge(var.first_user, {
    email     = var.first_user.email != null ? var.first_user.email : local.email
    pwd       = var.first_user.pwd != null ? var.first_user.pwd : random_password.first_user[0].result
    firstName = var.first_user.firstName != null ? var.first_user.firstName : local.name_parts[0]
    lastName  = var.first_user.lastName != null ? var.first_user.lastName : length(local.name_parts) > 1 ? join(".", slice(local.name_parts, 1, length(local.name_parts))) : "Doe"
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
    shared_sg = {
      id   = aws_security_group.shared.id
      name = aws_security_group.shared.name
    }
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
