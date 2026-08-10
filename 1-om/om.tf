data "http" "my_ip" {
  url = "https://ifconfig.me/ip"
}

# Runs at plan time (data sources are read during the refresh phase), so a failing
# prerequisites check aborts the plan before anything is created or modified.
data "external" "prerequisites" {
  program = ["bash", "-c", "bash ${path.root}/../scripts/check-prerequisites.sh '${local.aws_config.key_name}' >/dev/null && printf '{\"ok\":\"true\"}'"]
}

# check-prerequisites.sh (data.external.prerequisites) verifies that the local key pair
# exists at ~/.ssh/<key_name> and ~/.ssh/<key_name>.pub, otherwise the plan fails.
# Terraform creates the key pair on AWS; if it already exists there but is not in the
# Terraform state, import it once with: terraform import aws_key_pair.vm <key_name>
resource "aws_key_pair" "vm" {
  key_name   = local.aws_config.key_name
  public_key = file(pathexpand("~/.ssh/${local.aws_config.key_name}.pub"))

  tags = local.tags
}

module "om_appdb" {
  source                 = "../modules/ec2"
  instance_name_prefix   = "om-appdb"
  vpc_id                 = local.aws_config.vpc_id
  subnet_id              = local.aws_config.subnet_id
  tags                   = local.tags
  key_name               = local.aws_config.key_name
  ami_id                 = local.om_config.appdb.ami_id
  instance_type          = local.om_config.appdb.tier
  root_block_device_size = local.om_config.appdb.root_size_gb

  depends_on = [aws_key_pair.vm, data.external.prerequisites]

  init_script = templatefile("${path.root}/../init-scripts/appdb-init.sh", {
    OM_APPDB_USER     = local.backing_db_credentials.name,
    OM_APPDB_PASSWORD = local.backing_db_credentials.pwd,
    OM_APPDB_VERSION  = local.om_config.appdb.version,
    WHITELIST_CIDR    = data.http.my_ip.response_body
  })
}

locals {
  appdb_hosts     = module.om_appdb.instance_private_dns
  appdb_hosts_str = join(",", module.om_appdb.instance_private_dns)
}
module "om_app" {
  source                 = "../modules/ec2"
  instance_name_prefix   = "om"
  vpc_id                 = local.aws_config.vpc_id
  subnet_id              = local.aws_config.subnet_id
  key_name               = local.aws_config.key_name
  ami_id                 = local.om_config.ami_id
  instance_type          = local.om_config.tier
  root_block_device_size = local.om_config.root_size_gb
  instance_count         = local.om_config.instance_count
  tags                   = local.tags
  iam_instance_profile   = "s3_full_access"
  depends_on             = [aws_key_pair.vm, data.external.prerequisites]
  ingress_rules = [
    {
      description = "HTTP 8080 access"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTP 8443 access"
      from_port   = 8443
      to_port     = 8443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  init_script = templatefile("${path.root}/../init-scripts/om-init.sh", {
    OM_DOWNLOAD_URL   = local.om_config.download_url,
    OM_APPDB_HOSTS    = local.appdb_hosts_str,
    OM_APPDB_USER     = local.backing_db_credentials.name,
    OM_APPDB_PASSWORD = local.backing_db_credentials.pwd
  })
}

resource "null_resource" "om_ready" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "bash ${path.root}/../scripts/wait-for-om.sh ${module.om_app.instance_public_dns[0]} 8080"
  }
}
