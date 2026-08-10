"""Build the input JSON consumed by a target script and feed it as stdin.

Reads the Ops Manager API key from om-admin.json and the OM access URL
from stage-1-output.json, then passes the assembled JSON to the target
Python script via stdin:

    python scripts/test_helper.py scripts/prepare_project.py --url --org-name
"""
import argparse
import json
import os
import subprocess
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load_json(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def main() -> None:
    admin = load_json(os.path.join(REPO_ROOT, "om-admin.json"))
    stage1 = load_json(os.path.join(REPO_ROOT, "stage-1-output.json"))
    url = stage1["om_access_url"]
    api_key = admin["programmaticApiKey"]
    public_key = api_key["publicKey"]
    private_key = api_key["privateKey"]
    org_name = "Default Organization"
    project_name = "Default Project"

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", nargs="?", const=url, default=None,
                        help="Ops Manager URL (default: value from stage-1-output.json)")
    parser.add_argument("--public-key", dest="public_key", nargs="?", const=public_key, default=None,
                        help="API public key (default: value from om-admin.json)")
    parser.add_argument("--private-key", dest="private_key", nargs="?", const=private_key, default=None,
                        help="API private key (default: value from om-admin.json)")
    parser.add_argument("--org-name", dest="org_name", nargs="?", const=org_name, default=None,
                        help="Organization name (default: %(const)s)")
    parser.add_argument("--project-name", dest="project_name", nargs="?", const=project_name, default=None,
                        help="Project name (default: %(const)s)")
    parser.add_argument("filename", help="Target Python script to receive the JSON via stdin")
    args = parser.parse_args()

    input_args = {
        key: val for key, val in vars(args).items()
        if key != "filename" and val is not None
    }

    subprocess.run(
        [sys.executable, args.filename],
        input=json.dumps(input_args),
        text=True,
    )


if __name__ == "__main__":
    main()
