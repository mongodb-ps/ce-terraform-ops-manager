"""Enable the daemon on specified hosts using the automation config API."""
import sys
import os
from om_api import api_get, api_put

om_url = os.environ["OM_URL"]
head = os.environ["HEADDB"]
public_key = os.environ["PUBLIC_KEY"]
private_key = os.environ["PRIVATE_KEY"]

daemon_get_url = f"{om_url}/api/public/v1.0/admin/backup/daemon/configs/"
daemon_response = api_get(daemon_get_url, public_key, private_key, {})
daemons = daemon_response.json().get("results", [])
daemon = daemons[0]
daemon_id = daemon["id"]
machine = daemon["machine"]
machine["headRootDirectory"] = head
if daemon["configured"]:
    print(f"Daemon {daemon_id}/{machine['machine']} is already enabled.")
    sys.exit(0)

print(f"Enabling daemon {daemon_id}/{machine['machine']}...")
daemon_put_url = f"{om_url}/api/public/v1.0/admin/backup/daemon/configs/{machine['machine']}/"
daemon_response = api_put(daemon_put_url, public_key, private_key, {
    "configured": True,
    "id": daemon_id,
    "machine": machine
})
if daemon_response.status_code != 200:
    print(f"Failed to enable daemon {daemon_id}/{machine['machine']}: {daemon_response.text}")
    sys.exit(1)
else:
    print(f"Daemon {daemon_id}/{machine['machine']} enabled successfully.")
    sys.exit(0)