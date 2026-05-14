#!/usr/bin/env bash
set -Eeuo pipefail

STACK_DIR="${STACK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$STACK_DIR"

if docker ps --format '{{.Names}}' | grep -qx 'digitalworld-hermes'; then
  bash scripts/fix-permissions.sh >/dev/null 2>&1 || true
  docker exec -it --user hermes digitalworld-hermes /opt/hermes/.venv/bin/hermes "$@"
else
  echo "[INFO] Container läuft nicht. Starte temporären Hermes-CLI-Container."
  docker run -it --rm \
    -v "$STACK_DIR/data/hermes:/opt/data" \
    nousresearch/hermes-agent:latest "$@"
fi
