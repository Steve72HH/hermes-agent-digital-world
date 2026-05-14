#!/usr/bin/env bash
set -Eeuo pipefail

STACK_DIR="${STACK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$STACK_DIR"

if ! docker compose ps -q hermes >/dev/null 2>&1; then
  echo "[ERR] Compose-Service 'hermes' nicht gefunden. Bist du im richtigen Stack-Verzeichnis?" >&2
  exit 1
fi

if ! docker compose ps --status running hermes | grep -q 'hermes'; then
  echo "[INFO] Hermes-Container ist nicht running. Starte Stack..."
  docker compose up -d hermes
  sleep 8
fi

echo "[INFO] Korrigiere /opt/data Rechte im Container"
docker compose exec -u root hermes sh -lc '
set -e
if id hermes >/dev/null 2>&1; then
  chown -R hermes:hermes /opt/data || true
else
  echo "[WARN] User hermes existiert nicht im Container; überspringe chown hermes:hermes" >&2
fi
chmod 700 /opt/data 2>/dev/null || true
chmod 700 /opt/data/auth 2>/dev/null || true
chmod 600 /opt/data/config.yaml 2>/dev/null || true
chmod 600 /opt/data/auth/google_oauth.json 2>/dev/null || true
echo "== /opt/data =="
ls -la /opt/data | sed -n "1,80p"
echo "== /opt/data/auth =="
ls -la /opt/data/auth 2>/dev/null || true
'
