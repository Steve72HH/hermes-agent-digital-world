#!/usr/bin/env bash
set -Eeuo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERR ]${NC} $*" >&2; }
ask() { echo -e "${BLUE}[? ]${NC} $*"; }

if [[ $EUID -ne 0 ]]; then
  err "Bitte als root ausführen."
  exit 1
fi

cat <<'BANNER'
╔═══════════════════════════════════════════════════════╗
║ digital-world.dev Server Hardening                    ║
║ Optional: für frische Debian/Ubuntu Server             ║
╚═══════════════════════════════════════════════════════╝
BANNER

ask "Neuen Admin-User anlegen/prüfen [admin]:"
read -r NEW_USER
NEW_USER=${NEW_USER:-admin}

ask "SSH-Port [22]:"
read -r SSH_PORT
SSH_PORT=${SSH_PORT:-22}

if ! [[ "$SSH_PORT" =~ ^[0-9]+$ ]] || (( SSH_PORT < 1 || SSH_PORT > 65535 )); then
  err "Ungültiger SSH-Port"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq sudo curl ca-certificates openssh-server ufw fail2ban unattended-upgrades apt-listchanges >/dev/null

if ! id "$NEW_USER" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "$NEW_USER"
  log "User $NEW_USER angelegt"
fi
usermod -aG sudo "$NEW_USER"

if getent group docker >/dev/null; then
  usermod -aG docker "$NEW_USER" || true
fi

USER_HOME=$(eval echo "~$NEW_USER")
install -d -m 700 -o "$NEW_USER" -g "$NEW_USER" "$USER_HOME/.ssh"
if [[ -f /root/.ssh/authorized_keys ]]; then
  cp /root/.ssh/authorized_keys "$USER_HOME/.ssh/authorized_keys"
  chown "$NEW_USER:$NEW_USER" "$USER_HOME/.ssh/authorized_keys"
  chmod 600 "$USER_HOME/.ssh/authorized_keys"
else
  warn "/root/.ssh/authorized_keys nicht gefunden. SSH-Key für $NEW_USER manuell hinterlegen."
fi

cat >/etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd

[sshd]
enabled = true
port = $SSH_PORT
EOF
systemctl enable --now fail2ban

cat >/etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
systemctl enable --now unattended-upgrades || true

ufw --force default deny incoming >/dev/null
ufw --force default allow outgoing >/dev/null
ufw allow "$SSH_PORT/tcp" comment 'SSH' >/dev/null
ufw allow 80/tcp comment 'Traefik HTTP' >/dev/null
ufw allow 443/tcp comment 'Traefik HTTPS' >/dev/null
ufw --force enable >/dev/null

warn "Root-SSH und Passwortlogin werden erst nach deiner Bestätigung deaktiviert."
echo "Teste vorher in einem zweiten Terminal: ssh -p $SSH_PORT $NEW_USER@<server-ip>"
ask "Login als $NEW_USER getestet? Tippe exakt yes zum Fortfahren:"
read -r CONFIRM
if [[ "$CONFIRM" == "yes" ]]; then
  cp /etc/ssh/sshd_config "/etc/ssh/sshd_config.backup.$(date +%Y%m%d-%H%M%S)"
  mkdir -p /etc/ssh/sshd_config.d
  cat >/etc/ssh/sshd_config.d/99-digital-world-hardening.conf <<EOF
Port $SSH_PORT
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
X11Forwarding no
AllowUsers $NEW_USER
EOF
  sshd -t
  systemctl reload ssh || systemctl reload sshd
  log "SSH gehärtet. Root-Login aus, Passwortlogin aus."
else
  warn "SSH-Hardening übersprungen. User/Firewall/fail2ban sind eingerichtet."
fi

log "Fertig. UFW: 22/80/443 bzw. SSH-Port $SSH_PORT offen."
