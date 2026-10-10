#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

echo "[pre-commit] dotnet build"
dotnet build AgentManage.slnx --nologo -v quiet
