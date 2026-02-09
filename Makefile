.PHONY: help up down logs ps restart reset health validate clean demo sanity-check

help: ## Display this help message
	@echo "5G Health Platform Infrastructure - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## Start INFRA services only (db, nats, mqtt)
	@echo "Starting 5G Health Platform INFRAstructure..."
	docker compose --profile infra up -d
	@echo "Waiting for services to be healthy..."
	@sleep 5
	@$(MAKE) health

demo: ## Start ALL services (infra + app) for end-to-end demo
	@echo "Starting 5G Health Platform FULL DEMO..."
	docker compose --profile infra --profile app up -d --build
	@echo "Waiting for services to be healthy..."
	@sleep 10
	@$(MAKE) health
	@echo "Dashboard available at http://localhost:5173"
	@echo "Gateway available at http://localhost:8081"

down: ## Stop all services and remove volumes
	@echo "Stopping 5G Health Platform..."
	docker compose --profile infra --profile app down -v

logs: ## Show logs from all services (follow mode, tail 200)
	docker compose logs -f --tail=200

ps: ## Show status of all services
	docker compose ps -a

restart: ## Restart all services
	@echo "Restarting..."
	docker compose restart
	@sleep 5
	@$(MAKE) health

health: ## Check status of containers
	@echo "Checking containers..."
	@docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

sanity-check: ## Run curl checks against Gateway
	@echo "Running sanity check against Gateway (http://localhost:8081)..."
	@curl -s http://localhost:8081/health | grep "OK" && echo "✅ Gateway /health OK" || echo "❌ Gateway /health FAILED"

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

logs-nats: ## Show NATS logs
	docker compose logs -f nats

logs-gateway: ## Show Gateway logs
	docker compose logs -f realtime-gateway

logs-ingestion: ## Show Ingestion logs
	docker compose logs -f ingestion

