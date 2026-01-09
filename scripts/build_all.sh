#!/usr/bin/env bash
# Build all submodules using nix build
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "==> Building corelib..."
(cd "$REPO_ROOT/corelib" && nix build)

echo "==> Building viewer..."
(cd "$REPO_ROOT/viewer" && nix build)

echo "==> Building editor..."
(cd "$REPO_ROOT/editor" && nix build)

echo "==> All builds succeeded!"
