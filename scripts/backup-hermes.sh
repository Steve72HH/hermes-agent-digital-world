#!/usr/bin/env bash
set -Eeuo pipefail

STACK_DIR="${STACK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BACKUP_DIR="${BACKUP_DIR:-/opt/digital-world/backups/hermes}"
TS="$(date +%Y%m%d-%H%M%S)"
ARCHIVE="$BACKUP_DIR/hermes-digitalworld-$TS.tar.gz"

mkdir -p "$BACKUP_DIR"
cd "$STACK_DIR"

echo "[INFO] Backup Ziel: $ARCHIVE"
tar --warning=no-file-changed -czf "$ARCHIVE" \
  .env \
  docker-compose.yml \
  compose \
  scripts \
  docs \
  data/hermes

chmod 600 "$ARCHIVE"
echo "[OK] $ARCHIVE"
