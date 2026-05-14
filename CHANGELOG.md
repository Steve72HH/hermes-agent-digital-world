# Changelog

## 1.0.1 - 2026-05-14

- Fix: Installer-Prompts werden nicht mehr von Command-Substitution verschluckt.
- Fix: Docker-Healthcheck deaktiviert, damit Hermes nicht fälschlich `starting`/`unhealthy` bleibt.
- Fix: `init: true` entfernt und `TINI_SUBREAPER=1` gesetzt.
- Fix: `GATEWAY_ALLOW_ALL_USERS=true` ergänzt für Traefik-Basic-Auth-Betrieb.
- Fix: Hermes-Config-Pfad auf `/opt/data/config.yaml` dokumentiert und Scripts angepasst.
- Fix: OAuth/Auth-Rechte unter `/opt/data/auth/` per `fix-permissions.sh`.
- Neu: `scripts/hermes-model.sh` für Provider-/Modell-Konfiguration.
- Neu: `scripts/hermes-config.sh` zur sicheren Config-Prüfung ohne Token-Ausgabe.

## 1.0.0 - 2026-05-14

- Initiale digital-world.dev Variante
- Umstellung von Caddy auf Traefik Docker Labels
- Default Domain `hermes.digital-world.dev`
- Stack-Pfad `/opt/digital-world/hermes`
- Basic Auth Middleware
- Security Header Middleware
- optionaler API Router
- Backup/Restore/Update/Healthcheck Skripte
- Ansible-Beispiel
- GitHub Workflows und Templates
