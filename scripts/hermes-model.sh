#!/usr/bin/env bash
set -Eeuo pipefail

STACK_DIR="${STACK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$STACK_DIR"

if ! docker compose ps --status running hermes | grep -q 'hermes'; then
  echo "[INFO] Hermes-Container läuft nicht. Starte Stack..."
  docker compose up -d hermes
  sleep 10
fi

bash scripts/fix-permissions.sh || true

HEADLESS="${HERMES_HEADLESS:-1}"
echo "[INFO] Starte Hermes Model-Wizard"
echo "[INFO] Empfehlung für kostenlos: Google Gemini via OAuth + Code Assist -> gemini-3-flash-preview"

if docker compose exec -u hermes -e HERMES_HEADLESS="$HEADLESS" hermes sh -lc '/opt/hermes/.venv/bin/hermes model'; then
  bash scripts/fix-permissions.sh || true
  echo "[INFO] Starte Hermes neu, damit Gateway/Web das neue Modell lädt"
  docker compose restart hermes
else
  echo "[ERR] Model-Wizard fehlgeschlagen" >&2
  exit 1
fi
