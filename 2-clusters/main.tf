locals {
  stage_1_output         = jsondecode(file("${path.root}/../stage-1-output.json"))
  aws_config             = local.stage_1_output.aws_config
  om_config              = local.stage_1_output.om_config
  s3_config              = local.stage_1_output.s3_config
  test_instance_config   = local.stage_1_output.test_instance_config
  tags                   = local.stage_1_output.tags
  first_user             = local.stage_1_output.first_user
  backing_db_credentials = local.stage_1_output.backing_db_credentials
  default_ami_id         = local.stage_1_output.default_ami_id
  om_access_url          = local.stage_1_output.om_access_url
  backup_type            = local.stage_1_output.backup_type

  om_admin       = jsondecode(file("${path.root}/../om-admin.json"))
  om_public_key  = local.om_admin.programmaticApiKey.publicKey
  om_private_key = local.om_admin.programmaticApiKey.privateKey

  backup_fcv = "${split(".", local.om_config.backing_db.version)[0]}.0"
}

resource "local_file" "vars_json" {
  filename = "${path.root}/../stage-2-output.json"
  content = jsonencode({
    default_ami_id = local.default_ami_id
    "BackingDB"    = local.om_info
    "TestProject"  = local.test_info
  })
}

resource "null_resource" "on_destroy" {
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      rm -f ${path.root}/../stage-2-output.json
    EOT
  }
}
