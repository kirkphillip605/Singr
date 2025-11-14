# Singr Backend

Central API backend for the Singr karaoke platform.

## Overview

The Singr Central API Backend is a **single, unified REST API** that serves multiple front-end applications based on user roles and contexts:

- **Public/Guest Users** - Venue discovery, song search, guest requests
- **Singer Users** - Profile management, favorites, request submission, history
- **Customer/Venue Owners** - Venue management, song databases, request processing, team management, billing
- **Admin Users** - Platform administration, customer support, analytics

All users interact with the same API, with access controlled by JWT authentication and role-based permissions.

## Technology Stack

| Component | Technology |
|-----------|------------|
| **Language** | TypeScript (strict mode) |
| **Runtime** | Node.js 20+ |
| **Framework** | Fastify |
| **Database** | PostgreSQL 16 + PostGIS |
| **ORM** | Prisma |
| **Cache** | Redis |
| **Queue** | BullMQ |
| **Auth** | JWT (ES256) + Argon2 |
| **Validation** | Zod |
| **Email** | Mailjet |
| **SMS** | Twilio |
| **Payments** | Stripe |
| **Logging** | Pino |
| **Monitoring** | Sentry |

## Prerequisites

- Node.js 20+
- pnpm 8+
- Docker and Docker Compose
- Git

## Quick Start

1. **Clone repository:**
   ```bash
   git clone https://github.com/kirkphillip605/Singr.git
   cd Singr
   ```

2. **Install dependencies:**
   ```bash
   make install
   ```

3. **Set up environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Start services:**
   ```bash
   make dev-up
   ```

5. **Run migrations:**
   ```bash
   make db-migrate
   ```

6. **Seed database:**
   ```bash
   make db-seed
   ```

7. **Start development server:**
   ```bash
   pnpm dev
   ```

API will be available at `http://localhost:3000`

## Project Structure

```
singr-backend/
├── apps/
│   └── api/                    # Single unified Fastify API service
│       ├── src/
│       │   ├── server.ts       # Fastify server setup
│       │   ├── index.ts        # Entry point
│       │   ├── routes/         # Route modules by role/context
│       │   │   ├── v1/
│       │   │   │   ├── auth/           # Authentication endpoints
│       │   │   │   ├── public/         # Public/guest endpoints
│       │   │   │   ├── singer/         # Singer user endpoints
│       │   │   │   ├── customer/       # Customer/venue owner endpoints
│       │   │   │   ├── admin/          # Admin endpoints
│       │   │   │   └── openkj/         # OpenKJ compatibility
│       │   ├── plugins/        # Fastify plugins
│       │   ├── middleware/     # Custom middleware & RBAC
│       │   ├── services/       # Business logic services
│       │   ├── workers/        # BullMQ background workers
│       │   └── types/          # TypeScript types
│       └── tests/              # Integration tests
├── packages/
│   ├── database/               # Prisma schema, migrations
│   │   ├── prisma/
│   │   │   ├── schema.prisma
│   │   │   └── migrations/
│   │   └── src/
│   │       └── client.ts
│   ├── auth/                   # JWT, session, RBAC utilities
│   │   └── src/
│   │       ├── jwt.ts
│   │       ├── password.ts
│   │       └── rbac.ts
│   ├── config/                 # Environment validation
│   │   └── src/
│   │       ├── index.ts
│   │       └── constants.ts
│   ├── shared/                 # DTOs, types, utilities, services
│   │   └── src/
│   │       ├── validation/
│   │       ├── services/
│   │       ├── types/
│   │       └── utils/
│   └── observability/          # Logging, Sentry, metrics
│       └── src/
│           ├── logger.ts
│           ├── sentry.ts
│           └── metrics.ts
├── docker/
│   ├── api.Dockerfile
│   └── docker-compose.yml
├── docs/
│   ├── openapi.yaml
│   └── ARCHITECTURE.md
└── scripts/
    └── seed-database.ts
```

## Development Commands

```bash
# Install dependencies
make install

# Start local services (PostgreSQL, Redis, MinIO, Mailpit)
make dev-up

# Stop local services
make dev-down

# View service logs
make dev-logs

# Run database migrations
make db-migrate

# Seed database with test data
make db-seed

# Reset database (drop, migrate, seed)
make db-reset

# Run tests
make test

# Run linters
make lint

# Format code
make format

# Type check
make type-check
```

## Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Application
NODE_ENV=development
PORT=3000

# Database
DATABASE_URL=postgresql://singr:password@localhost:5432/singr_dev

# Redis
REDIS_URL=redis://localhost:6379

# JWT
JWT_PRIVATE_KEY=...
JWT_PUBLIC_KEY=...

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Mailjet
MAILJET_API_KEY=...
MAILJET_SECRET_KEY=...

# Twilio
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_PHONE_NUMBER=...
```

## API Documentation

Once the server is running, visit:
- **Swagger UI**: http://localhost:3000/docs
- **OpenAPI Spec**: http://localhost:3000/docs/json

## Architecture

See [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) for detailed architecture documentation.

## Development Phases

The project is organized into 18 phases (0-17):

- **Phase 0**: Project Foundation & Infrastructure Setup
- **Phase 1**: Database Schema & Core Models
- **Phase 2**: Authentication & Authorization
- **Phase 3**: API Server Foundation
- **Phase 4**: Authentication Endpoints
- **Phase 5**: Public Venue Discovery & Guest Features
- **Phase 6**: Singer Account & Profile Management
- **Phase 7**: Singer History, Favorites & Personalization
- **Phase 8**: Customer Venue Management
- **Phase 9**: Customer Systems & SongDB Management
- **Phase 10**: Customer Request Management
- **Phase 11**: API Key Management & OpenKJ Integration
- **Phase 12**: Organization & Team Management
- **Phase 13**: Subscription & Billing Integration
- **Phase 14**: Request Interface API
- **Phase 15**: Admin & Support Portal Backend
- **Phase 16**: Analytics & Reporting
- **Phase 17**: Testing, Documentation & Deployment

See `Project Planning Documents/` for detailed phase plans.

## Testing

```bash
# Run all tests
pnpm test

# Run tests in watch mode
pnpm test:watch

# Run tests with coverage
pnpm test:coverage

# Run integration tests only
pnpm test:integration
```

## Deployment

See [Phase 17 Plan](./Project%20Planning%20Documents/PHASE_17_PLAN.MD) for production deployment instructions.

## Security

- ES256 JWT tokens (asymmetric cryptography)
- Argon2id password hashing
- Rate limiting on all endpoints
- CORS configuration
- Input validation with Zod
- SQL injection prevention (Prisma)
- XSS prevention
- CSRF protection

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## License

UNLICENSED - Private Repository

## Support

- Email: support@singrkaraoke.com
- Website: https://singrkaraoke.com

---

**Last Updated**: 2025-11-14  
**Version**: 1.0.0  
**Status**: In Active Development
