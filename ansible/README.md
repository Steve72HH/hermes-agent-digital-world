# Ansible Deployment

Optionales Beispiel, falls du den Stack reproduzierbar auf mehreren Servern ausrollen willst.

## Vorbereitung

```bash
cp inventory.example.yml inventory.yml
```

Passe Host, User und Variablen an.

## Deployment

```bash
ansible-playbook -i inventory.yml deploy-hermes.yml
```

## Hinweis

`traefik_basic_auth_users` muss bereits Compose-kompatibel escaped sein:

```bash
docker run --rm httpd:2.4-alpine htpasswd -nbB admin 'PASSWORT' | sed -e 's/\$/\$\$/g'
```
