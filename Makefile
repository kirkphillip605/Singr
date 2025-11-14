.PHONY: help dev-up dev-down dev-logs db-migrate db-seed db-reset test lint format type-check install

help:
	@echo "Singr Backend Development Commands"
	@echo "===================================="
	@echo "make install       - Install all dependencies"
	@echo "make dev-up        - Start all Docker services"
	@echo "make dev-down      - Stop and remove containers"
	@echo "make dev-logs      - Tail service logs"
	@echo "make db-migrate    - Run Prisma migrations"
	@echo "make db-seed       - Seed database with test data"
	@echo "make db-reset      - Drop, migrate, and seed"
	@echo "make test          - Run test suite"
	@echo "make lint          - Run linters"
	@echo "make format        - Format code"
	@echo "make type-check    - Type check without emit"

install:
	pnpm install

dev-up:
	docker-compose -f docker/docker-compose.yml up -d
	@echo "Waiting for services to be healthy..."
	@sleep 5
	@echo "✅ All services started"
	@echo "Services:"
	@echo "  PostgreSQL: localhost:5432 (singr/password)"
	@echo "  Redis: localhost:6379"
	@echo "  MinIO: localhost:9000 (minioadmin/minioadmin)"
	@echo "  Mailpit: http://localhost:8025"

dev-down:
	docker-compose -f docker/docker-compose.yml down

dev-logs:
	docker-compose -f docker/docker-compose.yml logs -f

db-migrate:
	cd packages/database && pnpm db:migrate:dev

db-seed:
	cd packages/database && pnpm db:seed

db-reset: dev-down dev-up
	@sleep 5
	$(MAKE) db-migrate
	$(MAKE) db-seed
	@echo "✅ Database reset complete"

test:
	pnpm test

lint:
	pnpm lint

format:
	pnpm format

type-check:
	pnpm type-check
