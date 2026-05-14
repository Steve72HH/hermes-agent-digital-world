#!/usr/bin/env bash
set -Eeuo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERR ]${NC} $*" >&2; }
# Important: ask() writes to stderr. read_default() returns the selected value on stdout.
ask() { echo -e "${BLUE}[? ]${NC} $*" >&2; }
hr() { echo "----------------------------------------------------------------"; }

DEFAULT_DOMAIN="hermes.digital-world.dev"
DEFAULT_STACK_DIR="/opt/digital-world/hermes"
DEFAULT_TRAEFIK_NETWORK="proxy"
DEFAULT_ENTRYPOINT="websecure"
DEFAULT_CERTRESOLVER="le"
DEFAULT_TZ="Europe/Berlin"

require_root() {
  if [[ $EUID -ne 0 ]]; then
    err "Bitte als root ausführen: sudo bash scripts/install-hermes-traefik.sh"
    exit 1
  fi
}

ensure_tty() {
  if [[ ! -t 0 ]]; then
    if [[ -t 1 && -r /dev/tty ]]; then
      exec </dev/tty
    else
      err "Kein TTY für interaktive Eingaben verfügbar."
      exit 1
    fi
  fi
}

read_default() {
  local prompt="$1" default="$2" var
  ask "$prompt [$default]:"
  read -r var
  printf '%s' "${var:-$default}"
}

escape_dollars() {
  sed 's/\$/\$\$/g'
}

install_docker_if_missing() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker vorhanden: $(docker --version)"
  else
    warn "Docker fehlt. Installation über get.docker.com wird gestartet."
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
  fi

  if ! docker compose version >/dev/null 2>&1; then
    err "Docker Compose Plugin fehlt. Bitte docker-compose-plugin installieren."
    exit 1
  fi
}

ensure_tools() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq curl ca-certificates dnsutils openssl tar gzip coreutils rsync apache2-utils >/dev/null
}

ensure_network() {
  local network="$1"
  if docker network inspect "$network" >/dev/null 2>&1; then
    log "Traefik-Netzwerk '$network' existiert."
  else
    warn "Docker-Netzwerk '$network' existiert nicht."
    ask "Soll ich '$network' als externes Traefik-Netzwerk anlegen? [Y/n]"
    read -r confirm
    if [[ ! "${confirm:-y}" =~ ^[Nn]$ ]]; then
      docker network create "$network" >/dev/null
      log "Netzwerk '$network' angelegt."
    else
      err "Ohne externes Traefik-Netzwerk kann der Stack nicht starten."
      exit 1
    fi
  fi
}

check_dns() {
  local domain="$1"
  local server_ip domain_ip
  server_ip=$(curl -sf https://api.ipify.org 2>/dev/null || curl -sf https://icanhazip.com 2>/dev/null || true)
  domain_ip=$(dig +short "$domain" A | tail -n1 || true)

  log "Server-IP: ${server_ip:-unbekannt}"
  log "DNS A für $domain: ${domain_ip:-nicht gesetzt}"

  if [[ -z "${domain_ip:-}" ]]; then
    warn "Für $domain wurde kein A-Record gefunden. Traefik/Let's Encrypt funktioniert erst nach DNS-Fix."
  elif [[ -n "${server_ip:-}" && "$server_ip" != "$domain_ip" ]]; then
    warn "Domain zeigt auf $domain_ip, dieser Server meldet $server_ip. Prüfe DNS/Proxy-Ziel."
  else
    log "DNS sieht passend aus."
  fi
}

generate_basic_auth() {
  local user="$1" pass="$2"
  if command -v htpasswd >/dev/null 2>&1; then
    htpasswd -nbB "$user" "$pass" | escape_dollars
  else
    docker run --rm httpd:2.4-alpine htpasswd -nbB "$user" "$pass" | escape_dollars
  fi
}

copy_repo_files() {
  local source_dir="$1" target_dir="$2"
  local source_real target_real

  mkdir -p "$target_dir"
  source_real=$(realpath -m "$source_dir")
  target_real=$(realpath -m "$target_dir")

  if [[ "$source_real" == "$target_real" ]]; then
    log "Quell- und Zielverzeichnis sind identisch. Kopieren übersprungen."
    return 0
  fi

  rsync -a \
    --exclude '.git' \
    --exclude '.env' \
    --exclude 'data' \
    --exclude 'backups' \
    "$source_real"/ "$target_real"/
}

main() {
  require_root
  ensure_tty

  clear || true
  cat <<'BANNER'
╔══════════════════════════════════════════════════════════════╗
║  digital-world.dev · Hermes Agent · Traefik Installer        ║
║  Ziel: hermes.digital-world.dev über vorhandenes Traefik      ║
╚══════════════════════════════════════════════════════════════╝
BANNER

  hr
  log "Konfiguration"
  hr

  local domain stack_dir network entrypoint certresolver tz admin_user admin_pass api_key basicauth source_dir
  domain=$(read_default "Domain" "$DEFAULT_DOMAIN")
  stack_dir=$(read_default "Stack-Verzeichnis" "$DEFAULT_STACK_DIR")
  network=$(read_default "Traefik Docker Netzwerk" "$DEFAULT_TRAEFIK_NETWORK")
  entrypoint=$(read_default "Traefik EntryPoint" "$DEFAULT_ENTRYPOINT")
  certresolver=$(read_default "Traefik CertResolver" "$DEFAULT_CERTRESOLVER")
  tz=$(read_default "Timezone" "$DEFAULT_TZ")

  ask "Dashboard Benutzer [admin]:"
  read -r admin_user
  admin_user=${admin_user:-admin}

  ask "Dashboard Passwort leer lassen = automatisch generieren:"
  read -rs admin_pass
  echo
  if [[ -z "$admin_pass" ]]; then
    admin_pass=$(openssl rand -base64 24 | tr -d '/+=' | cut -c1-22)
    GENERATED_PASS=1
  else
    GENERATED_PASS=0
  fi

  api_key=$(openssl rand -hex 32)

  hr
  log "Geplante Installation"
  hr
  echo "Domain:              $domain"
  echo "Stack-Verzeichnis:   $stack_dir"
  echo "Traefik-Netzwerk:    $network"
  echo "Traefik EntryPoint:  $entrypoint"
  echo "CertResolver:        $certresolver"
  echo "Dashboard Benutzer:  $admin_user"
  echo
  ask "Installation fortsetzen? [Y/n]"
  read -r confirm
  [[ "${confirm:-y}" =~ ^[Nn]$ ]] && exit 0

  hr
  log "System prüfen"
  hr
  ensure_tools
  install_docker_if_missing
  ensure_network "$network"
  check_dns "$domain"

  hr
  log "Dateien schreiben"
  hr
  source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  copy_repo_files "$source_dir" "$stack_dir"
  cd "$stack_dir"

  mkdir -p data/hermes backups logs
  chmod 700 data/hermes || true

  log "Basic-Auth Hash generieren"
  basicauth=$(generate_basic_auth "$admin_user" "$admin_pass")

  cat > .env <<EOF_ENV
COMPOSE_PROJECT_NAME=digitalworld-hermes
HERMES_DOMAIN=$domain
HERMES_API_DOMAIN=api.$domain
TRAEFIK_NETWORK=$network
TRAEFIK_ENTRYPOINT=$entrypoint
TRAEFIK_CERTRESOLVER=$certresolver
TRAEFIK_BASIC_AUTH_USERS=$basicauth
HERMES_IMAGE=nousresearch/hermes-agent:latest
HERMES_DASHBOARD_TUI=0
GATEWAY_ALLOW_ALL_USERS=true
API_SERVER_KEY=$api_key
TZ=$tz
DW_OWNER=digital-world.dev
DW_SERVICE=hermes-agent
DW_ENV=prod
DW_MAINTAINER=kontakt@digital-world.dev
EOF_ENV
  chmod 600 .env
  chmod +x scripts/*.sh

  hr
  log "Stack starten"
  hr
  docker compose pull
  docker compose up -d
  sleep 12

  log "Berechtigungen korrigieren"
  bash scripts/fix-permissions.sh || warn "Rechtekorrektur konnte nicht vollständig ausgeführt werden."

  hr
  log "Hermes Modell konfigurieren"
  hr
  echo "Empfehlung kostenlos:"
  echo "  Provider: Google Gemini via OAuth + Code Assist"
  echo "  Modell:   gemini-3-flash-preview"
  echo
  ask "Model-Wizard jetzt starten? [Y/n]"
  read -r confirm
  if [[ ! "${confirm:-y}" =~ ^[Nn]$ ]]; then
    HERMES_HEADLESS=1 bash scripts/hermes-model.sh || warn "Model-Wizard wurde beendet oder hat Fehler gemeldet. Du kannst ihn später erneut starten: bash scripts/hermes-model.sh"
  else
    warn "Model-Wizard übersprungen. Nachholen mit: bash scripts/hermes-model.sh"
  fi

  hr
  log "Finaler Status"
  hr
  docker compose ps
  bash scripts/hermes-config.sh || true

  hr
  echo -e "${GREEN}Installation abgeschlossen.${NC}"
  hr
  echo "Dashboard: https://$domain"
  echo "Benutzer:  $admin_user"
  if [[ "${GENERATED_PASS:-0}" -eq 1 ]]; then
    echo "Passwort:  $admin_pass  <-- JETZT SICHERN"
  else
    echo "Passwort:  (dein eingegebenes Passwort)"
  fi
  echo "Stack:     $stack_dir"
  echo "API-Key:   $stack_dir/.env"
  echo
  echo "Nächste Checks:"
  echo "  cd $stack_dir"
  echo "  docker compose logs -f hermes"
  echo "  bash scripts/healthcheck.sh"
  echo "  bash scripts/hermes-config.sh"
}

main "$@"
