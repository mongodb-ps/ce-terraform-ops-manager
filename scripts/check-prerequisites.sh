#!/usr/bin/env bash

set -euo pipefail

key_name="${1:-}"
if [ -z "$key_name" ]; then
  echo "Error: key_name argument is required." >&2
  echo "Usage: $0 <key_name>" >&2
  exit 1
fi

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

# The local SSH key pair must exist; the public key is imported to AWS.
key="$HOME/.ssh/$key_name"
pub="$key.pub"
if [ ! -f "$key" ] || [ ! -f "$pub" ]; then
  echo "Error: SSH key pair not found at $key and $pub." >&2
  echo "Create it first with: ssh-keygen -t ed25519 -C \"my-local-aws-key\" -f ~/.ssh/$key_name" >&2
  exit 1
fi

echo "Prerequisites satisfied: $python_version, pyomsdk and SSH key pair '$key_name' are available."
