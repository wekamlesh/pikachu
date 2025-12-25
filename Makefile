SHELL := /bin/bash
.DEFAULT_GOAL := help

-include .env
export

.PHONY: help setup deploy nginx

help: ## Show this help message
	@printf "Targets:\n"
	@awk 'BEGIN {FS = ":.*##"; OFS = ""} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

##@ Initial Setup
setup: ## Setup VPS for initial deployment (Podman + Nginx deps)
	@echo "🔧 Setting up VPS..."
	@./scripts/setup-vps.sh

##@ Deploy
deploy: ## Deploy n8n stack
	@echo "🚀 Deploying..."
	@./scripts/deploy.sh

##@ Nginx
nginx: ## Configure Nginx reverse proxy + HTTPS for n8n
	@echo "🌐 Configuring Nginx..."
	@./scripts/setup-nginx.sh

##@ Backup
backup: ## Configure Nginx reverse proxy + HTTPS for n8n
	@echo "🌐 Run the backup..."
	@./scripts/backup.sh