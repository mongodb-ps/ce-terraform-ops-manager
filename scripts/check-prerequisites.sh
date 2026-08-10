#!/usr/bin/env bash

set -euo pipefail

# Optional: when provided, only used for an informational message about the SSH key pair.
key_name="${1:-}"

if ! command -v python >/dev/null 2>&1; then
  echo "Error: Python 3.10 is required but python was not found in PATH." >&2
  exit 1
fi

python_version=$(python --version 2>&1)
if [[ ! "$python_version" =~ ^Python\ ([0-9]+)\.([0-9]+) ]]; then
  echo "Error: Unable to determine the Python version from '$python_version'." >&2
  exit 1
fi

python_major=${BASH_REMATCH[1]}
python_minor=${BASH_REMATCH[2]}
if (( python_major < 3 || (python_major == 3 && python_minor < 10) )); then
  echo "Error: Python 3.10+ is required, but '$python_version' found." >&2
  exit 1
fi

if ! python -m pip show pyomsdk >/dev/null 2>&1; then
  echo "Error: pyomsdk is not installed for $python_version." >&2
  echo "Install with: python -m pip install pyomsdk" >&2
  exit 1
fi

# The local SSH key pair is optional: when it is missing, Terraform generates a new
# one (tls_private_key), imports it to AWS and saves it to ~/.ssh/<key_name>.
if [ -n "$key_name" ]; then
  key="$HOME/.ssh/$key_name"
  pub="$key.pub"
  if [ ! -f "$key" ] || [ ! -f "$pub" ]; then
    echo "Info: SSH key pair '$key_name' not found at $key and $pub; Terraform will generate a new one and save the private key to $key." >&2
  fi
fi

echo "Prerequisites satisfied: $python_version and pyomsdk are available."
