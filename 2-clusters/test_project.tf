# Create project for OM Lead backing DBs.
data "external" "test_project" {
  program = ["python3", "${path.module}/../scripts/prepare_project.py"]
  query = {
    url         = local.om_access_url
    public_key  = local.om_public_key
    private_key = local.om_private_key,
    org_name    = "Ops Manager",
    project_name = "TestProject",
  }
}
locals {
  test_info = data.external.test_project.result
}
