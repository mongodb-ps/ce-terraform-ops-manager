# Create backing DB for OM Lead
module "om_backup" {
  source                 = "../modules/ec2"
  instance_name_prefix   = "om-backup"
  instance_type          = local.test_instance_config.tier
  vpc_id                 = local.aws_config.vpc_id
  subnet_id              = local.aws_config.subnet_id
  tags                   = local.tags
  instance_count         = local.om_config.backing_db.instance_count
  ami_id                 = local.om_config.backing_db.ami_id
  key_name               = local.aws_config.key_name
  root_block_device_size = 20
  init_script = templatefile("${path.root}/../init-scripts/agent-init.sh", {
    OM_URL                = local.om_access_url,
    OM_AUTOMATION_VERSION = "${local.om_info.agent_version}-1",
    OM_GROUP_ID           = local.om_info.project_id,
    OM_API_KEY            = local.om_info.agent_api_key
  })
}

locals {
  params = {
    om_url      = local.om_access_url,
    project_id  = local.om_info.project_id,
    public_key  = local.om_public_key,
    private_key = local.om_private_key,
    user        = local.backing_db_credentials.name,
    pwd         = local.backing_db_credentials.pwd
  }
  backup_hosts = module.om_backup.instance_private_dns
  params_backup = replace(jsonencode(merge(local.params, {
    rs                = "backup",
    hosts             = local.backup_hosts,
    project_id        = local.om_info.project_id,
    backup_version = local.om_config.backing_db.version,
    backup_fcv     = local.backup_fcv
  })), "\\n", "")
}

# Create replica set for OM backup.
# This rs will later be used as oplog/snapshot store, or metadata store.
resource "null_resource" "create_backup_rs" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    environment = {
      PARAMS = "${local.params_backup}"
    }
    command = "python3 ${path.root}/../scripts/create_cluster.py "
  }
  depends_on = [ module.om_backup ]
}