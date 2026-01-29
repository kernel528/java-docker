#!/usr/bin/env bash
set -euo pipefail

# Print tag blocks from .drone.yml for quick reference.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
drone_file="${repo_root}/.drone.yml"

if ! command -v rg >/dev/null 2>&1; then
	echo "rg (ripgrep) is required." >&2
	exit 1
fi

rg -n "tags:" -n "${drone_file}" -A 6
