"""Prepare for guest VM."""

import sys
import os
import json
from typing import Optional
from pyomsdk import OpsManagerClient

params = json.load(sys.stdin)

url = params["url"]
public_key = params["public_key"]
private_key = params["private_key"]
org_name = params.get("org_name", "Default Organization")
project_name = params.get("project_name", "Default Project")
state_file = params.get("state_file", "../stage-2-output.json")

client = OpsManagerClient(url, public_key, private_key)

# Create organization if it does not exist.
orgs_response = client.organizations_resource.get_all_organizations(query_params=None)
assert "error" not in orgs_response, f"Can't retrieve organizations: {str(orgs_response)}"
orgs = orgs_response.get("results", [])
org_id: Optional[str] = next(
    (
        org["id"]
        for org in orgs
        if org["name"] == org_name and org.get("isDeleted") is False
    ),
    None,
)

if org_id is None:
    new_org = client.organizations_resource.create_organization(
        query_params=None,
        body_params=client.organizations_resource.CreateOrganizationBodyParams(
            name=org_name,
        ),
    )
    org_id = new_org["id"]

# Create project if it does not exist.
project_id: Optional[str] = None
agent_key: Optional[str] = None
project_response = client.projects_resource.get_by_name(
    path_params=client.projects_resource.GetByNamePathParams(
        group_name=project_name,
    ),
    query_params=None,
)
if project_response.get("error", None) == 404:
    assert org_id is not None, (
        "Organization ID should not be None when creating a project."
    )
    project_response = client.projects_resource.create(
        query_params=None,
        body_params=client.projects_resource.CreateBodyParams(
            name=project_name,
            org_id=org_id,
        ),
    )

project_id = project_response.get("id", None)
agent_key = project_response.get("agentApiKey")

assert project_id is not None, (
    "Project ID should not be None after creation or retrieval."
)
if not agent_key:
    data = {}
    if os.path.exists(state_file):
        with open(state_file, "r", encoding="utf-8") as f:
            data = json.load(f)
            if project_name in data:
                agent_key = data[project_name]["agent_api_key"]
    if not agent_key:
        agent_response = client.agents_resource.create_api_key(
            path_params=client.agents_resource.CreateApiKeyPathParams(
                project_id=project_id,
            ),
            query_params=None,
            body_params=client.agents_resource.CreateApiKeyBodyParams(
                desc="API key for automation agents.",
            ),
        )
        agent_key = agent_response.get("key")

versions_response = client.agents_resource.retrieve_all_versions(query_params=None)
agent_version = versions_response.get("automationVersion")

print(
    json.dumps(
        {
            "org_id": org_id,
            "project_id": project_id,
            "agent_api_key": agent_key,
            "agent_version": agent_version,
        }
    )
)
