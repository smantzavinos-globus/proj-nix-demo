#!/usr/bin/env bash
# Initialize or update all submodules
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$REPO_ROOT"

echo "==> Initializing/updating submodules..."
git submodule update --init --recursive

echo "==> Submodules ready:"
git submodule status
