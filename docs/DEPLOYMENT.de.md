# Deployment: Hermes Agent unter hermes.digital-world.dev

## Voraussetzungen

- Debian 12/13 oder Ubuntu 22.04/24.04
- Docker Engine + Docker Compose Plugin
- vorhandenes Traefik v2/v3 Setup
- externes Docker-Netzwerk `proxy`
- Traefik EntryPoint `websecure`
- funktionierender TLS CertResolver `le`
- DNS `hermes.digital-world.dev` zeigt auf den Traefik-Server

## 1. Traefik-Netzwerk prüfen

```bash
docker network ls | grep proxy || docker network create proxy
```

## 2. DNS prüfen

```bash
dig +short hermes.digital-world.dev A
dig +short hermes.digital-world.dev AAAA
curl -4 https://api.ipify.org; echo
```

Der A-Record muss auf den Server zeigen, auf dem Traefik Port 80/443 annimmt.

## 3. Installation

```bash
sudo mkdir -p /opt/digital-world/hermes
sudo chown -R "$USER:$USER" /opt/digital-world/hermes
cd /opt/digital-world/hermes
chmod +x scripts/*.sh
sudo bash scripts/install-hermes-traefik.sh
```

Der Installer startet den Stack und bietet danach den Model-Wizard an.

Empfehlung für kostenlos:

```text
Google Gemini via OAuth + Code Assist
Modell: gemini-3-flash-preview
```

## 4. Logs

```bash
cd /opt/digital-world/hermes
docker compose logs -f hermes
```

## 5. Status und echte Prüfung

Der Compose-Healthcheck ist absichtlich deaktiviert, weil Hermes je nach Version keinen stabilen generischen `/health`-Endpoint liefert. Nutze stattdessen:

```bash
bash scripts/healthcheck.sh
bash scripts/hermes-config.sh
```

## 6. Traefik-Router prüfen

```bash
docker inspect digitalworld-hermes --format '{{ json .Config.Labels }}' | jq
```

Ohne `jq`:

```bash
docker inspect digitalworld-hermes | grep -i traefik -A2 -B2
```

## 7. Modell nachträglich konfigurieren

```bash
cd /opt/digital-world/hermes
HERMES_HEADLESS=1 bash scripts/hermes-model.sh
bash scripts/hermes-config.sh
```

Die aktive Hermes-Konfiguration liegt im Container-Volume unter:

```text
/opt/data/config.yaml
```

OAuth-Dateien liegen unter:

```text
/opt/data/auth/
```

Diese Dateien niemals veröffentlichen.

## 8. Häufige Fehler

### Installer scheint direkt am Anfang zu hängen

Fix ist in dieser Version enthalten. Ursache war ein Prompt auf `stdout` innerhalb einer Command-Substitution. Prompts gehen jetzt auf `stderr`.

### Container wird `unhealthy` oder bleibt `starting`

Fix ist in dieser Version enthalten. Der Docker-Healthcheck ist deaktiviert. Nutze:

```bash
bash scripts/healthcheck.sh
```

### `No authenticated providers`

Prüfe zuerst:

```bash
bash scripts/hermes-config.sh
ls -la data/hermes/auth
```

Dann Rechte reparieren:

```bash
bash scripts/fix-permissions.sh
docker compose restart hermes
```

### 404 von Traefik

Ursachen:

- Container ist nicht im `proxy` Netzwerk
- falscher `TRAEFIK_NETWORK` Name
- falscher Hostname in `HERMES_DOMAIN`
- Traefik Docker Provider sieht den Container nicht

Fix:

```bash
docker network inspect proxy | grep digitalworld-hermes -n || true
docker compose up -d --force-recreate
```

### TLS-Zertifikat kommt nicht

Ursachen:

- DNS zeigt nicht auf diesen Server
- Port 80/443 durch Firewall blockiert
- CertResolver heißt bei dir nicht `le`

Fix in `.env`:

```env
TRAEFIK_CERTRESOLVER=deinresolver
TRAEFIK_ENTRYPOINT=websecure
```

Danach:

```bash
docker compose up -d --force-recreate
```

### Basic Auth funktioniert nicht

Hash neu erzeugen:

```bash
docker run --rm httpd:2.4-alpine htpasswd -nbB admin 'DEIN_PASSWORT' | sed -e 's/\$/\$\$/g'
```

Den kompletten Output in `.env` setzen:

```env
TRAEFIK_BASIC_AUTH_USERS=admin:$$2y$$...
```

Danach:

```bash
docker compose up -d --force-recreate
```
