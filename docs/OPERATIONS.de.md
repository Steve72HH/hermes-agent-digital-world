# Betrieb

## Status

```bash
cd /opt/digital-world/hermes
docker compose ps
bash scripts/healthcheck.sh
bash scripts/hermes-config.sh
```

## Logs

```bash
docker compose logs -f hermes
```

## Modell/Provider konfigurieren

Empfehlung kostenlos:

```text
Google Gemini via OAuth + Code Assist
Modell: gemini-3-flash-preview
```

Start:

```bash
HERMES_HEADLESS=1 bash scripts/hermes-model.sh
```

Danach:

```bash
bash scripts/hermes-config.sh
```

## Rechte reparieren

Wenn die Weboberfläche `No authenticated providers` zeigt oder OAuth-Dateien root-owned sind:

```bash
bash scripts/fix-permissions.sh
docker compose restart hermes
```

## CLI öffnen

```bash
bash scripts/hermes-cli.sh
```

## Update

```bash
bash scripts/backup-hermes.sh
bash scripts/update-hermes.sh
```

## Backup

```bash
bash scripts/backup-hermes.sh
```

Standardziel:

```text
/opt/digital-world/backups/hermes
```

## Restore

```bash
bash scripts/restore-hermes.sh /opt/digital-world/backups/hermes/hermes-digitalworld-YYYYmmdd-HHMMSS.tar.gz
```

## API-Key anzeigen

```bash
sudo grep API_SERVER_KEY /opt/digital-world/hermes/.env
```

## OpenAI-kompatibler API-Endpunkt intern

Im Container:

```text
http://127.0.0.1:8642/v1
```

Aus demselben Docker-Netzwerk:

```text
http://digitalworld-hermes:8642/v1
```

## Öffentliche API nur optional

Die öffentliche API ist nicht standardmäßig geroutet. Aktivierung:

```bash
docker compose -f docker-compose.yml -f compose/docker-compose.api-router.yml up -d
```

URL:

```text
https://api.hermes.digital-world.dev/v1
```

Nur mit starkem `API_SERVER_KEY`, Basic Auth und idealerweise IP-Allowlist betreiben.
