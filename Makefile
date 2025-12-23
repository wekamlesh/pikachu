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


