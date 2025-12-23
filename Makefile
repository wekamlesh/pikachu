SHELL := /bin/bash
.DEFAULT_GOAL := help

-include .env
export

.PHONY: help setup deploy nginx

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