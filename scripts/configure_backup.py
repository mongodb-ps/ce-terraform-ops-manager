"""Create backup store for OM if not exists."""

import os
import urllib.parse
from pyomsdk import OpsManagerClient
from pyomsdk.resources.enums import S3AuthMethod

om_url = os.environ["OM_URL"]
public_key = os.environ["PUBLIC_KEY"]
private_key = os.environ["PRIVATE_KEY"]
hosts_str = os.environ.get("HOSTS_STR", "")
user = os.environ.get("OPLOG_USER", "")
pwd = urllib.parse.quote(os.environ.get("OPLOG_PWD", ""), safe="")
store_id = os.environ["STORE_ID"]
store_type = os.environ["STORE_TYPE"]
backup_type = os.environ["BACKUP_TYPE"]

client = OpsManagerClient(om_url, public_key, private_key)
assert store_type in ["oplog", "blockstore"], (
    "STORE_TYPE must be 'oplog' or 'blockstore'"
)
assert backup_type in ["mongo", "s3"], "BACKUP_TYPE must be 'mongo' or 's3'"

if store_type == "oplog":
    # Congiguring oplog store for backup.
    if backup_type == "mongo":
        # Use MongoDB replica set for oplog store.
        os_resource = client.oplog_store_resource
        response = os_resource.get_by_id(
            path_params=os_resource.GetByIdPathParams(oplog_config_id=store_id),
            query_params=None,
        )
        if "error" in response and response.get("error") == "404":
            print(f"Creating oplog store {store_id}...")
            os_resource.create(
                query_params=None,
                body_params=os_resource.CreateBodyParams(
                    id=store_id,
                    assignment_enabled=True,
                    uri=f"mongodb://{user}:{pwd}@{hosts_str}/?authSource=admin",
                ),
            )
        else:
            print(f"Oplog store {store_id} already configured. Updating...")
            os_resource.update(
                path_params=os_resource.UpdatePathParams(oplog_config_id=store_id),
                query_params=None,
                body_params=os_resource.UpdateBodyParams(
                    assignment_enabled=True,
                    uri=f"mongodb://{user}:{pwd}@{hosts_str}/?authSource=admin",
                ),
            )
    elif backup_type == "s3":
        # Use S3-compatible storage for oplog store.
        s3_os_resource = client.s3_oplog_resource
        response = s3_os_resource.get_by_id(
            path_params=s3_os_resource.GetByIdPathParams(s3_oplog_config_id=store_id),
            query_params=None,
        )
        bucket_name = os.environ.get("S3_BUCKET_NAME", "")
        bucket_endpoint = os.environ.get("S3_BUCKET_ENDPOINT", "")
        if "error" in response and response.get("error") == "404":
            print(f"Creating S3 oplog store {store_id}...")
            s3_os_resource.create(
                query_params=None,
                body_params=s3_os_resource.CreateBodyParams(
                    id=store_id,
                    assignment_enabled=True,
                    uri=f"mongodb://{user}:{pwd}@{hosts_str}/?authSource=admin",
                    accepted_tos=True,
                    path_style_access_enabled=False,
                    s3_auth_method=S3AuthMethod.IAM_ROLE,
                    s3_bucket_endpoint=bucket_endpoint,
                    s3_bucket_name=bucket_name,
                    disable_proxy_s3=True,
                    s3_max_connections=50,
                    sse_enabled=False,
                ),
            )
        else:
            print(f"S3 oplog store {store_id} already configured. Updating...")
            s3_os_resource.update(
                path_params=s3_os_resource.UpdatePathParams(
                    s3_oplog_config_id=store_id
                ),
                query_params=None,
                body_params=s3_os_resource.UpdateBodyParams(
                    assignment_enabled=True,
                    uri=f"mongodb://{user}:{pwd}@{hosts_str}/?authSource=admin",
                    accepted_tos=True,
                    path_style_access_enabled=False,
                    s3_auth_method=S3AuthMethod.IAM_ROLE,
                    s3_bucket_endpoint=bucket_endpoint,
                    s3_bucket_name=bucket_name,
                    disable_proxy_s3=True,
                    s3_max_connections=50,
                    sse_enabled=False,
                ),
            )
elif store_type == "blockstore":
    # Configure blockstore for backup.
    if backup_type == "mongo":
        # Use MongoDB replica set for blockstore.
        bs_resource = client.blockstore_resource
        response = bs_resource.get_by_id(
            path_params=bs_resource.GetByIdPathParams(blockstore_id=store_id),
            query_params=None,
        )
        if "error" in response and response.get("error") == "404":
            print(f"Creating blockstore {store_id}...")
            bs_resource.create(
                query_params=None,
                body_params=bs_resource.CreateBodyParams(
                    id=store_id,
                    assignment_enabled=True,
                    uri=f"mongodb://{user}:{pwd}@{hosts_str}/?authSource=admin",
                ),
            )
        else:
            print(f"Blockstore {store_id} already configured. Updating...")
            bs_resource.update(
                path_params=bs_resource.UpdatePathParams(blockstore_id=store_id),
                query_params=None,
                body_params=bs_resource.UpdateBodyParams(
                    assignment_enabled=True,
                    uri=f"mongodb://{user}:{pwd}@{hosts_str}/?authSource=admin",
                ),
            )
    elif backup_type == "s3":
        # Use S3-compatible storage for blockstore.
        s3_bs_resource = client.s3_compatible_blockstore_resource
        response = s3_bs_resource.get_by_id(
            path_params=s3_bs_resource.GetByIdPathParams(
                s3_blockstore_config_id=store_id
            ),
            query_params=None,
        )
        bucket_name = os.environ.get("S3_BUCKET_NAME", "")
        bucket_endpoint = os.environ.get("S3_BUCKET_ENDPOINT", "")
        if "error" in response and response.get("error") == "404":
            print(f"Creating S3 blockstore {store_id}...")
            s3_bs_resource.create(
                query_params=None,
                body_params=s3_bs_resource.CreateBodyParams(
                    id=store_id,
                    assignment_enabled=True,
                    uri=f"mongodb://{user}:{pwd}@{hosts_str}/?authSource=admin",
                    accepted_tos=True,
                    path_style_access_enabled=False,
                    s3_auth_method=S3AuthMethod.IAM_ROLE,
                    s3_bucket_endpoint=bucket_endpoint,
                    s3_bucket_name=bucket_name,
                    disable_proxy_s3=True,
                    s3_max_connections=50,
                    sse_enabled=False,
                ),
            )
        else:
            print(f"S3 blockstore {store_id} already configured. Updating...")
            s3_bs_resource.update(
                path_params=s3_bs_resource.UpdatePathParams(
                    s3_blockstore_config_id=store_id
                ),
                query_params=None,
                body_params=s3_bs_resource.UpdateBodyParams(
                    assignment_enabled=True,
                    uri=f"mongodb://{user}:{pwd}@{hosts_str}/?authSource=admin",
                    accepted_tos=True,
                    path_style_access_enabled=False,
                    s3_auth_method=S3AuthMethod.IAM_ROLE,
                    s3_bucket_endpoint=bucket_endpoint,
                    s3_bucket_name=bucket_name,
                    disable_proxy_s3=True,
                    s3_max_connections=50,
                    sse_enabled=False,
                ),
            )

print(f"Successfully created {store_type} store {store_id}.")
