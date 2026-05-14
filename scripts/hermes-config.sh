#!/usr/bin/env bash
set -Eeuo pipefail

STACK_DIR="${STACK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$STACK_DIR"

docker compose exec hermes sh -lc '
echo "== Hermes model config =="
grep -A8 -Ei "^model:" /opt/data/config.yaml 2>/dev/null || true

echo
echo "== provider/auth hints =="
grep -A10 -B3 -Ei "provider|gemini|google|anthropic|claude" /opt/data/config.yaml 2>/dev/null | sed -n "1,120p" || true

echo
echo "== auth directory; do not print token files =="
ls -la /opt/data/auth 2>/dev/null || true
'
