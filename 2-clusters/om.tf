# Create backing DB for OM Lead
module "om_metastore" {
  source                 = "../modules/ec2"
  instance_name_prefix   = "om-metastore"
  instance_type          = "t3.small"
  vpc_id                 = local.vpc_id
  subnet_id              = local.subnet_id
  tags                   = local.tags
  instance_count         = 1
  ami_id                 = local.ami_id
  key_name               = local.key_name
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
  metastore_hosts = module.om_metastore.instance_private_dns
  params_metastore = replace(jsonencode(merge(local.params, {
    rs                = "metastore",
    hosts             = local.metastore_hosts,
    project_id        = local.om_info.project_id,
    metastore_version = local.metastore_version,
    metastore_fcv     = local.metastore_fcv
  })), "\\n", "")
}

resource "null_resource" "create_metastore_rs" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    environment = {
      PARAMS = "${local.params_metastore}"
    }
    command = "python3 ${path.root}/../scripts/create_cluster.py "
  }
}
