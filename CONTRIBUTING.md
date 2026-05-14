# Contributing

Dieses Repository ist primär für das digital-world.dev Serverumfeld gebaut. Pull Requests sind willkommen, wenn sie diese Architektur respektieren:

- Docker Compose statt manueller Host-Installation
- Traefik als Reverse Proxy
- keine Secrets im Repo
- idempotente Skripte
- Debian/Ubuntu kompatibel
- klare Doku für Betrieb und Fehleranalyse

## Lokale Checks

```bash
bash -n scripts/*.sh
```

Mit ShellCheck, falls installiert:

```bash
shellcheck scripts/*.sh
```
