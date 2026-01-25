# Docker Setup for Cuisine13

This guide explains how to run Cuisine13 using Docker and Docker Compose.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Quick Start

### 1. Copy environment file
```bash
cp .env.example .env
```

### 2. Start the application
```bash
./scripts/docker-dev.sh start
```

The application will be available at:
- Web: http://localhost:4000
- Database: localhost:5432

### 3. Check logs
```bash
./scripts/docker-dev.sh logs
```

### 4. Stop the application
```bash
./scripts/docker-dev.sh stop
```

## Available Commands

The `docker-dev.sh` script provides convenient commands:

```bash
# Container management
./scripts/docker-dev.sh start      # Start all services
./scripts/docker-dev.sh stop       # Stop all services
./scripts/docker-dev.sh restart    # Restart web service
./scripts/docker-dev.sh ps         # Show running containers

# Logs and debugging
./scripts/docker-dev.sh logs       # View web service logs (follow)
./scripts/docker-dev.sh shell      # Open bash shell in web container
./scripts/docker-dev.sh iex        # Open IEx console

# Database operations
./scripts/docker-dev.sh migrate    # Run migrations
./scripts/docker-dev.sh rollback   # Rollback last migration
./scripts/docker-dev.sh seed       # Seed database
./scripts/docker-dev.sh reset      # Reset database (drop/create/migrate/seed)

# Development
./scripts/docker-dev.sh mix [cmd]  # Run any mix command
./scripts/docker-dev.sh test       # Run tests
./scripts/docker-dev.sh build      # Rebuild containers
./scripts/docker-dev.sh clean      # Remove containers and volumes
```

## Manual Docker Compose Commands

If you prefer using docker-compose directly:

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f web

# Stop services
docker-compose down

# Run migrations
docker-compose exec web mix ecto.migrate

# Open IEx
docker-compose exec web iex -S mix

# Run mix commands
docker-compose exec web mix deps.get
docker-compose exec web mix test
```

## Development Workflow

1. **Start services**: `./scripts/docker-dev.sh start`
2. **Make code changes**: Edit files on your host machine
3. **Changes auto-reload**: Phoenix LiveReload works inside Docker
4. **Run migrations**: `./scripts/docker-dev.sh migrate`
5. **View logs**: `./scripts/docker-dev.sh logs`
6. **Debug in IEx**: `./scripts/docker-dev.sh iex`

## Volumes

Docker Compose uses named volumes for persistence:

- `postgres_data`: PostgreSQL data
- `mix_deps`: Mix dependencies (faster builds)
- `mix_build`: Build artifacts (faster compilation)

## Troubleshooting

### Port already in use
If port 4000 or 5432 is already in use, edit `docker-compose.yml`:
```yaml
ports:
  - "4001:4000"  # Change host port
```

### Permission errors
If you get permission errors:
```bash
# Fix ownership (Linux/Mac)
sudo chown -R $USER:$USER .
```

### Clean start
If things are broken, try a clean start:
```bash
./scripts/docker-dev.sh clean  # Removes all data!
./scripts/docker-dev.sh build
./scripts/docker-dev.sh start
```

### Database connection errors
Make sure the database is healthy:
```bash
docker-compose ps
docker-compose logs db
```

## Production Deployment

For production, use `docker-compose.prod.yml`:

1. **Set environment variables**:
```bash
cp .env.example .env.prod
# Edit .env.prod with production values
```

2. **Start production services**:
```bash
docker-compose -f docker-compose.prod.yml up -d
```

3. **Run migrations**:
```bash
docker-compose -f docker-compose.prod.yml exec web /app/bin/cuisine13 eval 'Cuisine13.Release.migrate'
```

## Tips

- Code changes are automatically synced (volume mount)
- Dependencies are cached in named volumes
- Database persists between restarts
- Use `docker-dev.sh shell` for debugging
- Use `docker-dev.sh iex` for interactive Elixir

## Common Issues

**Q: Changes not reflecting?**
A: Restart the web service: `./scripts/docker-dev.sh restart`

**Q: Database connection refused?**
A: Wait for database to be ready, check `docker-compose logs db`

**Q: Out of disk space?**
A: Clean up: `docker system prune -a --volumes`

**Q: Want to reset everything?**
A: `./scripts/docker-dev.sh clean` then `./scripts/docker-dev.sh start`
