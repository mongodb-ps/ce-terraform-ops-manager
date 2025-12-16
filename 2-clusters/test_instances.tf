# Create backing DB for OM Lead
module "test_instances" {
  source                 = "../modules/ec2"
  instance_name_prefix   = "test-instance"
  instance_type          = local.test_instance_config.tier
  vpc_id                 = local.aws_config.vpc_id
  subnet_id              = local.aws_config.subnet_id
  key_name               = local.aws_config.key_name
  tags                   = local.tags
  instance_count         = local.test_instance_config.instance_count
  ami_id                 = local.test_instance_config.ami_id
  root_block_device_size = local.test_instance_config.root_size_gb
  init_script = templatefile("${path.root}/../init-scripts/agent-init.sh", {
    OM_URL                = local.om_access_url,
    OM_AUTOMATION_VERSION = "${local.test_info.agent_version}-1",
    OM_GROUP_ID           = local.test_info.project_id,
    OM_API_KEY            = local.test_info.agent_api_key
  })
}