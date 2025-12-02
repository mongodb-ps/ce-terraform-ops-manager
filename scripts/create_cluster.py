"""Prepare backing replica set"""
import json
import os
import sys
from time import sleep
from om_api import api_get, api_put

params = json.loads(os.environ["PARAMS"])

om_url = params["om_url"]
project_id = params["project_id"]
public_key = params["public_key"]
private_key = params["private_key"]
rs = params["rs"]
hosts = params["hosts"]
user = params["user"]
pwd = params["pwd"]
metastore_version = params["metastore_version"]
metastore_fcv = params["metastore_fcv"]

api_url = f"{om_url}api/public/v1.0/groups/{project_id}/automationConfig"
auto_config_response = api_get(api_url, public_key, private_key, {})
auto_config = auto_config_response.json()

auto_config["auth"] = {
    "authoritativeSet": True,
    "autoAuthMechanism": "MONGODB-CR",
    "autoAuthMechanisms": ["MONGODB-CR", "SCRAM-SHA-256"],
    "autoAuthRestrictions": [],
    "autoPwd": "cilkIBAlUz9g8dNq33FWx8tH",
    "autoUser": "mms-automation",
    "deploymentAuthMechanisms": ["MONGODB-CR", "SCRAM-SHA-256"],
    "disabled": False,
    "key": "nd38J4PLSncTrqsBgZnZ9DgPFYnzuqdKDNGn8EF4xoPmluM5hfqh1J5fwMtk07ZkRi9zs67lSZz9loHLkUBSOCu9KZMxgMGzG9ZCYoxiq8yj3cjkCni979HK517xckYFLyOFep7yh2P1V11aHwgAm9uLSK9Mj3djImuj6PBnssqpHZw2lrm8UHui47CipnUiu9qgXo93Z043LZ56XdcexyiWJz2hQadObdRqhKVsF4KbKtgBPwDZfDb41cBuKCxcyi00D6KSfQtRyhvsBQpiQn1f3iY3joS551wopJo3IARf2GNfik6pFwHkk7bGoUSgVI0plCZOZ6XtZQm4DC1PxtdNEwlwrGvefAGCMGabfy4zhQEYi5rEX1LzxbgXGKctlGzii10VJhu0zjlEPxAQe3WQHihcaL93yhmPzgusEOJNY6R2wiwZkcM1MLDLUZ49JS9m00b042i0kRcH12OKtxQIAXKTGBce0td4cDt02m2oUPdhCUjx91Z0YkDqf7SeNDuO628N4nbrWYc0hUVbnHVAQekYrnTsJtPvnW90dxzHiHV6dVOr4sApIXZjO2CxXnQQYj9SGLN1lHQZbVOVXcFzvUqbq8HTPsWQT4uF5AaDnaVnDQNk2AWhXhcNsPsUKl4pYNf1IR9o2gEhpMY9taK399yYewXQXyHYCKT0cCbll6zHKU1fVr77BwxxY9Wf2Q89Iu1PWfsMxrFmDNX8Pz43cEAm9PcI85A2i0Dc5n5DDr7S6xMmVtmZRn52c5WbPVsVMwpkO3c7nirs3NmRdS8cvueqVnsWxpGanNx3rHtOYiUnLOsqXl61yNtjd06TNbZBbKmpwTDssroBp2RGkKoA2aJ8seIExEADjsBdMjadwvDEZuhNCyQKsQFpwgKvg0IucRd2dTgRGSR2h4674AzkfCcpFlkdcorJTatPbz7zK02KJmX3r2mCqQ9seC5LHcBYcM9jpAjY7wh6MNbnbgQAh5wCVSD6CXKIDIrw42a2CgZ2Lg2MAxbEen6GCLa4",
    "keyfile": "/var/lib/mongodb-mms-automation/keyfile",
    "keyfileWindows": "%SystemDrive%\\MMSAutomation\\versions\\keyfile",
    "usersDeleted": [],
    "usersWanted": [
        {
            "authenticationRestrictions": [],
            "db": "admin",
            "mechanisms": ["SCRAM-SHA-1", "SCRAM-SHA-256"],
            "roles": [{"db": "admin", "role": "root"}],
            "initPwd": f"{pwd}",
            "user": f"{user}",
        }
    ],
}
# Remove existing replica set config if exists
all_rs = [rs_cfg for rs_cfg in auto_config.get("replicaSets", []) if rs_cfg["_id"] != rs]
all_rs.append(
    {
        "_id": f"{rs}",
        "members": [
            {
                "_id": i,
                "arbiterOnly": False,
                "buildIndexes": True,
                "hidden": False,
                "host": f"{rs}_{i}",
                "priority": 1.0,
                "secondaryDelaySecs": 0,
                "votes": 1,
            } for i in range(len(hosts))
        ],
        "protocolVersion": "1",
        "settings": {},
    }
)
auto_config["replicaSets"] = all_rs
# Remove existing processes for the replica set
auto_config["processes"] = [proc for proc in auto_config.get("processes", []) if not proc["name"].startswith(f"{rs}_")]
auto_config["processes"].extend([
    {
        "args2_6": {
            "net": {"port": 27017},
            "replication": {"replSetName": f"{rs}"},
            "storage": {"dbPath": "/data/"},
            "systemLog": {"destination": "file", "path": "/data/mongodb.log"},
        },
        "auditLogRotate": {"sizeThresholdMB": 1000.0, "timeThresholdHrs": 24},
        "authSchemaVersion": 5,
        "disabled": False,
        "featureCompatibilityVersion": f"{metastore_fcv}",
        "horizons": {},
        "hostname": f"{host}",
        "logRotate": {"sizeThresholdMB": 1000.0, "timeThresholdHrs": 24},
        "manualMode": False,
        "name": f"{rs}_{i}",
        "processType": "mongod",
        "version": f"{metastore_version}",
    }
    for i, host in enumerate(hosts)
])

# Remove existing backup and monitoring versions for the hosts
auto_config["backupVersions"] = [bv for bv in auto_config.get("backupVersions", []) if bv["hostname"] not in hosts]
auto_config["backupVersions"].extend([
    {
        "baseUrl": f"{om_url}",
        "hostname": f"{host}",
        "logPath": "/var/log/mongodb-mms-automation/backup-agent.log",
        "logRotate": {"sizeThresholdMB": 1000.0, "timeThresholdHrs": 24},
        "name": "backup agent"
    }
    for host in hosts
])

# Remove existing monitoring versions for the hosts
auto_config["monitoringVersions"] = [mv for mv in auto_config.get("monitoringVersions", []) if mv["hostname"] not in hosts]
auto_config["monitoringVersions"].extend([
    {
        "baseUrl": f"{om_url}",
        "hostname": f"{host}",
        "logPath": "/var/log/mongodb-mms-automation/monitoring-agent.log",
        "logRotate": {"sizeThresholdMB": 1000.0, "timeThresholdHrs": 24},
        "name": "monitoring agent"
    }
    for host in hosts
])
response = api_put(api_url, public_key, private_key, auto_config)
if response.status_code != 200:
    print(f"Failed to update automation config: {response.text}")
    sys.exit(1)

# Wait for the automation config to be applied
status_url = f"{om_url}api/public/v1.0/groups/{project_id}/automationStatus"
while True:
    status_response = api_get(status_url, public_key, private_key, {})
    status = status_response.json()
    proc_statuses = [s["lastGoalVersionAchieved"] for s in status.get("processes", []) if s["name"].startswith(f"{rs}_")]
    goal_version = status.get("goalVersion")
    if all(v >= goal_version for v in proc_statuses):
        break
    print("Waiting for automation config to be applied...")
    print(f"Goal version: {goal_version}, Current process versions: {proc_statuses}")
    sleep(10)
print("Automation config applied.")
