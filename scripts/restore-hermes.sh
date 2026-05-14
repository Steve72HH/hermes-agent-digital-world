#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/hermes-digitalworld-YYYYmmdd-HHMMSS.tar.gz" >&2
  exit 1
fi

ARCHIVE="$1"
STACK_DIR="${STACK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

if [[ ! -f "$ARCHIVE" ]]; then
  echo "[ERR] Archiv nicht gefunden: $ARCHIVE" >&2
  exit 1
fi

cd "$STACK_DIR"
echo "[WARN] Stoppe Stack"
docker compose down || true

echo "[INFO] Restore nach $STACK_DIR"
tar -xzf "$ARCHIVE" -C "$STACK_DIR"
chmod 600 .env || true
chmod +x scripts/*.sh || true

echo "[INFO] Starte Stack"
docker compose up -d
sleep 10
bash scripts/fix-permissions.sh || true

docker compose ps
