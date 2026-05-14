STACK_DIR ?= .

.PHONY: up down logs ps update backup health setup model cli config permissions hermes-config

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f hermes

ps:
	docker compose ps

update:
	bash scripts/update-hermes.sh

backup:
	bash scripts/backup-hermes.sh

health:
	bash scripts/healthcheck.sh

setup:
	bash scripts/hermes-setup.sh

model:
	bash scripts/hermes-model.sh

permissions:
	bash scripts/fix-permissions.sh

hermes-config:
	bash scripts/hermes-config.sh

cli:
	bash scripts/hermes-cli.sh

config:
	docker compose config
