# Hermes Agent für digital-world.dev

![digital-world.dev](https://img.shields.io/badge/digital--world.dev-Hermes%20Agent-00d4ff)
![Reverse Proxy](https://img.shields.io/badge/Traefik-ready-24a1c1)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

**Traefik-fähiger Hermes-Agent-Stack für `hermes.digital-world.dev` in einem bestehenden Docker-/Debian-Serverumfeld.**

Diese Version ist die bereinigte digital-world.dev-Variante: Caddy wurde entfernt, Traefik übernimmt TLS/Reverse Proxy, das Dashboard liegt hinter Basic Auth, die Hermes-Daten bleiben persistent unter `./data/hermes -> /opt/data`.

## Fixes in dieser Version

Diese Version enthält die Fehlerbereinigung aus dem echten Server-Test:

- Installer-Prompt hängt nicht mehr: interaktive Prompts gehen jetzt korrekt auf `stderr`.
- Docker-Healthcheck ist deaktiviert: Hermes landet dadurch nicht mehr fälschlich in `starting`/`unhealthy`.
- `init: true` entfernt: keine störende doppelte `tini`-Warnung mehr.
- `TINI_SUBREAPER=1` gesetzt.
- `GATEWAY_ALLOW_ALL_USERS=true` gesetzt, weil der Zugriff über Traefik Basic Auth geschützt wird.
- Hermes-Konfiguration wird korrekt unter `/opt/data/config.yaml` erwartet, nicht unter `~/.hermes/config.yaml`.
- OAuth/Auth-Dateien unter `/opt/data/auth/` werden per Script auf den Container-User `hermes` korrigiert.
- Neuer Model-Wizard: `scripts/hermes-model.sh`.
- Neue Config-Prüfung: `scripts/hermes-config.sh`.
- Neuer Permissions-Fix: `scripts/fix-permissions.sh`.

## Zielbild

```text
Internet
  │
  ▼
Traefik v2/v3
  ├─ EntryPoint: websecure / :443
  ├─ TLS: vorhandener Resolver, default: le
  ├─ Middleware: Basic Auth + Security Header
  └─ Router: Host(`hermes.digital-world.dev`)
        │
        ▼
Docker network: proxy
        │
        ▼
Hermes Agent Container
  ├─ Dashboard intern: :9119
  ├─ Gateway/API intern: :8642
  └─ Persistenz: ./data/hermes -> /opt/data
```

## Schnellstart

```bash
sudo mkdir -p /opt/digital-world/hermes
sudo chown -R "$USER:$USER" /opt/digital-world/hermes
cd /opt/digital-world/hermes

git clone https://github.com/Steve72HH/hermes-agent-digital-world.git .
chmod +x scripts/*.sh
sudo bash scripts/install-hermes-traefik.sh
```

Default-Werte:

| Einstellung | Default |
|---|---:|
| Domain | `hermes.digital-world.dev` |
| Stack-Pfad | `/opt/digital-world/hermes` |
| Traefik-Netzwerk | `proxy` |
| Traefik EntryPoint | `websecure` |
| Traefik Certresolver | `le` |
| Dashboard-Port intern | `9119` |
| API-Port intern | `8642` |

## Kostenloses Modell konfigurieren

Empfehlung:

```text
Provider: Google Gemini via OAuth + Code Assist
Modell:   gemini-3-flash-preview
```

Wizard starten:

```bash
cd /opt/digital-world/hermes
HERMES_HEADLESS=1 bash scripts/hermes-model.sh
```

Danach prüfen:

```bash
bash scripts/hermes-config.sh
```

Erwartung:

```yaml
model:
  default: gemini-3-flash-preview
  provider: google-gemini-cli
  base_url: cloudcode-pa://google
```

Wichtig: Dateien unter `data/hermes/auth/` niemals veröffentlichen. Diese enthalten OAuth-/Token-Daten.

## Betrieb

```bash
cd /opt/digital-world/hermes

docker compose ps
docker compose logs -f hermes
bash scripts/healthcheck.sh
bash scripts/hermes-config.sh
```

Browser:

```text
https://hermes.digital-world.dev
```

CLI öffnen:

```bash
bash scripts/hermes-cli.sh
```

Update:

```bash
bash scripts/backup-hermes.sh
bash scripts/update-hermes.sh
```

Backup:

```bash
bash scripts/backup-hermes.sh
```

Restore:

```bash
bash scripts/restore-hermes.sh /pfad/zum/hermes-digitalworld-YYYYmmdd-HHMMSS.tar.gz
```

## Wichtige Dateien

```text
.
├── docker-compose.yml                     # Hauptstack: Hermes + Traefik Labels
├── .env.example                           # Beispielkonfiguration
├── compose/
│   └── docker-compose.api-router.yml      # optional: API öffentlich über api.hermes...
├── scripts/
│   ├── install-hermes-traefik.sh          # One-shot Installer
│   ├── hermes-model.sh                    # Provider/Modell konfigurieren
│   ├── hermes-config.sh                   # aktive Config anzeigen
│   ├── fix-permissions.sh                 # /opt/data Rechte im Container korrigieren
│   ├── healthcheck.sh                     # lokaler Container-/Port-/Traefik-Test
│   ├── hermes-cli.sh                      # Hermes TUI/CLI öffnen
│   ├── update-hermes.sh                   # Image pull + Neustart
│   ├── backup-hermes.sh                   # tar.gz Backup von Konfig + Daten
│   ├── restore-hermes.sh                  # Restore aus Backup
│   └── harden-server.sh                   # optionales Host-Hardening
├── ansible/
├── docs/
└── .github/
```

## API bewusst nicht öffentlich

Der Hermes API-Server ist im Container auf `0.0.0.0:8642` aktiv, aber standardmäßig nicht öffentlich geroutet. Das ist Absicht: Die API kann Agentenfunktionen und Tooling auslösen.

Optional aktivieren:

```bash
docker compose -f docker-compose.yml -f compose/docker-compose.api-router.yml up -d
```

Dann wird `https://api.hermes.digital-world.dev/v1` geroutet. Nur mit starkem API-Key, Auth-Middleware und sinnvoller IP-/Firewall-Absicherung betreiben.



Diese Version basiert konzeptionell auf `oliverhees/hermes-agent-oneshot-installer`, wurde aber auf ein bestehendes Traefik-/digital-world.dev-Serverumfeld umgebaut. Die Ursprungsversion ist MIT-lizenziert. Siehe `NOTICE` und `LICENSE`.
