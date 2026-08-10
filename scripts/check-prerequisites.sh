#!/usr/bin/env bash

set -euo pipefail

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
  echo "Install it with: python -m pip install pyomsdk" >&2
  exit 1
fi

echo "Prerequisites satisfied: $python_version and pyomsdk are available."
