"""Create oplog store for OM if not exists."""

import os
import sys
import urllib.parse
from pyomsdk import OpsManagerClient
from pyomsdk.resources import S3OplogResource, S3CompatibleBlockstoreResource

om_url = os.environ["OM_URL"]
public_key = os.environ["PUBLIC_KEY"]
private_key = os.environ["PRIVATE_KEY"]
s3_endpoint = os.environ["S3_ENDPOINT"]
s3_bucket = os.environ["S3_BUCKET"]
s3_access_key = os.environ["S3_ACCESS_KEY"]
s3_secret_key = os.environ["S3_SECRET_KEY"]
oplog_hosts_str = os.environ["OPLOG_HOSTS_STR"]
user = os.environ["OPLOG_USER"]
pwd = urllib.parse.quote(os.environ["OPLOG_PWD"], safe="")
store_id = os.environ["OPLOG_STORE_ID"]
store_type = os.environ["STORE_TYPE"]

client = OpsManagerClient(om_url, public_key, private_key)

if store_type == "oplog":
    oplog_resource: S3OplogResource =client.s3_oplog_resource
    s3_configs = oplog_resource.get_all(query_params=None).get("results", [])
    if store_id in [cfg["id"] for cfg in s3_configs]:
        print(f"Oplog store {store_id} already configured.")
        sys.exit(0)
    oplog_resource.create(
        query_params=None,
        body_params=oplog_resource.CreateBodyParams(
            id=store_id,
            accepted_tos=True,
            aws_access_key=s3_access_key,
            aws_secret_key=s3_secret_key,
            s3_bucket_name=s3_bucket,
            s3_bucket_endpoint=s3_endpoint,
            path_style_access_enabled=False,
            s3_max_connections=50,
            sse_enabled=True,
            disable_proxy_s3=True,
            assignment_enabled=True,
            uri=f"mongodb://{user}:{pwd}@{oplog_hosts_str}/?authSource=admin",
        ),
    )
elif store_type == "blockstore":
    bs_resource: S3CompatibleBlockstoreResource = client.s3_compatible_blockstore_resource
    s3_configs = bs_resource.get_all(query_params=None).get("results", [])
    if store_id in [cfg["id"] for cfg in s3_configs]:
        print(f"Blockstore {store_id} already configured.")
        sys.exit(0)
    bs_resource.create(
        query_params=None,
        body_params=bs_resource.CreateBodyParams(
            id=store_id,
            accepted_tos=True,
            aws_access_key=s3_access_key,
            aws_secret_key=s3_secret_key,
            s3_bucket_name=s3_bucket,
            s3_bucket_endpoint=s3_endpoint,
            path_style_access_enabled=False,
            s3_max_connections=50,
            sse_enabled=True,
            disable_proxy_s3=True,
            uri=f"mongodb://{user}:{pwd}@{oplog_hosts_str}/?authSource=admin",
        ),
    )
print(f"Successfully created {store_type} store {store_id}.")
