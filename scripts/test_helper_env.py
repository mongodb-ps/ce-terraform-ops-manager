"""Print bash export commands for selected parameters.

Reads the Ops Manager API key from om-admin.json and the OM access URL
from stage-1-output.json, then prints `export` lines to stdout:

    eval "$(python scripts/test_helper_env.py --url --public-key --private-key)"
    python scripts/destroy_project.py
"""
import argparse
import json
import os

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
    args = parser.parse_args()

    for key, val in vars(args).items():
        if val is not None:
            print(f'export {key.upper()}="{val}"')


if __name__ == "__main__":
    main()
