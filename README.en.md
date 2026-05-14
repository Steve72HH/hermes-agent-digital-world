# Hermes Agent for digital-world.dev

Traefik-ready Hermes Agent deployment for `hermes.digital-world.dev`.

This is a cleaned-up digital-world.dev variant for an existing Docker/Traefik server environment. Caddy is removed, Traefik handles TLS and Basic Auth, and Hermes data is persisted at `./data/hermes -> /opt/data`.

## Production fixes included

- Installer prompt bug fixed: interactive prompts write to `stderr`.
- Docker healthcheck disabled to avoid false `starting`/`unhealthy` states.
- Compose `init: true` removed to avoid duplicated tini warnings.
- `TINI_SUBREAPER=1` configured.
- `GATEWAY_ALLOW_ALL_USERS=true` configured for a Traefik Basic Auth protected gateway.
- Hermes config path documented as `/opt/data/config.yaml`.
- OAuth/auth file ownership under `/opt/data/auth/` fixed via script.
- Added `scripts/hermes-model.sh`, `scripts/hermes-config.sh`, and `scripts/fix-permissions.sh`.

## Quickstart

```bash
sudo mkdir -p /opt/digital-world/hermes
sudo chown -R "$USER:$USER" /opt/digital-world/hermes
cd /opt/digital-world/hermes

git clone https://github.com/Steve72HH/hermes-agent-digital-world.git .
chmod +x scripts/*.sh
sudo bash scripts/install-hermes-traefik.sh
```

## Recommended free model

```text
Provider: Google Gemini via OAuth + Code Assist
Model:    gemini-3-flash-preview
```

Run:

```bash
cd /opt/digital-world/hermes
HERMES_HEADLESS=1 bash scripts/hermes-model.sh
bash scripts/hermes-config.sh
```

Expected config:

```yaml
model:
  default: gemini-3-flash-preview
  provider: google-gemini-cli
  base_url: cloudcode-pa://google
```

Never commit `.env`, `data/`, backups, OAuth files, API keys, or passwords.
