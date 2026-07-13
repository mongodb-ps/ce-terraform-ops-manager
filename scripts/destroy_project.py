"""Destroy the project in Ops Manager"""
import os
from pyomsdk import OpsManagerClient

om_url = os.environ["OM_URL"]
public_key = os.environ["PUBLIC_KEY"]
private_key = os.environ["PRIVATE_KEY"]
org_id = os.environ["ORG_ID"]

client = OpsManagerClient(om_url, public_key, private_key)

# Get all projects in the organization
projects_response = client.organizations_resource.get_all_projects(
    path_params=client.organizations_resource.GetAllProjectsPathParams(
        org_id=org_id,
    ),
    query_params=None,
)
projects = projects_response.get("results", [])
pids = [project["id"] for project in projects]

# Delete each project
for pid in pids:
    client.projects_resource.delete(
        path_params=client.projects_resource.DeletePathParams(
            project_id=pid,
        ),
        query_params=None,
    )

# Finally, delete the organization
client.organizations_resource.delete_organization(
    path_params=client.organizations_resource.DeleteOrganizationPathParams(
        org_id=org_id,
    ),
    query_params=None,
)