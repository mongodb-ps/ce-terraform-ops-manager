"""Prepare for guest VM."""
import sys
import os
import json
from om_api import api_get, api_post

params = json.load(sys.stdin)
# params = json.loads(os.environ["PROJECT_PARAMS_JSON"])

url_prefix = f"{params['url']}/api/public/v1.0"
public_key = params["public_key"]
private_key = params["private_key"]
org_name = params.get("org_name", "Default Organization")
project_name = params.get("project_name", "Default Project")
state_file  = params.get("state_file", "../stage-2-output.json")

# Create organization if it does not exist.
org_url = f"{url_prefix}/orgs"
orgs_response = api_get(org_url, public_key, private_key, {})
orgs = orgs_response.json().get("results", [])
org_id = None
for org in orgs:
    if org["name"] == org_name and org["isDeleted"] is False:
        org_id = org["id"]
if not org_id:
    new_org_response = api_post(org_url, public_key, private_key, {"name": org_name})
    org_id = new_org_response.json().get("id")

# Create project if it does not exist.
project_url = f"{url_prefix}/groups"
project_get_url = f"{url_prefix}/groups/byName/{project_name}"
project_id = None
project_response = api_get(project_get_url, public_key, private_key, {})
if project_response.status_code != 200:
    project_response = api_post(project_url, public_key, private_key, {
        "name": project_name,
        "orgId": org_id
    })
project = project_response.json()
project_id = project.get("id")
agent_key = project.get("agentApiKey", None)

if not agent_key:
    # Check if the output file exists. If yes, read the agent API key from it.
    output_file = state_file
    data = {}
    if os.path.exists(output_file):
        with open(output_file, "r", encoding="utf-8") as f:
            data = json.load(f)
            if project_name in data:
                agent_key = data[project_name]["agent_api_key"]
    else:
        # Create agent API key for the project.
        agent_url = f"{url_prefix}/groups/{project_id}/agentapikeys"
        agent_key_response = api_post(agent_url, public_key, private_key, {
            "desc": "API key for automation agents."
        })
        agent_key = agent_key_response.json().get("key")

automation_url = f"{url_prefix}/softwareComponents/versions"
automation_response = api_get(automation_url, public_key, private_key, {})
agent_version = automation_response.json().get("automationVersion")

print(json.dumps({
    "org_id": org_id,
    "project_id": project_id,
    "agent_api_key": agent_key,
    "agent_version": agent_version
}))
