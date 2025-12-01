# Create backing DB for OM Lead
module "test_instances" {
  source                 = "../modules/ec2"
  instance_name_prefix   = "test-instance"
  instance_type          = "t3.micro"
  vpc_id                 = local.vpc_id
  subnet_id              = local.subnet_id
  tags                   = local.tags
  instance_count         = var.num_test_instances
  ami_id                 = local.ami_id
  key_name               = local.key_name
  root_block_device_size = 20
  init_script = templatefile("${path.root}/../init-scripts/agent-init.sh", {
    OM_URL                = local.om_access_url,
    OM_AUTOMATION_VERSION = "${local.test_info.agent_version}-1",
    OM_GROUP_ID           = local.test_info.project_id,
    OM_API_KEY            = local.test_info.agent_api_key
  })
}