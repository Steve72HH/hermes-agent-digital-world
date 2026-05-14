# Security Notes

## Standard-Härtung dieser Variante

- keine direkten `ports:` auf dem Hermes-Container
- Zugriff nur über bestehendes Traefik-Netzwerk
- Dashboard hinter Traefik Basic Auth
- Security Header Middleware aktiv
- API-Server nicht öffentlich geroutet
- API-Key automatisch mit `openssl rand -hex 32`
- persistente Daten in `data/hermes`
- `.env` mit `chmod 600`
- OAuth/Auth-Dateien liegen unter `data/hermes/auth/` und werden nicht versioniert

## Wichtig

Hermes ist ein Agent mit Toolzugriff. Wer Zugriff auf Dashboard/API bekommt, kann je nach Hermes-Konfiguration weitreichende Aktionen auslösen. Deshalb:

- Dashboard-Passwort stark wählen
- API nicht ohne zwingenden Grund öffentlich routen
- API-Key niemals committen
- `.env` niemals veröffentlichen
- `data/hermes/auth/` niemals veröffentlichen
- Backups verschlüsselt ablegen
- Traefik/CrowdSec/Fail2Ban Logs überwachen

## GATEWAY_ALLOW_ALL_USERS

Diese Variante setzt standardmäßig:

```env
GATEWAY_ALLOW_ALL_USERS=true
```

Das ist hier vertretbar, weil der Zugriff auf das Dashboard per Traefik Basic Auth geschützt wird und die API nicht öffentlich geroutet ist. Wenn du zusätzliche Plattformen wie Telegram/Discord/Slack aktivierst, solltest du die jeweiligen Allowlisten sauber konfigurieren und `GATEWAY_ALLOW_ALL_USERS` wieder restriktiver setzen.

## Optionale öffentliche API

Wenn du `compose/docker-compose.api-router.yml` aktivierst, dann mindestens:

- starker `API_SERVER_KEY`
- Traefik Basic Auth
- IP-Allowlist oder VPN-Zugriff
- Rate-Limit Middleware
- Logging/Monitoring

## Empfohlene Ergänzungen

- CrowdSec Traefik Bouncer
- IP-Allowlist für Admin-Dienste
- Uptime Kuma Monitoring
- regelmäßiges `backup-hermes.sh`
- Wazuh/Auditd auf dem Host
- separater technischer Admin-User ohne Root-Login
