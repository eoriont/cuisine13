#!/bin/bash
# Development Docker helper script

set -e

case "$1" in
  start)
    echo "🚀 Starting development environment..."
    docker-compose up -d
    echo "✅ Environment started!"
    echo "   Web: http://localhost:4000"
    echo "   DB: localhost:5432"
    ;;

  stop)
    echo "🛑 Stopping development environment..."
    docker-compose down
    echo "✅ Environment stopped!"
    ;;

  restart)
    echo "🔄 Restarting development environment..."
    docker-compose restart web
    echo "✅ Environment restarted!"
    ;;

  logs)
    echo "📋 Showing logs (Ctrl+C to exit)..."
    docker-compose logs -f web
    ;;

  shell)
    echo "🐚 Opening shell in web container..."
    docker-compose exec web bash
    ;;

  iex)
    echo "💧 Opening IEx console..."
    docker-compose exec web iex -S mix
    ;;

  mix)
    shift
    echo "🔨 Running mix command: $@"
    docker-compose exec web mix "$@"
    ;;

  migrate)
    echo "🔄 Running migrations..."
    docker-compose exec web mix ecto.migrate
    echo "✅ Migrations complete!"
    ;;

  rollback)
    echo "⏪ Rolling back migration..."
    docker-compose exec web mix ecto.rollback
    echo "✅ Rollback complete!"
    ;;

  reset)
    echo "⚠️  Resetting database..."
    docker-compose exec web mix ecto.reset
    echo "✅ Database reset complete!"
    ;;

  seed)
    echo "🌱 Seeding database..."
    docker-compose exec web mix run priv/repo/seeds.exs
    echo "✅ Seeding complete!"
    ;;

  test)
    echo "🧪 Running tests..."
    docker-compose exec web mix test
    ;;

  clean)
    echo "🧹 Cleaning up containers and volumes..."
    read -p "This will remove all data. Continue? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      docker-compose down -v
      echo "✅ Cleanup complete!"
    else
      echo "Cancelled."
    fi
    ;;

  build)
    echo "🔨 Rebuilding containers..."
    docker-compose build --no-cache
    echo "✅ Build complete!"
    ;;

  ps)
    docker-compose ps
    ;;

  *)
    echo "Cuisine13 Docker Development Helper"
    echo ""
    echo "Usage: ./scripts/docker-dev.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start      - Start all services"
    echo "  stop       - Stop all services"
    echo "  restart    - Restart web service"
    echo "  logs       - View web service logs"
    echo "  shell      - Open bash shell in web container"
    echo "  iex        - Open IEx console"
    echo "  mix [cmd]  - Run mix command"
    echo "  migrate    - Run database migrations"
    echo "  rollback   - Rollback last migration"
    echo "  reset      - Reset database (drop, create, migrate, seed)"
    echo "  seed       - Seed database"
    echo "  test       - Run tests"
    echo "  clean      - Remove all containers and volumes"
    echo "  build      - Rebuild containers"
    echo "  ps         - Show running containers"
    echo ""
    echo "Examples:"
    echo "  ./scripts/docker-dev.sh start"
    echo "  ./scripts/docker-dev.sh logs"
    echo "  ./scripts/docker-dev.sh mix deps.get"
    exit 1
    ;;
esac
