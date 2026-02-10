# 5G Health Platform Infrastructure
Local development infrastructure for the 5G Health Platform. This repository provides a `docker-compose` setup to run the core infrastructure services (NATS, TimescaleDB, Redis, Mosquitto) and the application services (Gateway, Ingestion, Dashboard).

[![Docker Compose Validation](../../actions/workflows/docker-compose-validation.yml/badge.svg)](../../actions/workflows/docker-compose-validation.yml)

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js 18+ (optional, for local development)
- Make (optional, for convenience)

### One-Command Setup

Run the full demo (Infra + App):

```bash
make demo
# OR without make:
docker compose --profile infra --profile app up -d --build
```

Run infrastructure only (NATS, DB, etc.):

```bash
make up
# OR without make:
docker compose --profile infra up -d
```

Stop everything:

```bash
make down
# OR without make:
docker compose --profile infra --profile app down -v
```

## Architecture & Ports

| Service            | Internal Port | Host Port | Description |
|-------------------|---------------|-----------|-------------|
| **Realtime Gateway** | 8080 | **8081** | HTTP/WebSocket API (`/health`, `/ws`) |
| **AI Triage** | 8092 | **8092** | AI-powered patient triage service (`/health`) |
| **Dashboard** | 5173 | **5173** | Web UI |
| **NATS** | 4222 | **4222** | Core Message Broker (JetStream enabled) |
| NATS Monitoring | 8222 | **8222** | NATS Management UI |
| **TimescaleDB** | 5432 | **5432** | Time-series Database |
| **Mosquitto** | 1883 | **1883** | MQTT Broker |
| Redis | 6379 | **6379** | Cache (Optional) |

## Services

### Infrastructure (`profile: infra`)
- **NATS**: Configuring with JetStream. Auto-creates the `events` stream with subjects: `vitals.recorded`, `patient.alert.raised`, `dispatch.created`, `dispatch.assigned`.
- **TimescaleDB**: Stores sensor data.
- **Mosquitto**: MQTT broker for edge devices.

### Applications (`profile: app`)
- **Realtime Gateway**: Node.js service connecting NATS/DB to frontend.
- **Ingestion**: Simulates/Ingests sensor data.
- **AI Triage**: Consumes vitals events from NATS, evaluates patient conditions, and publishes alerts.
- **Dashboard**: React/Vite UI.

## Troubleshooting

### Port Conflicts
- **8081**: The Gateway uses 8081 on the host to avoid conflict with common services on 8080 (like Apache/IIS).
- **4222**: Ensure no local NATS server is running.

### NATS Streams Missing
The `nats-init` container attempts to create streams on startup. If you see errors about missing streams:
1. Check logs: `docker compose logs nats-init`
2. Manually create:
   ```bash
   docker exec -it 5g-platform-nats nats stream add events --subjects "vitals.recorded,patient.alert.raised,dispatch.created,dispatch.assigned" --storage file --retention limits --max-msgs 10000 --discard old --replicas 1 --no-confirm
   ```

### Rebuilding Services
If you change code in the sibling repositories (`../5g-health-platform-realtime-gateway`, etc.), you must rebuild the containers:
```bash
docker compose --profile app build
docker compose --profile app up -d
```

## Documentation
See [docs/integration-runbook.md](docs/integration-runbook.md) for a step-by-step verification guide.

```bash
git clone <repository-url>
cd 5g-health-platform-infra

# Copy environment template
cp .env.example .env

# (Optional) Edit .env to customize ports/credentials
```

### 2. Start Infrastructure

```bash
# Using Make (recommended)
make up

# Or using Docker Compose directly
docker compose up -d
```

The infrastructure will start all services in the background. Initial startup may take 1-2 minutes while containers download and initialize.

### 3. Verify Services

```bash
make health

# Or check manually
docker compose ps
```

All services should show as "healthy" or "Up".

## 🛠️ Common Commands

| Command           | Description                                      |
| ----------------- | ------------------------------------------------ |
| `make up`       | Start all services                               |
| `make down`     | Stop all services                                |
| `make restart`  | Restart all services                             |
| `make logs`     | Follow logs from all services                    |
| `make ps`       | Show service status                              |
| `make health`   | Check health of all services                     |
| `make reset`    | **⚠️ Stop services and delete all data** |
| `make clean`    | Remove stopped containers and clean up           |
| `make validate` | Validate docker-compose.yml configuration        |

### Service-Specific Logs

```bash
make logs-postgres    # PostgreSQL logs
make logs-redis       # Redis logs
make logs-nats        # NATS logs
make logs-mqtt        # Mosquitto logs
```

## 🔌 Service Endpoints

### PostgreSQL / TimescaleDB

- **Port**: `5432` (default)
- **Database**: `5g_health_platform`
- **Username**: `platform_user`
- **Password**: `platform_secret`
- **Connection String**:
  ```
  postgresql://platform_user:platform_secret@localhost:5432/5g_health_platform
  ```

### Redis

- **Port**: `6379` (default)
- **Password**: `redis_secret`
- **Connection String**:
  ```
  redis://:redis_secret@localhost:6379
  ```

### NATS with JetStream

- **Client Port**: `4222` (default)
- **HTTP Monitoring**: `8222`
- **Connection URL**: `nats://localhost:4222`
- **Monitoring UI**: http://localhost:8222

**JetStream Features**:

- Max Memory: 1GB
- Max Storage: 10GB
- Store Location: `/data/jetstream` (persisted in named volume)

### Mosquitto MQTT

- **MQTT Port**: `1883` (default)
- **WebSocket Port**: `9001`
- **Connection**: `mqtt://localhost:1883`
- **WebSocket**: `ws://localhost:9001`

**Note**: Anonymous connections are enabled for local development.

## 📊 Data Persistence

All service data is stored in Docker named volumes:

- `postgres_data` - PostgreSQL/TimescaleDB data
- `redis_data` - Redis persistence (AOF enabled)
- `nats_data` - NATS JetStream storage
- `mosquitto_data` - MQTT message persistence
- `mosquitto_logs` - Mosquitto logs

Data persists across `docker compose down` and container restarts. To completely remove all data, use `make reset`.

## 🌐 Networking

Services communicate via the `5g-platform-network` bridge network. This allows:

- Services to reference each other by container name (e.g., `postgres`, `redis`)
- Isolated network namespace for security
- Easy inter-service communication

## 🔧 Using This Infrastructure in Application Repositories

### In Your Application's `.env` or Config

```bash
# PostgreSQL
DATABASE_URL=postgresql://platform_user:platform_secret@localhost:5432/5g_health_platform

# Redis
REDIS_URL=redis://:redis_secret@localhost:6379

# NATS
NATS_URL=nats://localhost:4222

# MQTT
MQTT_BROKER=mqtt://localhost:1883
```

### In docker-compose.yml (for application services)

```yaml
services:
  your-service:
    # ... your service config
    networks:
      - 5g-platform-network

networks:
  5g-platform-network:
    external: true
    name: 5g-health-platform_5g-platform-network
```

Or run your services on the host and connect to exposed ports.

## 🧪 CI/CD Integration

The repository includes a GitHub Actions workflow (`.github/workflows/docker-compose-validation.yml`) that:

1. Validates `docker-compose.yml` syntax
2. Starts all services
3. Runs health checks on each container
4. Verifies TimescaleDB extension installation

This ensures infrastructure changes don't break the stack.

## 🔒 Security Notes

**⚠️ This configuration is for LOCAL DEVELOPMENT ONLY**

For production deployments:

- Change all default passwords
- Enable authentication on NATS
- Configure Mosquitto password file
- Use TLS/SSL for all connections
- Implement proper network policies
- Use secrets management (Vault, AWS Secrets Manager, etc.)

## 📝 Configuration Reference

### Environment Variables

All configurable values are in `.env`. Key variables:

| Variable              | Default                | Description          |
| --------------------- | ---------------------- | -------------------- |
| `POSTGRES_DB`       | `5g_health_platform` | Database name        |
| `POSTGRES_USER`     | `platform_user`      | Database user        |
| `POSTGRES_PASSWORD` | `platform_secret`    | Database password    |
| `POSTGRES_PORT`     | `5432`               | PostgreSQL port      |
| `REDIS_PASSWORD`    | `redis_secret`       | Redis password       |
| `REDIS_PORT`        | `6379`               | Redis port           |
| `NATS_PORT`         | `4222`               | NATS client port     |
| `NATS_HTTP_PORT`    | `8222`               | NATS HTTP monitoring |
| `MQTT_PORT`         | `1883`               | MQTT port            |
| `MQTT_WS_PORT`      | `9001`               | MQTT WebSocket port  |

### Custom Configurations

- **NATS**: Edit `nats/nats.conf`
- **Mosquitto**: Edit `mosquitto/mosquitto.conf`
- **PostgreSQL Init**: Add scripts to `db/init/` (executed in alphanumeric order)

## 🐛 Troubleshooting

### Services won't start

```bash
# Check service logs
make logs

# Check specific service
docker compose logs postgres
```

### Port already in use

Edit `.env` and change conflicting ports.

### TimescaleDB extension not found

```bash
# Check extension installation
docker compose exec postgres psql -U platform_user -d 5g_health_platform -c "\dx"
```

### Reset everything

```bash
make reset  # WARNING: Deletes all data
```

## 📚 Additional Resources

- [TimescaleDB Documentation](https://docs.timescale.com/)
- [Redis Documentation](https://redis.io/docs/)
- [NATS JetStream Documentation](https://docs.nats.io/nats-concepts/jetstream)
- [Mosquitto Documentation](https://mosquitto.org/documentation/)

---

**5G Health Platform Infrastructure** | Maintained by BeeLink CN
