locals {
  stage_1_output         = jsondecode(file("${path.root}/../stage-1-output.json"))
  om_access_url          = local.stage_1_output.om_access_url
  aws_region             = local.stage_1_output.aws_region
  vpc_id                 = local.stage_1_output.vpc_id
  subnet_id              = local.stage_1_output.subnet_id
  tags                   = local.stage_1_output.tags
  first_user             = local.stage_1_output.first_user
  backing_db_credentials = local.stage_1_output.backing_db_credentials
  om_download_url        = local.stage_1_output.om_download_url
  ami_id                 = local.stage_1_output.ami_id
  key_name               = local.stage_1_output.key_name
  snapshot_size          = local.stage_1_output.snapshot_size
  metastore_version      = local.stage_1_output.metastore_version
  metastore_fcv          = local.stage_1_output.metastore_fcv
  metastore_tier         = local.stage_1_output.metastore_tier
  num_test_instances     = local.stage_1_output.num_test_instances
  test_instance_tier     = local.stage_1_output.test_instance_tier
  test_instance_size     = local.stage_1_output.test_instance_size

  om_admin       = jsondecode(file("${path.root}/../om-admin.json"))
  om_public_key  = local.om_admin.programmaticApiKey.publicKey
  om_private_key = local.om_admin.programmaticApiKey.privateKey
}

resource "local_file" "vars_json" {
  filename = "${path.root}/../stage-2-output.json"
  content = jsonencode({
    first_user             = local.first_user
    backing_db_credentials = local.backing_db_credentials
    tags                   = local.tags
    aws_region             = local.aws_region
    vpc_id                 = local.vpc_id
    subnet_id              = local.subnet_id
    "BackingDB"            = local.om_info
    "TestProject"               = local.test_info
    om_metastore_hosts     = local.metastore_hosts
  })
}

resource "null_resource" "on_destroy" {
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      rm -f ${path.root}/../stage-2-output.json ${path.root}/../om_admin.json
    EOT
  }
  # depends_on = [ null_resource.destroy_project ]
}
