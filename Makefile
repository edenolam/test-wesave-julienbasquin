COMPOSE := docker compose
TEST_DATABASE_URL := postgres://portfolio:development@db/portfolio_test

.DEFAULT_GOAL := help
.PHONY: help setup build up down restart logs status console shell db-prepare migrate seed test lint lint-fix security check demo

help: ## Afficher les commandes disponibles
	@awk 'BEGIN {FS = ":.*## "} /^[a-z-]+:.*## / {printf "  make %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Installer et démarrer la démonstration complète
	$(MAKE) build
	$(MAKE) db-prepare
	$(MAKE) seed
	$(MAKE) up
	@echo "Prêt : http://localhost:3000/docs/index.html — connexion : demo@example.test / Demonstration-12345!"

build: ## Construire l'image Rails
	$(COMPOSE) build

up: ## Démarrer les services en arrière-plan
	$(COMPOSE) up -d --wait --wait-timeout 120

down: ## Arrêter les services en conservant les données
	$(COMPOSE) down

restart: ## Redémarrer l'API
	$(COMPOSE) restart api

logs: ## Suivre les logs de l'API
	$(COMPOSE) logs -f api

status: ## Afficher l'état des services
	$(COMPOSE) ps

console: ## Ouvrir la console Rails
	$(COMPOSE) run --rm api bin/rails console

shell: ## Ouvrir un terminal dans un conteneur Rails
	$(COMPOSE) run --rm api bash

db-prepare: ## Créer la base et appliquer les migrations
	$(COMPOSE) run --rm api bin/rails db:prepare

migrate: ## Appliquer les migrations
	$(COMPOSE) run --rm api bin/rails db:migrate

seed: ## Charger les données de démonstration
	$(COMPOSE) run --rm api bin/rails db:seed

test: ## Préparer la base de test et exécuter les tests
	$(COMPOSE) run --rm -e RAILS_ENV=test -e DATABASE_URL=$(TEST_DATABASE_URL) api sh -c "bin/rails db:prepare && bin/rails test"

lint: ## Vérifier le style Ruby
	$(COMPOSE) run --rm --no-deps api bin/rubocop

lint-fix: ## Corriger automatiquement le style Ruby
	$(COMPOSE) run --rm --no-deps api bin/rubocop -a

security: ## Analyser le code et les dépendances
	$(COMPOSE) run --rm --no-deps api bin/brakeman --no-pager
	$(COMPOSE) run --rm --no-deps api bin/bundler-audit

check: ## Exécuter les tests, le style et les analyses de sécurité
	$(MAKE) test
	$(MAKE) lint
	$(MAKE) security

demo: ## Exécuter une démonstration HTTP complète (crée des données)
	$(MAKE) seed
	$(MAKE) up
	$(COMPOSE) exec -T api ruby script/demo.rb
