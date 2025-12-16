"""Create backup store for OM if not exists."""
import os
import sys
import urllib.parse
from om_api import api_post, api_get, api_put

om_url = os.environ["OM_URL"]
public_key = os.environ["PUBLIC_KEY"]
private_key = os.environ["PRIVATE_KEY"]
hosts_str = os.environ.get("HOSTS_STR", "")
user = os.environ.get("OPLOG_USER", "")
pwd = urllib.parse.quote(os.environ.get("OPLOG_PWD", ""), safe='')
store_id = os.environ["STORE_ID"]
store_type = os.environ["STORE_TYPE"]
backup_type = os.environ["BACKUP_TYPE"]

store_url = f"{om_url}api/public/v1.0/admin/backup/{store_type}/{backup_type}Configs"
res = api_get(f"{store_url}/{store_id}", public_key, private_key, {})

if (store_type == "oplog" and backup_type in ["mongo", "fileSystem"]) or (
    store_type == "snapshot" and backup_type == "mongo"
    ):
    # mongo oplogstore/blockstore goes here
    data = {
        "id": store_id,
        "assignmentEnabled": True,
        "uri": f"mongodb://{user}:{pwd}@{hosts_str}/?authSource=admin",
    }
    if res.status_code != 404:
        print(f"{store_type.capitalize()} store {store_id} already configured. Updating...")
        res = api_put(f"{store_url}/{store_id}", public_key, private_key, data)
    else:
        print(f"Creating {store_type} store {store_id}...")
        res = api_post(store_url, public_key, private_key, data)
elif backup_type == "s3":
    # s3 oplogstore/blockstore goes here
    bucket_name = os.environ.get("S3_BUCKET_NAME", "")
    bucket_endpoint = os.environ.get("S3_BUCKET_ENDPOINT", "")
    data = {
        "uri":f"mongodb://{user}:{pwd}@{hosts_str}/?authSource=admin",
        "acceptedTos": True,
        "id": store_id,
        "assignmentEnabled": True,
        "pathStyleAccessEnabled": False,
        "s3AuthMethod": "IAM_ROLE",
        "s3BucketEndpoint": bucket_endpoint,
        "s3BucketName": bucket_name,
        "disableProxyS3": True,
        "s3MaxConnections": 50,
        "sseEnabled": False,
    }
    if res.status_code != 404:
        print(f"{store_type.capitalize()} store {store_id} already configured. Updating...")
        res = api_put(f"{store_url}/{store_id}", public_key, private_key, data)
    else:
        print(f"Creating {store_type} store {store_id}...")
        res = api_post(store_url, public_key, private_key, data)
elif store_type == "snapshot" and backup_type == "fileSystem":
    # filesystem snapshot store goes here
    fs_path = os.environ["FILESYSTEM_PATH"]
    data = {
        "id": store_id,
        "assignmentEnabled": True,
        "storePath": fs_path,
        "mmapv1CompressionSetting": "GZIP",
        "wtCompressionSetting": "NONE"
    }
    if res.status_code != 404:
        print(f"{store_type.capitalize()} store {store_id} already configured. Updating...")
        res = api_put(f"{store_url}/{store_id}", public_key, private_key, data)
    else:
        print(f"Creating {store_type} store {store_id}...")
        res = api_post(store_url, public_key, private_key, data)
else:
    print(f"Unsupported backup_type {backup_type} for store_type {store_type}.")
    sys.exit(1)

if res.status_code >= 200 and res.status_code < 300:
    print(f"Successfully created {store_type} store {store_id}.")
else:
    print(f"Failed to create {store_type} store {store_id}: {res.status_code} {res.text}")
    sys.exit(1)