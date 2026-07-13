"""Enable the daemon on specified hosts using the automation config API."""

import sys
import os
from pyomsdk import OpsManagerClient

om_url = os.environ["OM_URL"]
head = os.environ["HEADDB"]
public_key = os.environ["PUBLIC_KEY"]
private_key = os.environ["PRIVATE_KEY"]

client = OpsManagerClient(om_url, public_key, private_key)

daemon_response = client.backup_daemon_resource.get_all(query_params=None)
daemons = daemon_response.get("results", [])
daemon = daemons[0]
daemon_id = daemon["id"]
machine = daemon["machine"]
machine_name = machine["machine"]
machine["headRootDirectory"] = head

if daemon["configured"]:
    print(f"Daemon {daemon_id}/{machine_name} is already enabled.")
    sys.exit(0)

print(f"Enabling daemon {daemon_id}/{machine_name}...")
client.backup_daemon_resource.update(
    path_params=client.backup_daemon_resource.UpdatePathParams(
        machine=machine_name,
        head_root_directory=head,
    ),
    query_params=None,
    body_params=client.backup_daemon_resource.UpdateBodyParams(
        configured=True,
        machine=machine,
    ),
)
print(f"Daemon {daemon_id}/{machine_name} enabled successfully.")
