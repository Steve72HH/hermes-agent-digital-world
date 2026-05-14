#!/usr/bin/env bash
set -Eeuo pipefail

STACK_DIR="${STACK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$STACK_DIR"
mkdir -p data/hermes

echo "[INFO] Der alte setup-Wizard ist in diesem Stack bewusst durch den Model-Wizard ersetzt."
echo "[INFO] Nutze für kostenlos: Google Gemini via OAuth + Code Assist -> gemini-3-flash-preview"
exec bash scripts/hermes-model.sh
