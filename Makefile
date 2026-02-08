.PHONY: help up down logs ps restart reset health validate clean

help: ## Display this help message
	@echo "5G Health Platform Infrastructure - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## Start all services
	@echo "Starting 5G Health Platform infrastructure..."
	docker compose up -d
	@echo "Waiting for services to be healthy..."
	@sleep 5
	@$(MAKE) health

down: ## Stop all services
	@echo "Stopping 5G Health Platform infrastructure..."
	docker compose down

logs: ## Show logs from all services (follow mode)
	docker compose logs -f

ps: ## Show status of all services
	docker compose ps

restart: ## Restart all services
	@echo "Restarting 5G Health Platform infrastructure..."
	docker compose restart
	@sleep 5
	@$(MAKE) health

reset: ## Stop services, remove volumes, and start fresh
	@echo "⚠️  WARNING: This will delete all data in volumes!"
	@echo "Press Ctrl+C within 5 seconds to cancel..."
	@sleep 5
	docker compose down -v
	docker compose up -d
	@echo "Waiting for services to be healthy..."
	@sleep 5
	@$(MAKE) health

health: ## Check health status of all services
	@echo "Checking service health..."
	@docker compose ps --format "table {{.Name}}\t{{.Status}}"

validate: ## Validate docker-compose.yml configuration
	@echo "Validating docker-compose configuration..."
	docker compose config --quiet && echo "✓ Configuration is valid" || echo "✗ Configuration has errors"

clean: ## Remove stopped containers and dangling images
	@echo "Cleaning up Docker resources..."
	docker compose down --remove-orphans
	docker system prune -f

# Service-specific logs
logs-postgres: ## Show PostgreSQL logs
	docker compose logs -f postgres

logs-redis: ## Show Redis logs
	docker compose logs -f redis

logs-nats: ## Show NATS logs
	docker compose logs -f nats

logs-mqtt: ## Show Mosquitto logs
	docker compose logs -f mosquitto
