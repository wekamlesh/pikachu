SHELL := /bin/bash
.DEFAULT_GOAL := help

# Load environment variables
-include .env
export

.PHONY: help setup

##@ Initial Setup

setup: ## Setup VPS for initial deployment
	@echo "🔧 Setting up VPS..."
	@./scripts/setup-vps.sh

## Deploy 
deploy: ## Deploy n8n stack (auto-detects caddy)
	@echo "🚀 Deploying..."
	@./scripts/deploy.sh
