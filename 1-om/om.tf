module "om_appdb" {
  source                 = "../modules/ec2"
  instance_name_prefix   = "om-appdb"
  instance_type          = var.appdb_tier
  vpc_id                 = var.vpc_id
  subnet_id              = var.subnet_id
  ami_id                 = var.ami_id
  tags                   = local.tags
  key_name               = var.key_name
  root_block_device_size = var.appdb_size

  init_script = templatefile("${path.root}/../init-scripts/appdb-init.sh", {
    OM_APPDB_USER     = var.backing_db_credentials.name,
    OM_APPDB_PASSWORD = var.backing_db_credentials.pwd
    OM_APPDB_VERSION  = var.appdb_version
  })
}

locals {
  appdb_hosts     = module.om_appdb.instance_private_dns
  appdb_hosts_str = join(",", module.om_appdb.instance_private_dns)
}
module "om_app" {
  source                 = "../modules/ec2"
  instance_name_prefix   = "om"
  instance_type          = var.om_tier
  vpc_id                 = var.vpc_id
  subnet_id              = var.subnet_id
  ami_id                 = var.ami_id
  key_name               = var.key_name
  tags                   = local.tags
  root_block_device_size = var.om_size
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
    OM_DOWNLOAD_URL   = var.om_download_url,
    OM_APPDB_HOSTS    = local.appdb_hosts_str,
    OM_APPDB_USER     = var.backing_db_credentials.name,
    OM_APPDB_PASSWORD = var.backing_db_credentials.pwd
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
