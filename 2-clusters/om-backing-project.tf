# Create project for OM Lead backing DBs.
data "external" "om_info" {
  program = ["python3", "${path.module}/../scripts/prepare_project.py"]
  query = {
    url         = local.om_access_url
    public_key  = local.om_public_key
    private_key = local.om_private_key,
    org_name    = "Ops Manager",
    project_name = "BackingDB",
  }
  depends_on = [ data.external.om_info ]
}
locals {
  om_info = data.external.om_info.result
}

# resource "null_resource" "destroy_project" {
#   triggers = {
#     always_run = timestamp()
#   }
#   provisioner "local-exec" {
#     when    = destroy
#     environment = {
#       OM_URL = local.om_access_url
#       PUBLIC_KEY = local.om_public_key
#       PRIVATE_KEY = local.om_private_key
#       ORG_ID = local.om_info.org_id
#     }
#     command = "python3 ${path.root}/../scripts/destroy_project.py "
#   }
# }
