"""Create oplog store for OM if not exists."""
import os
import sys
import urllib.parse
from om_api import api_post, api_get

om_url = os.environ["OM_URL"]
public_key = os.environ["PUBLIC_KEY"]
private_key = os.environ["PRIVATE_KEY"]
s3_endpoint = os.environ["S3_ENDPOINT"]
s3_bucket = os.environ["S3_BUCKET"]
s3_access_key = os.environ["S3_ACCESS_KEY"]
s3_secret_key = os.environ["S3_SECRET_KEY"]
oplog_hosts_str = os.environ["OPLOG_HOSTS_STR"]
user = os.environ["OPLOG_USER"]
pwd = urllib.parse.quote(os.environ["OPLOG_PWD"], safe='')
store_id = os.environ["OPLOG_STORE_ID"]
store_type = os.environ["STORE_TYPE"]

s3_url = f"{om_url}api/public/v1.0/admin/backup/{store_type}/s3Configs?pretty=true"
res = api_get(s3_url, public_key, private_key, {})
s3_configs = res.json().get("results", [])
if store_id in [cfg["id"] for cfg in s3_configs]:
    print(f"Oplog store {store_id} already configured.")
    sys.exit(0)

data = {
    "id": store_id,
    "acceptedTos": True,
    "awsAccessKey": s3_access_key,
    "awsSecretKey": s3_secret_key,
    "s3BucketName": s3_bucket,
    "s3BucketEndpoint": s3_endpoint,
    "pathStyleAccessEnabled": False,
    "s3MaxConnections": 50,
    "sseEnabled": True,
    "disableProxyS3": True,
    "assignmentEnabled": True,
    "uri": f"mongodb://{user}:{pwd}@{oplog_hosts_str}/?authSource=admin",
}
res = api_post(s3_url, public_key, private_key, data)
if res.status_code >= 200 and res.status_code < 300:
    print(f"Successfully created {store_type} store {store_id}.")
else:
    print(f"Failed to create {store_type} store {store_id}: {res.text}")
    sys.exit(1)