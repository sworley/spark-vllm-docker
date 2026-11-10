#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

# Keep the process in the foreground so systemd or another supervisor
# can track it and restart it if needed.
exec ./run-recipe.sh recipes/deepseek-v4-flash-vision-exp.yaml
