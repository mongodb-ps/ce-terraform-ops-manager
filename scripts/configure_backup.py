"""Create backup store for OM if not exists."""
import os
import sys
import urllib.parse
from om_api import api_post, api_get, api_put

om_url = os.environ["OM_URL"]
public_key = os.environ["PUBLIC_KEY"]
private_key = os.environ["PRIVATE_KEY"]
oplog_hosts_str = os.environ["OPLOG_HOSTS_STR"]
user = os.environ["OPLOG_USER"]
pwd = urllib.parse.quote(os.environ["OPLOG_PWD"], safe='')
store_id = os.environ["OPLOG_STORE_ID"]
store_type = os.environ["STORE_TYPE"]

oplog_url = f"{om_url}api/public/v1.0/admin/backup/{store_type}/mongoConfigs"
res = api_get(f"{oplog_url}/{store_id}", public_key, private_key, {})

data = {
    "id": store_id,
    "assignmentEnabled": True,
    "uri": f"mongodb://{user}:{pwd}@{oplog_hosts_str}/?authSource=admin",
}

if res.status_code != 404:
    print(f"{store_type.capitalize()} store {store_id} already configured. Updating...")
    res = api_put(f"{oplog_url}/{store_id}", public_key, private_key, data)
else:
    print(f"Creating {store_type} store {store_id}...")
    res = api_post(oplog_url, public_key, private_key, data)

if res.status_code >= 200 and res.status_code < 300:
    print(f"Successfully created {store_type} store {store_id}.")
else:
    print(f"Failed to create {store_type} store {store_id}: {res.status_code} {res.text}")
    sys.exit(1)