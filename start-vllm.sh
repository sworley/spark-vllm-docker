#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

# Keep the process in the foreground so systemd or another supervisor
# can track it and restart it if needed. On stop/termination ('systemctl
# stop', or the NVIDIA Sync custom job's X), tear the WHOLE cluster down,
# not just the head. 'stop-vllm.sh' -> 'launch-cluster.sh stop' reads the
# pinned .env (CLUSTER_NODES=10.20.0.11,10.20.0.12) and stops head + worker.
# NOTE: do NOT use `exec` here — the trap must fire.
trap './stop-vllm.sh' EXIT INT TERM

./run-recipe.sh recipes/deepseek-v4-flash-vision-exp.yaml
