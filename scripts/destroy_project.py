"""Destroy the project in Ops Manager"""
import sys
import os
from om_api import api_delete, api_get, api_put

om_url = os.environ["OM_URL"]
public_key = os.environ["PUBLIC_KEY"]
private_key = os.environ["PRIVATE_KEY"]
org_id = os.environ["ORG_ID"]

org_proj_url = f"{om_url}/api/public/v1.0/orgs/{org_id}/groups"
proj_url = f"{om_url}/api/public/v1.0/groups"
org_url = f"{om_url}/api/public/v1.0/orgs/{org_id}"

# Get all projects in the organization
projects_response = api_get(org_proj_url, public_key, private_key, {})
projects = projects_response.json().get("results", [])
pids = [project["id"] for project in projects]
# Delete each project
for pid in pids:
    del_proj_url = f"{proj_url}/{pid}"
    api_delete(del_proj_url, public_key, private_key, {})

# Finally, delete the organization
api_delete(org_url, public_key, private_key, {})