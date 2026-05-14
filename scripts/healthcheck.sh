#!/usr/bin/env bash
set -Eeuo pipefail

STACK_DIR="${STACK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$STACK_DIR"

if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  set -a; source .env; set +a
fi

DOMAIN="${HERMES_DOMAIN:-hermes.digital-world.dev}"

echo "[INFO] Docker status"
docker compose ps

echo
echo "[INFO] Hermes Prozesse"
docker compose exec hermes sh -lc 'ps aux | grep -E "hermes|gateway|dashboard" | grep -v grep || true' || true

echo
echo "[INFO] Interner Porttest im Container"
docker compose exec hermes sh -lc '
python - <<PY
import socket
for port in (9119, 8642):
    try:
        s = socket.create_connection(("127.0.0.1", port), 5)
        s.close()
        print(f"OK: Port {port} offen")
    except Exception as e:
        print(f"WARN: Port {port} nicht erreichbar: {e}")
PY
' || true

echo
echo "[INFO] Modell-Konfiguration"
docker compose exec hermes sh -lc 'grep -A8 -Ei "^model:" /opt/data/config.yaml 2>/dev/null || true' || true

echo
echo "[INFO] Traefik route quick check"
if command -v curl >/dev/null 2>&1; then
  curl -Ik "https://$DOMAIN" || true
else
  echo "curl nicht installiert"
fi
