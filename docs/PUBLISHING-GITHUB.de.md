# Veröffentlichung unter GitHub

## Empfohlener Name

```text
hermes-agent-digital-world
```

## Vor dem Push prüfen

```bash
cd /opt/digital-world/hermes
git status
find . -maxdepth 3 \( -name '.env' -o -path './data*' -o -path './backups*' -o -name '*oauth*' \) -print
```

Diese Dateien dürfen nicht gepusht werden:

- `.env`
- `data/`
- `backups/`
- private SSH Keys
- API Keys
- Passwörter
- OAuth-Dateien wie `google_oauth.json`

## Neues Repo lokal vorbereiten

```bash
cd /opt/digital-world/hermes
rm -rf .git
git init
git add .
git commit -m "Initial digital-world.dev Hermes Agent Traefik stack"
git branch -M main
```

## Remote setzen

```bash
git remote add origin git@github.com:Steve72HH/hermes-agent-digital-world.git
git push -u origin main
```

## GitHub Beschreibung

**Kurzbeschreibung:**

```text
Hermes Agent deployment stack for digital-world.dev using Docker Compose and Traefik.
```

**Topics:**

```text
hermes-agent docker compose traefik ai-agent self-hosted digital-world-dev debian automation
```

## Nach dem Push

- README auf GitHub prüfen
- Secrets prüfen: `.env` und `data/` dürfen nicht im Repo sein
- GitHub Actions `Validate` prüfen
- Release `v1.0.1` anlegen
