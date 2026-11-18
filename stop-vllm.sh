#!/usr/bin/env bash
# Stop the deepseek-v4-flash-vision-exp cluster (head + tensor-parallel worker).
#
# 'launch-cluster.sh stop' reads the pinned topology (.env:
# CLUSTER_NODES=10.20.0.11,10.20.0.12) and stops BOTH the head and the worker
# (via ssh). This is deterministic, unlike the NVIDIA Sync custom job's X,
# which only tore down the primary node.
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

./launch-cluster.sh stop
