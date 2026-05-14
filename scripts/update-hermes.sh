#!/usr/bin/env bash
set -Eeuo pipefail

STACK_DIR="${STACK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$STACK_DIR"

echo "[INFO] Stack: $STACK_DIR"
echo "[INFO] Pull image"
docker compose pull hermes

echo "[INFO] Restart"
docker compose up -d --remove-orphans

echo "[INFO] Status"
docker compose ps
