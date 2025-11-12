# Singr Central API Backend - Complete Multi-Phase Development Plan

**Document Version:** 1.0  
**Last Updated:** 2025-11-11  
**Author:** kirkphillip605  
**Status:** In Development

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Phase 0: Project Foundation & Infrastructure Setup](#phase-0-project-foundation--infrastructure-setup)
3. [Phase 1: Database Schema & Core Models](#phase-1-database-schema--core-models)
4. [Phase 2: Authentication & Authorization](#phase-2-authentication--authorization)
5. [Phase 3: API Server Foundation](#phase-3-api-server-foundation)
6. [Phase 4: Authentication Endpoints](#phase-4-authentication-endpoints)
7. [Phase 5: Public Venue Discovery & Guest Features](#phase-5-public-venue-discovery--guest-features)
8. [Phase 6: Singer Account & Profile Management](#phase-6-singer-account--profile-management)
9. [Phase 7: Singer History, Favorites & Personalization](#phase-7-singer-history-favorites--personalization)
10. [Phase 8: Customer Venue Management](#phase-8-customer-venue-management)
11. [Phase 9: Customer Systems & Songdb Management](#phase-9-customer-systems--songdb-management)
12. [Phase 10: Customer API Keys Management](#phase-10-customer-api-keys-management)
13. [Phase 11: Customer Request Management](#phase-11-customer-request-management)
14. [Phase 12: Organization Users & Team Management](#phase-12-organization-users--team-management)
15. [Phase 13: Subscription & Billing Integration](#phase-13-subscription--billing-integration)
16. [Phase 14: OpenKJ API Compatibility Layer](#phase-14-openkj-api-compatibility-layer)
17. [Phase 15: Customer Analytics & Reporting](#phase-15-customer-analytics--reporting)
18. [Phase 16: Testing & Documentation](#phase-16-testing--documentation)
19. [Phase 17: Performance Optimization & Monitoring](#phase-17-performance-optimization--monitoring)

---

## Executive Summary

The Singr Central API Backend is a unified, stateless REST API that powers all Singr ecosystem applications:
- **Singer Web App** - For registered and guest singers to discover venues, search songs, submit requests
- **Singer Mobile Apps** - Native iOS/Android applications for singers
- **Customer Web Portal** - For karaoke venue owners/managers to manage venues, staff, requests, and billing

### Key Architecture Decisions

| Aspect | Decision |
|--------|----------|
| **Framework** | Fastify (high-performance HTTP server) |
| **Language** | TypeScript (strict mode) |
| **Database** | PostgreSQL 16 with PostGIS extension |
| **ORM** | Prisma with raw SQL when needed |
| **Cache/Sessions** | Redis with Argon2 for sensitive tokens |
| **Authentication** | JWT (ES256) with refresh token rotation |
| **Authorization** | RBAC with org-specific permission overrides |
| **Validation** | Zod schemas for all inputs |
| **Storage** | Google Cloud Storage or S3 (signed URLs) |
| **Async Jobs** | BullMQ queue system |
| **Observability** | Sentry + pino structured logging |
| **Deployment** | Docker containers on Kubernetes/ECS |

### Technology Stack Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Client Applications                      │
│  (Singer Web, Singer Mobile, Customer Portal)               │
└─────────────────────────────────────┬───────────────────────┘
                                      │ HTTPS
┌─────────────────────────────────────┴───────────────────────┐
│                    Load Balancer / CDN                       │
│              (TLS Termination, CORS, Rate Limiting)         │
└─────────────────────────────────────┬───────────────────────┘
                                      │
┌─────────────────────────────────────┴───────────────────────┐
│                      Fastify API Service                     │
│  • Authentication (JWT, OAuth)                              │
│  • Request Validation (Zod)                                 │
│  • Rate Limiting & CORS                                     │
│  • Route Handlers                                           │
│  • Error Handling & Logging                                 │
└─────┬──────────────────────────────────────────────────────┘
      │
      ├─────────────────────┬──────────────────────┬──────────────────┐
      │                     │                      │                  │
┌─────▼─────┐      ┌────────▼────────┐    ┌──────▼─────┐    ┌──────▼─────┐
│ PostgreSQL │      │   Redis Cache   │    │ S3 Storage │    │ BullMQ     │
│ + PostGIS  │      │   + Sessions    │    │  Buckets   │    │ Queues     │
└────────────┘      └─────────────────┘    └────────────┘    └──────┬─────┘
                                                                      │
                                                         ┌────────────▼──┐
                                                         │ Worker Service │
                                                         │ (Emails, Webhooks)│
                                                         └─────────────────┘
```

---

## Phase 0: Project Foundation & Infrastructure Setup

### 0.1 Repository & Tooling Initialization

**Objective:** Establish project structure, tooling, and development environment.

**Duration:** 2-3 days  
**Team Size:** 1-2 developers

**Tasks:**

1. **Initialize monorepo structure:**
   ```
   singr-backend/
   ├── apps/
   │   ├── api/                    # Main Fastify API service
   │   │   ├── src/
   │   │   │   ├── server.ts       # Fastify server setup
   │   │   │   ├── index.ts        # Entry point
   │   │   │   └── routes/         # Route modules
   │   │   ├── tests/              # Integration tests
   │   │   └── package.json
   │   └── worker/                 # BullMQ background worker
   │       ├── src/
   │       │   ├── index.ts
   │       │   ├── jobs/           # Job processors
   │       │   └── handlers/
   │       └── package.json
   ├── packages/
   │   ├── database/               # Prisma schema, migrations
   │   │   ├── prisma/
   │   │   │   ├── schema.prisma
   │   │   │   └── migrations/
   │   │   ├── src/
   │   │   │   └── client.ts
   │   │   └── package.json
   │   ├── auth/                   # JWT, session, RBAC utilities
   │   │   ├── src/
   │   │   │   ├── jwt.ts
   │   │   │   ├── password.ts
   │   │   │   ├── rbac.ts
   │   │   │   └── index.ts
   │   │   └── package.json
   │   ├── config/                 # Environment validation
   │   │   ├── src/
   │   │   │   ├── index.ts
   │   │   │   └── constants.ts
   │   │   └── package.json
   │   ├── shared/                 # DTOs, types, utilities, services
   │   │   ├── src/
   │   │   │   ├── validation/
   │   │   │   ├── services/
   │   │   │   ├── types/
   │   │   │   └── utils/
   │   │   └── package.json
   │   └── observability/          # Logging, Sentry, metrics
   │       ├── src/
   │       │   ├── logger.ts
   │       │   ├── sentry.ts
   │       │   └── metrics.ts
   │       └── package.json
   ├── docker/
   │   ├── api.Dockerfile
   │   ├── worker.Dockerfile
   │   └── docker-compose.yml
   ├── docs/
   │   ├── openapi.yaml
   │   ├── README.md
   │   └── ARCHITECTURE.md
   ├── scripts/
   │   ├── generate-postman.ts
   │   └── seed-database.ts
   ├── pnpm-workspace.yaml
   ├── tsconfig.base.json
   ├── .eslintrc.js
   ├── .prettierrc
   ├── Makefile
   └── package.json
   ```

2. **Configure package manager (pnpm workspace):**
   ```json
   {
     "name": "singr-backend",
     "version": "1.0.0",
     "private": true,
     "description": "Singr Central API Backend",
     "scripts": {
       "dev": "pnpm --recursive dev",
       "build": "pnpm --recursive build",
       "test": "pnpm --recursive test",
       "lint": "eslint . --ext .ts",
       "format": "prettier --write .",
       "type-check": "tsc --noEmit",
       "prepare": "husky install"
     },
     "devDependencies": {
       "@typescript-eslint/eslint-plugin": "^6.x",
       "@typescript-eslint/parser": "^6.x",
       "eslint": "^8.x",
       "husky": "^8.x",
       "lint-staged": "^15.x",
       "prettier": "^3.x",
       "typescript": "^5.x",
       "vitest": "^1.x"
     }
   }
   ```

3. **Set up core dependencies** (in root `package.json`):
   ```json
   {
     "dependencies": {
       "fastify": "^4.x",
       "@fastify/cors": "^9.x",
       "@fastify/helmet": "^11.x",
       "@fastify/jwt": "^7.x",
       "@fastify/rate-limit": "^9.x",
       "@fastify/swagger": "^8.x",
       "@fastify/swagger-ui": "^3.x",
       "@prisma/client": "^5.x",
       "prisma": "^5.x",
       "zod": "^3.x",
       "pino": "^8.x",
       "pino-pretty": "^10.x",
       "@node-rs/argon2": "^1.x",
       "bullmq": "^5.x",
       "ioredis": "^5.x",
       "@sentry/node": "^7.x",
       "envsafe": "^2.x",
       "jsonwebtoken": "^9.x",
       "uuid": "^9.x"
     }
   }
   ```

4. **Initialize Git with `.gitignore`:**
   ```
   # Dependencies
   node_modules/
   .pnpm-store/
   
   # Build outputs
   dist/
   build/
   *.tsbuildinfo
   
   # Environment variables
   .env
   .env.local
   .env.*.local
   
   # IDE
   .vscode/
   .idea/
   *.swp
   *.swo
   *~
   
   # OS
   .DS_Store
   Thumbs.db
   
   # Logs
   logs/
   *.log
   npm-debug.log*
   
   # Prisma
   prisma/*.db
   prisma/*.db-journal
   
   # Test coverage
   coverage/
   .nyc_output/
   ```

5. **Create TypeScript configuration:**
   ```json
   {
     "compilerOptions": {
       "target": "ES2020",
       "module": "ESNext",
       "lib": ["ES2020"],
       "jsx": "react",
       "declaration": true,
       "declarationMap": true,
       "sourceMap": true,
       "outDir": "./dist",
       "rootDir": "./src",
       "strict": true,
       "esModuleInterop": true,
       "skipLibCheck": true,
       "forceConsistentCasingInFileNames": true,
       "resolveJsonModule": true,
       "moduleResolution": "node",
       "allowSyntheticDefaultImports": true,
       "baseUrl": ".",
       "paths": {
         "@singr/database": ["packages/database/src"],
         "@singr/auth": ["packages/auth/src"],
         "@singr/config": ["packages/config/src"],
         "@singr/shared/*": ["packages/shared/src/*"],
         "@singr/observability": ["packages/observability/src"]
       }
     },
     "include": ["src/**/*"],
     "exclude": ["node_modules", "dist"]
   }
   ```

**Deliverables:**
- ✅ Functional monorepo with all packages scaffolded
- ✅ `pnpm install` runs cleanly
- ✅ TypeScript compilation works across all packages
- ✅ Linting and formatting rules enforced
- ✅ Git repository initialized with proper .gitignore
- ✅ CI/CD configuration ready for setup

---

### 0.2 Docker & Local Development Environment

**Objective:** Provide consistent local dev environment with all dependencies.

**Duration:** 1-2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create `docker-compose.yml`:**
   ```yaml
   version: '3.8'
   
   services:
     postgres:
       image: postgis/postgis:16-3.3
       container_name: singr-postgres
       environment:
         POSTGRES_USER: singr
         POSTGRES_PASSWORD: password
         POSTGRES_DB: singr_dev
       ports:
         - "5432:5432"
       volumes:
         - postgres_data:/var/lib/postgresql/data
       healthcheck:
         test: ["CMD-SHELL", "pg_isready -U singr"]
         interval: 10s
         timeout: 5s
         retries: 5
   
     redis:
       image: redis:7-alpine
       container_name: singr-redis
       ports:
         - "6379:6379"
       command: redis-server --appendonly yes
       volumes:
         - redis_data:/data
       healthcheck:
         test: ["CMD", "redis-cli", "ping"]
         interval: 10s
         timeout: 5s
         retries: 5
   
     minio:
       image: minio/minio:latest
       container_name: singr-minio
       environment:
         MINIO_ROOT_USER: minioadmin
         MINIO_ROOT_PASSWORD: minioadmin
       ports:
         - "9000:9000"
         - "9001:9001"
       volumes:
         - minio_data:/data
       command: server /data --console-address ":9001"
       healthcheck:
         test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
         interval: 10s
         timeout: 5s
         retries: 5
   
     mailpit:
       image: axllent/mailpit:latest
       container_name: singr-mailpit
       ports:
         - "1025:1025"
         - "8025:8025"
   
   volumes:
     postgres_data:
     redis_data:
     minio_data:
   ```

2. **Write `Makefile` with commands:**
   ```makefile
   .PHONY: help dev-up dev-down dev-logs db-migrate db-seed db-reset test lint format type-check
   
   help:
   	@echo "Singr Backend Development Commands"
   	@echo "===================================="
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
   	pnpm --filter database db:migrate:dev
   
   db-seed:
   	pnpm --filter database db:seed
   
   db-reset: dev-down dev-up db-migrate db-seed
   	@echo "✅ Database reset complete"
   
   test:
   	pnpm --recursive test
   
   lint:
   	pnpm lint
   
   format:
   	pnpm format
   
   type-check:
   	pnpm type-check
   ```

3. **Configure environment variables template (`.env.example`):**
   ```bash
   # Application
   NODE_ENV=development
   PORT=3000
   LOG_LEVEL=debug
   
   # Database
   DATABASE_URL=postgresql://singr:password@localhost:5432/singr_dev
   
   # Redis
   REDIS_URL=redis://localhost:6379
   
   # Storage (S3/MinIO)
   S3_ENDPOINT=http://localhost:9000
   S3_ACCESS_KEY_ID=minioadmin
   S3_SECRET_ACCESS_KEY=minioadmin
   S3_BUCKET=singr-assets
   S3_REGION=us-east-1
   
   # JWT
   JWT_PRIVATE_KEY=-----BEGIN EC PRIVATE KEY-----\n...\n-----END EC PRIVATE KEY-----
   JWT_PUBLIC_KEY=-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----
   JWT_ISSUER=system.singrkaraoke.com
   JWT_AUDIENCE=system.singrkaraoke.com
   JWT_ACCESS_TTL=900
   JWT_REFRESH_TTL=604800
   
   # Session & Secrets
   AUTH_SECRET=your-256-bit-secret-key-here
   
   # Sentry
   SENTRY_DSN=
   
   # Stripe
   STRIPE_SECRET_KEY=sk_test_...
   STRIPE_WEBHOOK_SECRET=whsec_...
   STRIPE_PUBLISHABLE_KEY=pk_test_...
   
   # Email
   EMAIL_FROM=noreply@singrkaraoke.com
   EMAIL_PROVIDER=mailpit
   SMTP_HOST=localhost
   SMTP_PORT=1025
   SMTP_USER=
   SMTP_PASSWORD=
   
   # CORS
   CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:3002
   
   # Logging
   ENABLE_REQUEST_LOGGING=true
   ```

4. **Document setup in `README.md`:**
   ```markdown
   # Singr Backend

   Central API backend for the Singr karaoke platform.

   ## Prerequisites

   - Node.js 20+
   - pnpm 8+
   - Docker and Docker Compose
   - Git

   ## Quick Start

   1. **Clone repository:**
      \`\`\`bash
      git clone https://github.com/kirkphillip605/singr-backend.git
      cd singr-backend
      \`\`\`

   2. **Install dependencies:**
      \`\`\`bash
      pnpm install
      \`\`\`

   3. **Set up environment:**
      \`\`\`bash
      cp .env.example .env
      \`\`\`

   4. **Start services:**
      \`\`\`bash
      make dev-up
      \`\`\`

   5. **Run migrations:**
      \`\`\`bash
      make db-migrate
      \`\`\`

   6. **Seed database:**
      \`\`\`bash
      make db-seed
      \`\`\`

   7. **Start development server:**
      \`\`\`bash
      pnpm dev
      \`\`\`

   API will be available at `http://localhost:3000`

   ## Architecture

   See [ARCHITECTURE.md](./docs/ARCHITECTURE.md) for detailed architecture documentation.

   ## Contributing

   See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.
   ```

**Deliverables:**
- ✅ `docker-compose.yml` starts all services with health checks
- ✅ PostgreSQL accessible with PostGIS enabled
- ✅ Redis accessible and responding to PING
- ✅ MinIO accessible with bucket auto-created
- ✅ Mailpit accessible for email testing
- ✅ `make` commands for common tasks
- ✅ Comprehensive README with setup instructions

---

### 0.3 Configuration & Secrets Management

**Objective:** Type-safe, validated configuration system with email and SMS provider credentials.

**Duration:** 1-2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create `packages/config/src/index.ts`:**
   ```typescript
   import { envsafe, str, url, port, num, bool } from 'envsafe';

   export const config = envsafe({
     // Application
     NODE_ENV: str({
       choices: ['development', 'test', 'production'],
       default: 'development',
     }),
     PORT: port({ default: 3000 }),
     LOG_LEVEL: str({
       choices: ['fatal', 'error', 'warn', 'info', 'debug', 'trace'],
       default: 'info',
     }),

     // Database
     DATABASE_URL: url(),

     // Cache & Session
     REDIS_URL: url(),

     // Storage
     S3_ENDPOINT: url(),
     S3_ACCESS_KEY_ID: str(),
     S3_SECRET_ACCESS_KEY: str(),
     S3_BUCKET: str(),
     S3_REGION: str({ default: 'us-east-1' }),

     // JWT
     JWT_PRIVATE_KEY: str(),
     JWT_PUBLIC_KEY: str(),
     JWT_ISSUER: str({ default: 'system.singrkaraoke.com' }),
     JWT_AUDIENCE: str({ default: 'system.singrkaraoke.com' }),
     JWT_ACCESS_TTL: num({ default: 900 }), // 15 minutes
     JWT_REFRESH_TTL: num({ default: 604800 }), // 7 days

     // Session & Magic Links
     AUTH_SECRET: str(),
     MAGIC_LINK_TTL: num({ default: 900 }), // 15 minutes

     // 2FA Settings
     TWO_FACTOR_ISSUER: str({ default: 'Singr' }),
     TWO_FACTOR_WINDOW: num({ default: 1 }), // TOTP window tolerance

     // Observability
     SENTRY_DSN: str({ default: '' }),
     ENABLE_REQUEST_LOGGING: bool({ default: true }),

     // Stripe
     STRIPE_SECRET_KEY: str(),
     STRIPE_WEBHOOK_SECRET: str(),
     STRIPE_PUBLISHABLE_KEY: str(),

     // Mailjet Email Service
     MAILJET_API_KEY: str(),
     MAILJET_SECRET_KEY: str(),
     MAILJET_FROM_EMAIL: str({ default: 'noreply@singrkaraoke.com' }),
     MAILJET_FROM_NAME: str({ default: 'Singr' }),
     MAILJET_TEMPLATE_VERIFICATION: num({ default: 0 }), // Template IDs
     MAILJET_TEMPLATE_PASSWORD_RESET: num({ default: 0 }),
     MAILJET_TEMPLATE_MAGIC_LINK: num({ default: 0 }),
     MAILJET_TEMPLATE_TWO_FACTOR: num({ default: 0 }),
     MAILJET_TEMPLATE_WELCOME: num({ default: 0 }),
     MAILJET_TEMPLATE_INVITATION: num({ default: 0 }),

     // Twilio SMS Service
     TWILIO_ACCOUNT_SID: str(),
     TWILIO_AUTH_TOKEN: str(),
     TWILIO_PHONE_NUMBER: str(), // E.164 format
     TWILIO_VERIFY_SERVICE_SID: str({ default: '' }), // Optional: Use Twilio Verify API

     // Email/SMS Feature Flags
     ENABLE_EMAIL_SENDING: bool({ default: true }),
     ENABLE_SMS_SENDING: bool({ default: true }),
     EMAIL_PROVIDER: str({
       choices: ['mailjet', 'console'],
       default: 'mailjet',
     }), // 'console' for dev
     SMS_PROVIDER: str({
       choices: ['twilio', 'console'],
       default: 'twilio',
     }), // 'console' for dev

     // Rate Limiting for Communication
     EMAIL_RATE_LIMIT_MAX: num({ default: 10 }), // Per user per hour
     SMS_RATE_LIMIT_MAX: num({ default: 5 }), // Per user per hour

     // Application URLs (for email links)
     APP_URL_WEB: url({ default: 'http://localhost:3000' }),
     APP_URL_CUSTOMER: url({ default: 'http://localhost:3001' }),
     APP_URL_API: url({ default: 'http://localhost:3000' }),

     // CORS
     CORS_ORIGINS: str({
       default: 'http://localhost:3000,http://localhost:3001,http://localhost:3002',
     }),
   });
   ```

2. **Create `packages/config/src/constants.ts`:**
   ```typescript
   export const RATE_LIMITS = {
     AUTH_SIGNIN: { max: 5, window: '1m' },
     AUTH_REGISTER: { max: 3, window: '1h' },
     AUTH_PASSWORD_RESET: { max: 5, window: '1h' },
     AUTH_MAGIC_LINK: { max: 5, window: '1h' },
     AUTH_TWO_FACTOR_REQUEST: { max: 5, window: '1h' },
     AUTH_TWO_FACTOR_VERIFY: { max: 10, window: '15m' },
     PUBLIC_VENUES: { max: 60, window: '1m' },
     PUBLIC_SONGS_SEARCH: { max: 60, window: '1m' },
     PUBLIC_REQUESTS: { max: 10, window: '1h' },
     SINGER_REQUEST: { max: 10, window: '1h' },
     SINGER_QUICK_REQUEST: { max: 10, window: '1h' },
     CUSTOMER_API: { max: 100, window: '1m' },
     CUSTOMER_SONGDB_IMPORT: { max: 10, window: '1h' },
     ADMIN_API: { max: 200, window: '1m' },
   };

   export const CACHE_TTL = {
     VENUES_LIST: 300, // 5 minutes
     VENUE_DETAIL: 600, // 10 minutes
     SONGDB_SEARCH: 300, // 5 minutes
     PERMISSIONS: 1800, // 30 minutes
     PUBLIC_BRANDING: 3600, // 1 hour
     TWO_FACTOR_CODE: 300, // 5 minutes
   };

   export const PAGINATION = {
     DEFAULT_LIMIT: 20,
     MAX_LIMIT: 100,
     MIN_LIMIT: 1,
   };

   export const PAGINATION_LIMITS = {
     VENUES: { default: 20, max: 100 },
     SONGS: { default: 20, max: 100 },
     REQUESTS: { default: 20, max: 100 },
     USERS: { default: 20, max: 50 },
   };

   export const PASSWORD_CONFIG = {
     memoryCost: 19456, // 19 MB
     timeCost: 2,
     outputLen: 32,
     parallelism: 1,
   };

   export const API_KEY_PREFIX = 'sk_live_';

   export const TOKEN_EXPIRY = {
     INVITATION: 7 * 24 * 60 * 60 * 1000, // 7 days
     EMAIL_VERIFICATION: 24 * 60 * 60 * 1000, // 24 hours
     PASSWORD_RESET: 60 * 60 * 1000, // 1 hour
     MAGIC_LINK: 15 * 60 * 1000, // 15 minutes
     TWO_FACTOR_BACKUP: 0, // Never expires until used
   };

   export const TWO_FACTOR = {
     TOTP_WINDOW: 1, // Allow 1 step before/after for clock skew
     TOTP_STEP: 30, // 30 second intervals
     SMS_CODE_LENGTH: 6,
     SMS_CODE_TTL: 300, // 5 minutes
     BACKUP_CODE_COUNT: 10,
     BACKUP_CODE_LENGTH: 8,
   };

   export const EMAIL_TYPES = {
     VERIFICATION: 'email_verification',
     PASSWORD_RESET: 'password_reset',
     MAGIC_LINK: 'magic_link',
     TWO_FACTOR_CODE: 'two_factor_code',
     WELCOME: 'welcome',
     INVITATION: 'invitation',
     REQUEST_NOTIFICATION: 'request_notification',
   };

   export const SMS_TYPES = {
     VERIFICATION: 'sms_verification',
     TWO_FACTOR_CODE: 'two_factor_code',
     MAGIC_LINK: 'magic_link',
   };

   export const DEFAULT_ROLES = [
     { slug: 'admin', description: 'Platform administrator', isSystem: true },
     { slug: 'support_admin', description: 'Support team admin', isSystem: true },
     { slug: 'customer_owner', description: 'Customer account owner', isSystem: true },
     { slug: 'customer_manager', description: 'Customer manager', isSystem: true },
     { slug: 'customer_staff', description: 'Customer staff member', isSystem: true },
     { slug: 'singer', description: 'Singer user', isSystem: true },
   ];

   export const DEFAULT_PERMISSIONS = [
     // Venue permissions
     { slug: 'venues:read', description: 'View venues' },
     { slug: 'venues:write', description: 'Create/edit venues' },
     { slug: 'venues:delete', description: 'Delete venues' },

     // System permissions
     { slug: 'systems:read', description: 'View systems' },
     { slug: 'systems:write', description: 'Create/edit systems' },

     // API key permissions
     { slug: 'api_keys:read', description: 'View API keys' },
     { slug: 'api_keys:write', description: 'Create/rotate API keys' },
     { slug: 'api_keys:revoke', description: 'Revoke API keys' },

     // Songdb permissions
     { slug: 'songdb:read', description: 'View songdb' },
     { slug: 'songdb:write', description: 'Manage songdb' },

     // Request permissions
     { slug: 'requests:read', description: 'View requests' },
     { slug: 'requests:process', description: 'Process requests' },

     // Organization permissions
     { slug: 'organization:read', description: 'View organization members' },
     { slug: 'organization:write', description: 'Manage organization members' },

     // Billing permissions
     { slug: 'billing:read', description: 'View billing' },
     { slug: 'billing:write', description: 'Manage subscriptions' },

     // Branding permissions
     { slug: 'branding:read', description: 'View branding' },
     { slug: 'branding:write', description: 'Edit branding' },
   ];

   export const MAILJET_SANDBOX_MODE = {
     enabled: process.env.NODE_ENV === 'development',
     testEmail: 'test@singrkaraoke.com',
   };

   export const COMMUNICATION_RETRY = {
     maxAttempts: 3,
     backoffMs: 1000, // Start with 1 second
     backoffMultiplier: 2, // Double each retry
   };
   ```

3. **Update `.env.example`:**
   ```bash
   # Application
   NODE_ENV=development
   PORT=3000
   LOG_LEVEL=debug

   # Database
   DATABASE_URL=postgresql://singr:password@localhost:5432/singr_dev

   # Redis
   REDIS_URL=redis://localhost:6379

   # Storage (S3/MinIO)
   S3_ENDPOINT=http://localhost:9000
   S3_ACCESS_KEY_ID=minioadmin
   S3_SECRET_ACCESS_KEY=minioadmin
   S3_BUCKET=singr-assets
   S3_REGION=us-east-1

   # JWT (Generate with: openssl ecparam -genkey -name prime256v1 -noout -out jwt-private.pem)
   JWT_PRIVATE_KEY=-----BEGIN EC PRIVATE KEY-----\n...\n-----END EC PRIVATE KEY-----
   JWT_PUBLIC_KEY=-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----
   JWT_ISSUER=system.singrkaraoke.com
   JWT_AUDIENCE=system.singrkaraoke.com
   JWT_ACCESS_TTL=900
   JWT_REFRESH_TTL=604800

   # Session & Magic Links
   AUTH_SECRET=your-256-bit-secret-key-here-generate-with-openssl-rand-hex-32
   MAGIC_LINK_TTL=900

   # 2FA Settings
   TWO_FACTOR_ISSUER=Singr
   TWO_FACTOR_WINDOW=1

   # Sentry
   SENTRY_DSN=

   # Stripe
   STRIPE_SECRET_KEY=sk_test_...
   STRIPE_WEBHOOK_SECRET=whsec_...
   STRIPE_PUBLISHABLE_KEY=pk_test_...

   # Mailjet Configuration
   # Get credentials from: https://app.mailjet.com/account/api_keys
   MAILJET_API_KEY=your-mailjet-api-key
   MAILJET_SECRET_KEY=your-mailjet-secret-key
   MAILJET_FROM_EMAIL=noreply@singrkaraoke.com
   MAILJET_FROM_NAME=Singr

   # Mailjet Template IDs (create templates in Mailjet dashboard)
   MAILJET_TEMPLATE_VERIFICATION=0
   MAILJET_TEMPLATE_PASSWORD_RESET=0
   MAILJET_TEMPLATE_MAGIC_LINK=0
   MAILJET_TEMPLATE_TWO_FACTOR=0
   MAILJET_TEMPLATE_WELCOME=0
   MAILJET_TEMPLATE_INVITATION=0

   # Twilio Configuration
   # Get credentials from: https://console.twilio.com/
   TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   TWILIO_AUTH_TOKEN=your-auth-token
   TWILIO_PHONE_NUMBER=+15555551234
   TWILIO_VERIFY_SERVICE_SID=VAxxxxxxxxxxxxxxxxxxxxxxxxxxxx

   # Communication Feature Flags
   ENABLE_EMAIL_SENDING=true
   ENABLE_SMS_SENDING=true
   EMAIL_PROVIDER=mailjet
   SMS_PROVIDER=twilio

   # Communication Rate Limits
   EMAIL_RATE_LIMIT_MAX=10
   SMS_RATE_LIMIT_MAX=5

   # Application URLs (used in email/SMS links)
   APP_URL_WEB=http://localhost:3000
   APP_URL_CUSTOMER=http://localhost:3001
   APP_URL_API=http://localhost:3000

   # CORS
   CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:3002

   # Logging
   ENABLE_REQUEST_LOGGING=true
   ```

4. **Create configuration documentation in `docs/CONFIGURATION.md`:**
   ````markdown
   # Configuration Guide

   ## Environment Variables

   ### Required Variables

   All variables in `.env.example` marked as required must be set before starting the application.

   ### Email Configuration (Mailjet)

   1. **Sign up for Mailjet**: https://app.mailjet.com/signup
   2. **Get API credentials**: Navigate to Account Settings → API Key Management
   3. **Create email templates**:
      - Go to Transactional → Templates
      - Create templates for each email type
      - Note the template IDs and add to `.env`

   **Template Variables Required:**

   - **Verification Email** (`MAILJET_TEMPLATE_VERIFICATION`):
     - `{{user_name}}` - User's name
     - `{{verification_link}}` - Full verification URL
     - `{{verification_code}}` - 6-digit code (backup)

   - **Password Reset** (`MAILJET_TEMPLATE_PASSWORD_RESET`):
     - `{{user_name}}` - User's name
     - `{{reset_link}}` - Full password reset URL
     - `{{expiry_minutes}}` - Link expiration time

   - **Magic Link** (`MAILJET_TEMPLATE_MAGIC_LINK`):
     - `{{user_email}}` - User's email
     - `{{magic_link}}` - One-time sign-in URL
     - `{{expiry_minutes}}` - Link expiration time
     - `{{ip_address}}` - Request IP (security)

   - **2FA Code** (`MAILJET_TEMPLATE_TWO_FACTOR`):
     - `{{user_name}}` - User's name
     - `{{code}}` - 6-digit verification code
     - `{{expiry_minutes}}` - Code expiration time

   ### SMS Configuration (Twilio)

   1. **Sign up for Twilio**: https://www.twilio.com/try-twilio
   2. **Get Account SID and Auth Token**: Console Dashboard
   3. **Buy a phone number**: Phone Numbers → Buy a Number
   4. **Optional - Set up Verify API**:
      - More efficient for OTP codes
      - Navigate to Verify → Services
      - Create a service and note the Service SID

   ### JWT Key Generation

   Generate ES256 keys for production:

   ```bash
   # Generate private key
   openssl ecparam -genkey -name prime256v1 -noout -out jwt-private.pem

   # Generate public key
   openssl ec -in jwt-private.pem -pubout -out jwt-public.pem

   # View keys for .env (copy entire output including headers)
   cat jwt-private.pem
   cat jwt-public.pem
   ```

   ### Auth Secret Generation

   ```bash
   openssl rand -hex 32
   ```

   ## Development vs Production

   ### Development Settings

   ```bash
   NODE_ENV=development
   EMAIL_PROVIDER=console  # Logs emails to console
   SMS_PROVIDER=console    # Logs SMS to console
   ENABLE_EMAIL_SENDING=false
   ENABLE_SMS_SENDING=false
   ```

   ### Production Settings

   ```bash
   NODE_ENV=production
   EMAIL_PROVIDER=mailjet
   SMS_PROVIDER=twilio
   ENABLE_EMAIL_SENDING=true
   ENABLE_SMS_SENDING=true
   ```

   ## Rate Limiting

   Communication rate limits prevent abuse:

   - **Email**: 10 per user per hour (configurable via `EMAIL_RATE_LIMIT_MAX`)
   - **SMS**: 5 per user per hour (configurable via `SMS_RATE_LIMIT_MAX`)

   ## Troubleshooting

   ### Mailjet Issues

   - **401 Unauthorized**: Check API key and secret
   - **Template not found**: Verify template IDs in Mailjet dashboard
   - **Emails not sending**: Check sender domain verification
   - **Sandbox mode**: In development, Mailjet may require domain verification

   ### Twilio Issues

   - **403 Forbidden**: Check account status and auth token
   - **Invalid phone number**: Ensure E.164 format (+15555551234)
   - **SMS not delivered**: Check phone number verification (trial accounts)
   - **Rate limits**: Twilio has its own rate limits separate from application

   ## Security Best Practices

   1. **Never commit `.env` files**
   2. **Rotate API keys regularly** (every 90 days)
   3. **Use different keys per environment**
   4. **Monitor usage in Mailjet/Twilio dashboards**
   5. **Set up webhook security** (verify signatures)
   6. **Use environment-specific sending domains**
   ````

**Deliverables:**
- ✅ Validated environment variables with `envsafe`
- ✅ Mailjet API credentials configuration
- ✅ Twilio API credentials configuration
- ✅ Email template ID management
- ✅ SMS configuration with Twilio Verify support
- ✅ Feature flags for email/SMS providers
- ✅ Development vs production provider switching
- ✅ Rate limit configurations for communications
- ✅ Application URLs for email/SMS links
- ✅ 2FA configuration constants
- ✅ Magic link TTL configuration
- ✅ Comprehensive documentation with setup guides
- ✅ Token expiry constants
- ✅ Communication retry configuration

---

### 0.4 Observability Foundation

**Objective:** Set up structured logging, error tracking, and metrics.

**Duration:** 1-2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create `packages/observability/src/logger.ts`:**
   ```typescript
   import pino from 'pino';
   import { config } from '@singr/config';
   
   const isDevelopment = config.NODE_ENV === 'development';
   
   export const logger = pino({
     level: config.LOG_LEVEL,
     formatters: {
       level: (label) => ({ level: label.toUpperCase() }),
       bindings: (bindings) => ({
         pid: bindings.pid,
         hostname: bindings.hostname,
       }),
     },
     timestamp: pino.stdTimeFunctions.isoTime,
     redact: {
       paths: [
         'req.headers.authorization',
         'req.headers["x-api-key"]',
         'password',
         'passwordHash',
         'apiKeyHash',
         'refreshToken',
         'accessToken',
       ],
       remove: true,
     },
     serializers: {
       req: (req: any) => ({
         method: req.method,
         url: req.url,
         headers: {
           host: req.headers.host,
           'user-agent': req.headers['user-agent'],
         },
       }),
       res: (res: any) => ({
         statusCode: res.statusCode,
       }),
       err: pino.stdSerializers.err,
     },
     ...(isDevelopment && {
       transport: {
         target: 'pino-pretty',
         options: {
           colorize: true,
           singleLine: false,
           translateTime: 'SYS:standard',
           ignore: 'pid,hostname',
         },
       },
     }),
   });
   
   // Create child loggers by module
   export function createLogger(module: string) {
     return logger.child({ module });
   }
   ```

2. **Initialize Sentry in `packages/observability/src/sentry.ts`:**
   ```typescript
   import * as Sentry from '@sentry/node';
   import { config } from '@singr/config';
   import { logger } from './logger';
   
   export function initSentry() {
     if (!config.SENTRY_DSN) {
       logger.debug('Sentry not configured (SENTRY_DSN not set)');
       return;
     }
   
     Sentry.init({
       dsn: config.SENTRY_DSN,
       environment: config.NODE_ENV,
       tracesSampleRate: config.NODE_ENV === 'production' ? 0.1 : 1.0,
       integrations: [
         new Sentry.Integrations.Http({ tracing: true }),
         new Sentry.Integrations.OnUncaughtException(),
         new Sentry.Integrations.OnUnhandledRejection(),
       ],
       beforeSend(event, hint) {
         // Filter out known non-critical errors
         if (event.exception) {
           const error = hint.originalException;
           if (error instanceof Error) {
             if (error.message.includes('ECONNREFUSED')) {
               return null; // Skip connection errors in development
             }
           }
         }
         return event;
       },
     });
   
     logger.info('Sentry initialized');
   }
   
   export { Sentry };
   ```

3. **Create correlation ID middleware for request tracing:**
   ```typescript
   // packages/observability/src/middleware/correlation-id.ts
   import { randomUUID } from 'crypto';
   import { FastifyRequest, FastifyReply } from 'fastify';
   
   export async function correlationIdMiddleware(
     request: FastifyRequest,
     reply: FastifyReply
   ) {
     const correlationId =
       (request.headers['x-request-id'] as string) || randomUUID();
   
     request.headers['x-request-id'] = correlationId;
     reply.header('x-request-id', correlationId);
   
     // Enhance logger with correlation ID
     request.log = request.log.child({ correlationId });
   
     // Make available in Sentry
     if (request.user) {
       Sentry.setTag('correlationId', correlationId);
       Sentry.setUser({
         id: request.user.sub,
         email: request.user.email,
       });
     }
   }
   ```

4. **Create metrics endpoint:**
   ```typescript
   // packages/observability/src/metrics.ts
   import { FastifyInstance } from 'fastify';
   
   export class MetricsCollector {
     private requestCount = 0;
     private errorCount = 0;
     private totalLatency = 0;
     private requestCounts: Record<string, number> = {};
   
     recordRequest(method: string, path: string, statusCode: number, duration: number) {
       this.requestCount++;
       this.totalLatency += duration;
   
       const key = `${method} ${path}`;
       this.requestCounts[key] = (this.requestCounts[key] || 0) + 1;
   
       if (statusCode >= 400) {
         this.errorCount++;
       }
     }
   
     getMetrics() {
       return {
         uptime: process.uptime(),
         memory: process.memoryUsage(),
         totalRequests: this.requestCount,
         totalErrors: this.errorCount,
         avgLatency: this.requestCount > 0 ? this.totalLatency / this.requestCount : 0,
         requestsByEndpoint: this.requestCounts,
       };
     }
   
     toPrometheusFormat() {
       const metrics = this.getMetrics();
       return [
         `# HELP singr_requests_total Total number of requests`,
         `# TYPE singr_requests_total counter`,
         `singr_requests_total ${metrics.totalRequests}`,
         `# HELP singr_errors_total Total number of errors`,
         `# TYPE singr_errors_total counter`,
         `singr_errors_total ${metrics.totalErrors}`,
         `# HELP singr_latency_avg Average request latency in ms`,
         `# TYPE singr_latency_avg gauge`,
         `singr_latency_avg ${metrics.avgLatency}`,
       ].join('\n');
     }
   }
   
   export function registerMetricsEndpoint(
     fastify: FastifyInstance,
     collector: MetricsCollector
   ) {
     fastify.get('/metrics', async (request, reply) => {
       return reply
         .type('text/plain; version=0.0.4')
         .send(collector.toPrometheusFormat());
     });
   }
   ```

**Deliverables:**
- ✅ Structured JSON logging with pino
- ✅ Sentry error tracking configured
- ✅ Correlation IDs in all requests
- ✅ Sensitive data redacted from logs
- ✅ Prometheus-compatible metrics endpoint
- ✅ Request/error/latency metrics

---


### 0.5: Communication Infrastructure

**Objective:** Set up Mailjet, Twilio, email templates, SMS formatting, and BullMQ worker for async delivery.

**Duration:** 3-4 days  
**Team Size:** 1-2 developers

### 0.5.1 Mailjet Email Service

**Tasks:**

1. **Create Mailjet client in `packages/shared/src/services/email/mailjet-client.ts`:**
   ```typescript
   import Mailjet from 'node-mailjet';
   import { config } from '@singr/config';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('services:mailjet');

   export const mailjetClient = Mailjet.apiConnect(
     config.MAILJET_API_KEY,
     config.MAILJET_SECRET_KEY
   );

   export interface SendEmailParams {
     to: string;
     toName?: string;
     subject: string;
     templateId?: number;
     variables?: Record<string, any>;
     htmlPart?: string;
     textPart?: string;
   }

   export async function sendEmail(params: SendEmailParams): Promise<boolean> {
     try {
       if (!config.ENABLE_EMAIL_SENDING) {
         logger.info(
           {
             to: params.to,
             subject: params.subject,
             templateId: params.templateId,
           },
           'Email sending disabled - would have sent'
         );
         return true;
       }

       if (config.EMAIL_PROVIDER === 'console') {
         logger.info(
           {
             to: params.to,
             toName: params.toName,
             subject: params.subject,
             templateId: params.templateId,
             variables: params.variables,
           },
           '📧 EMAIL (Console Provider)'
         );
         return true;
       }

       const request = mailjetClient.post('send', { version: 'v3.1' });

       const message: any = {
         From: {
           Email: config.MAILJET_FROM_EMAIL,
           Name: config.MAILJET_FROM_NAME,
         },
         To: [
           {
             Email: params.to,
             Name: params.toName || params.to,
           },
         ],
         Subject: params.subject,
       };

       if (params.templateId) {
         message.TemplateID = params.templateId;
         message.TemplateLanguage = true;
         message.Variables = params.variables || {};
       } else {
         message.HTMLPart = params.htmlPart;
         message.TextPart = params.textPart;
       }

       const result = await request.request({
         Messages: [message],
       });

       logger.info(
         {
           to: params.to,
           subject: params.subject,
           messageId: result.body.Messages[0]?.To[0]?.MessageID,
         },
         'Email sent via Mailjet'
       );

       return true;
     } catch (error) {
       logger.error(
         {
           error,
           to: params.to,
           subject: params.subject,
         },
         'Failed to send email via Mailjet'
       );
       throw new Error('Failed to send email');
     }
   }

   export async function sendBulkEmail(
     emails: SendEmailParams[]
   ): Promise<boolean> {
     try {
       if (!config.ENABLE_EMAIL_SENDING || config.EMAIL_PROVIDER === 'console') {
         logger.info({ count: emails.length }, 'Bulk email (console mode)');
         return true;
       }

       const request = mailjetClient.post('send', { version: 'v3.1' });

       const messages = emails.map((params) => ({
         From: {
           Email: config.MAILJET_FROM_EMAIL,
           Name: config.MAILJET_FROM_NAME,
         },
         To: [
           {
             Email: params.to,
             Name: params.toName || params.to,
           },
         ],
         Subject: params.subject,
         TemplateID: params.templateId,
         TemplateLanguage: true,
         Variables: params.variables || {},
       }));

       await request.request({ Messages: messages });

       logger.info({ count: emails.length }, 'Bulk emails sent via Mailjet');

       return true;
     } catch (error) {
       logger.error({ error, count: emails.length }, 'Failed to send bulk emails');
       throw new Error('Failed to send bulk emails');
     }
   }
   ```

2. **Create email service with templates in `packages/shared/src/services/email/email-service.ts`:**
   ```typescript
   import { config, TOKEN_EXPIRY } from '@singr/config';
   import { sendEmail } from './mailjet-client';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('services:email');

   export class EmailService {
     async sendVerificationEmail(
       to: string,
       name: string,
       verificationToken: string
     ): Promise<void> {
       const verificationLink = `${config.APP_URL_WEB}/verify-email?token=${verificationToken}`;

       await sendEmail({
         to,
         toName: name,
         subject: 'Verify your Singr account',
         templateId: config.MAILJET_TEMPLATE_VERIFICATION,
         variables: {
           user_name: name,
           verification_link: verificationLink,
           verification_code: verificationToken.substring(0, 6).toUpperCase(),
           expiry_hours: Math.floor(TOKEN_EXPIRY.EMAIL_VERIFICATION / (1000 * 60 * 60)),
         },
       });

       logger.info({ to, name }, 'Verification email queued');
     }

     async sendPasswordResetEmail(
       to: string,
       name: string,
       resetToken: string
     ): Promise<void> {
       const resetLink = `${config.APP_URL_WEB}/reset-password?token=${resetToken}`;

       await sendEmail({
         to,
         toName: name,
         subject: 'Reset your Singr password',
         templateId: config.MAILJET_TEMPLATE_PASSWORD_RESET,
         variables: {
           user_name: name,
           reset_link: resetLink,
           expiry_minutes: Math.floor(TOKEN_EXPIRY.PASSWORD_RESET / (1000 * 60)),
         },
       });

       logger.info({ to, name }, 'Password reset email queued');
     }

     async sendMagicLinkEmail(
       to: string,
       magicToken: string,
       ipAddress: string
     ): Promise<void> {
       const magicLink = `${config.APP_URL_WEB}/auth/magic?token=${magicToken}`;

       await sendEmail({
         to,
         subject: 'Sign in to Singr',
         templateId: config.MAILJET_TEMPLATE_MAGIC_LINK,
         variables: {
           user_email: to,
           magic_link: magicLink,
           expiry_minutes: Math.floor(config.MAGIC_LINK_TTL / 60),
           ip_address: ipAddress,
         },
       });

       logger.info({ to, ipAddress }, 'Magic link email queued');
     }

     async sendTwoFactorEmail(
       to: string,
       name: string,
       code: string
     ): Promise<void> {
       await sendEmail({
         to,
         toName: name,
         subject: 'Your Singr verification code',
         templateId: config.MAILJET_TEMPLATE_TWO_FACTOR,
         variables: {
           user_name: name,
           code,
           expiry_minutes: 5,
         },
       });

       logger.info({ to, name }, '2FA code email queued');
     }

     async sendWelcomeEmail(
       to: string,
       name: string,
       accountType: 'customer' | 'singer'
     ): Promise<void> {
       await sendEmail({
         to,
         toName: name,
         subject: 'Welcome to Singr!',
         templateId: config.MAILJET_TEMPLATE_WELCOME,
         variables: {
           user_name: name,
           account_type: accountType,
           dashboard_link:
             accountType === 'customer'
               ? config.APP_URL_CUSTOMER
               : config.APP_URL_WEB,
         },
       });

       logger.info({ to, name, accountType }, 'Welcome email queued');
     }

     async sendInvitationEmail(
       to: string,
       inviterName: string,
       organizationName: string,
       invitationToken: string
     ): Promise<void> {
       const invitationLink = `${config.APP_URL_CUSTOMER}/invitation?token=${invitationToken}`;

       await sendEmail({
         to,
         subject: `${inviterName} invited you to ${organizationName}`,
         templateId: config.MAILJET_TEMPLATE_INVITATION,
         variables: {
           inviter_name: inviterName,
           organization_name: organizationName,
           invitation_link: invitationLink,
           expiry_days: Math.floor(TOKEN_EXPIRY.INVITATION / (1000 * 60 * 60 * 24)),
         },
       });

       logger.info({ to, inviterName, organizationName }, 'Invitation email queued');
     }

     async sendRequestNotification(
       to: string,
       venueName: string,
       artist: string,
       title: string,
       singerName?: string
     ): Promise<void> {
       await sendEmail({
         to,
         subject: `New song request at ${venueName}`,
         htmlPart: `
           <h2>New Song Request</h2>
           <p><strong>Venue:</strong> ${venueName}</p>
           <p><strong>Song:</strong> ${artist} - ${title}</p>
           ${singerName ? `<p><strong>Requested by:</strong> ${singerName}</p>` : ''}
           <p><a href="${config.APP_URL_CUSTOMER}/requests">View Request</a></p>
         `,
         textPart: `New song request at ${venueName}: ${artist} - ${title}${
           singerName ? ` (by ${singerName})` : ''
         }`,
       });

       logger.info({ to, venueName, artist, title }, 'Request notification email queued');
     }
   }
   ```

### 0.5.2 Twilio SMS Service

**Tasks:**

1. **Create Twilio client in `packages/shared/src/services/sms/twilio-client.ts`:**
   ```typescript
   import twilio from 'twilio';
   import { config } from '@singr/config';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('services:twilio');

   export const twilioClient = twilio(
     config.TWILIO_ACCOUNT_SID,
     config.TWILIO_AUTH_TOKEN
   );

   export interface SendSMSParams {
     to: string;
     body: string;
   }

   export async function sendSMS(params: SendSMSParams): Promise<boolean> {
     try {
       if (!config.ENABLE_SMS_SENDING) {
         logger.info(
           {
             to: params.to,
             body: params.body,
           },
           'SMS sending disabled - would have sent'
         );
         return true;
       }

       if (config.SMS_PROVIDER === 'console') {
         logger.info(
           {
             to: params.to,
             body: params.body,
           },
           '📱 SMS (Console Provider)'
         );
         return true;
       }

       const message = await twilioClient.messages.create({
         body: params.body,
         from: config.TWILIO_PHONE_NUMBER,
         to: params.to,
       });

       logger.info(
         {
           to: params.to,
           messageSid: message.sid,
           status: message.status,
         },
         'SMS sent via Twilio'
       );

       return true;
     } catch (error) {
       logger.error(
         {
           error,
           to: params.to,
         },
         'Failed to send SMS via Twilio'
       );
       throw new Error('Failed to send SMS');
     }
   }

   export async function sendVerificationCode(
     to: string,
     channel: 'sms' | 'call' = 'sms'
   ): Promise<string> {
     try {
       if (!config.TWILIO_VERIFY_SERVICE_SID) {
         throw new Error('Twilio Verify Service SID not configured');
       }

       if (config.SMS_PROVIDER === 'console') {
         const mockCode = '123456';
         logger.info({ to, channel }, `📱 Verification Code: ${mockCode}`);
         return mockCode;
       }

       const verification = await twilioClient.verify.v2
         .services(config.TWILIO_VERIFY_SERVICE_SID)
         .verifications.create({ to, channel });

       logger.info(
         {
           to,
           channel,
           status: verification.status,
         },
         'Verification code sent via Twilio Verify'
       );

       return verification.sid;
     } catch (error) {
       logger.error({ error, to, channel }, 'Failed to send verification code');
       throw new Error('Failed to send verification code');
     }
   }

   export async function checkVerificationCode(
     to: string,
     code: string
   ): Promise<boolean> {
     try {
       if (!config.TWILIO_VERIFY_SERVICE_SID) {
         throw new Error('Twilio Verify Service SID not configured');
       }

       if (config.SMS_PROVIDER === 'console') {
         logger.info({ to, code }, '📱 Verification check (console - always true)');
         return code === '123456';
       }

       const verificationCheck = await twilioClient.verify.v2
         .services(config.TWILIO_VERIFY_SERVICE_SID)
         .verificationChecks.create({ to, code });

       logger.info(
         {
           to,
           status: verificationCheck.status,
         },
         'Verification code checked'
       );

       return verificationCheck.status === 'approved';
     } catch (error) {
       logger.error({ error, to }, 'Failed to check verification code');
       return false;
     }
   }
   ```

2. **Create SMS service in `packages/shared/src/services/sms/sms-service.ts`:**
   ```typescript
   import { sendSMS, sendVerificationCode, checkVerificationCode } from './twilio-client';
   import { config, TWO_FACTOR } from '@singr/config';
   import { createLogger } from '@singr/observability';
   import { randomInt } from 'crypto';

   const logger = createLogger('services:sms');

   export class SMSService {
     async sendVerificationSMS(to: string, code: string): Promise<void> {
       await sendSMS({
         to,
         body: `Your Singr verification code is: ${code}. Valid for 5 minutes.`,
       });

       logger.info({ to }, 'Verification SMS queued');
     }

     async sendTwoFactorSMS(to: string, code: string): Promise<void> {
       await sendSMS({
         to,
         body: `Your Singr 2FA code is: ${code}. Valid for 5 minutes. Do not share this code.`,
       });

       logger.info({ to }, '2FA SMS queued');
     }

     async sendMagicLinkSMS(to: string, magicToken: string): Promise<void> {
       const magicLink = `${config.APP_URL_WEB}/auth/magic?token=${magicToken}`;

       await sendSMS({
         to,
         body: `Sign in to Singr: ${magicLink} (expires in ${Math.floor(
           config.MAGIC_LINK_TTL / 60
         )} minutes)`,
       });

       logger.info({ to }, 'Magic link SMS queued');
     }

     generateVerificationCode(): string {
       return randomInt(0, 999999).toString().padStart(6, '0');
     }

     async sendVerificationCodeViaTwilioVerify(
       to: string,
       channel: 'sms' | 'call' = 'sms'
     ): Promise<void> {
       await sendVerificationCode(to, channel);
       logger.info({ to, channel }, 'Twilio Verify code sent');
     }

     async verifyCodeViaTwilioVerify(to: string, code: string): Promise<boolean> {
       return await checkVerificationCode(to, code);
     }
   }
   ```

### 0.5.3 BullMQ Worker Setup

**Tasks:**

1. **Create job types in `packages/shared/src/types/jobs.ts`:**
   ```typescript
   export interface EmailJob {
     type: 'email';
     to: string;
     toName?: string;
     subject: string;
     templateId?: number;
     variables?: Record<string, any>;
     htmlPart?: string;
     textPart?: string;
   }

   export interface SMSJob {
     type: 'sms';
     to: string;
     body: string;
   }

   export interface TwoFactorJob {
     type: 'two_factor';
     userId: string;
     method: 'email' | 'sms';
     code: string;
   }

   export type CommunicationJob = EmailJob | SMSJob | TwoFactorJob;
   ```

2. **Create queue setup in `packages/shared/src/queues/communication-queue.ts`:**
   ```typescript
   import { Queue } from 'bullmq';
   import { Redis } from 'ioredis';
   import { config, COMMUNICATION_RETRY } from '@singr/config';
   import { createLogger } from '@singr/observability';
   import type { CommunicationJob } from '../types/jobs';

   const logger = createLogger('queues:communication');

   export function createCommunicationQueue(redis: Redis): Queue<CommunicationJob> {
     const queue = new Queue<CommunicationJob>('communication', {
       connection: redis,
       defaultJobOptions: {
         attempts: COMMUNICATION_RETRY.maxAttempts,
         backoff: {
           type: 'exponential',
           delay: COMMUNICATION_RETRY.backoffMs,
         },
         removeOnComplete: {
           age: 24 * 60 * 60, // Keep completed jobs for 24 hours
           count: 1000,
         },
         removeOnFail: {
           age: 7 * 24 * 60 * 60, // Keep failed jobs for 7 days
         },
       },
     });

     queue.on('error', (error) => {
       logger.error({ error }, 'Communication queue error');
     });

     return queue;
   }

   export async function enqueueCommunication(
     queue: Queue<CommunicationJob>,
     job: CommunicationJob,
     priority?: number
   ): Promise<void> {
     await queue.add(job.type, job, { priority });
     logger.debug({ type: job.type }, 'Communication job enqueued');
   }
   ```

3. **Create worker in `apps/worker/src/processors/communication-processor.ts`:**
   ```typescript
   import { Job } from 'bullmq';
   import { EmailService } from '@singr/shared/services/email/email-service';
   import { SMSService } from '@singr/shared/services/sms/sms-service';
   import { sendEmail } from '@singr/shared/services/email/mailjet-client';
   import { sendSMS } from '@singr/shared/services/sms/twilio-client';
   import { createLogger } from '@singr/observability';
   import type { CommunicationJob, EmailJob, SMSJob } from '@singr/shared/types/jobs';

   const logger = createLogger('worker:communication');

   export async function processCommunicationJob(
     job: Job<CommunicationJob>
   ): Promise<void> {
     const { data } = job;

     try {
       switch (data.type) {
         case 'email':
           await processEmailJob(data);
           break;

         case 'sms':
           await processSMSJob(data);
           break;

         case 'two_factor':
           await processTwoFactorJob(data);
           break;

         default:
           logger.warn({ type: (data as any).type }, 'Unknown job type');
       }

       logger.info({ jobId: job.id, type: data.type }, 'Communication job processed');
     } catch (error) {
       logger.error(
         {
           error,
           jobId: job.id,
           type: data.type,
           attempt: job.attemptsMade,
         },
         'Failed to process communication job'
       );
       throw error;
     }
   }

   async function processEmailJob(data: EmailJob): Promise<void> {
     await sendEmail({
       to: data.to,
       toName: data.toName,
       subject: data.subject,
       templateId: data.templateId,
       variables: data.variables,
       htmlPart: data.htmlPart,
       textPart: data.textPart,
     });
   }

   async function processSMSJob(data: SMSJob): Promise<void> {
     await sendSMS({
       to: data.to,
       body: data.body,
     });
   }

   async function processTwoFactorJob(data: any): Promise<void> {
     // Implementation will be added in Phase 4.6
     logger.info({ userId: data.userId, method: data.method }, '2FA job processed');
   }
   ```

4. **Create worker entry point in `apps/worker/src/index.ts`:**
   ```typescript
   import { Worker } from 'bullmq';
   import { Redis } from 'ioredis';
   import { config } from '@singr/config';
   import { createLogger, initSentry } from '@singr/observability';
   import { processCommunicationJob } from './processors/communication-processor';

   const logger = createLogger('worker');

   async function startWorker() {
     initSentry();

     const redis = new Redis(config.REDIS_URL, {
       maxRetriesPerRequest: null,
     });

     const worker = new Worker('communication', processCommunicationJob, {
       connection: redis,
       concurrency: 10,
       limiter: {
         max: 100,
         duration: 60000, // 100 jobs per minute
       },
     });

     worker.on('completed', (job) => {
       logger.info({ jobId: job.id }, 'Job completed');
     });

     worker.on('failed', (job, error) => {
       logger.error(
         {
           jobId: job?.id,
           error,
           attempts: job?.attemptsMade,
         },
         'Job failed'
       );
     });

     worker.on('error', (error) => {
       logger.error({ error }, 'Worker error');
     });

     logger.info('Communication worker started');

     // Graceful shutdown
     const shutdown = async (signal: string) => {
       logger.info(`Received ${signal}, shutting down gracefully`);
       await worker.close();
       await redis.quit();
       process.exit(0);
     };

     process.on('SIGINT', () => shutdown('SIGINT'));
     process.on('SIGTERM', () => shutdown('SIGTERM'));
   }

   startWorker().catch((error) => {
     logger.error({ error }, 'Failed to start worker');
     process.exit(1);
   });
   ```

5. **Add worker scripts to `apps/worker/package.json`:**
   ```json
   {
     "name": "@singr/worker",
     "version": "1.0.0",
     "scripts": {
       "dev": "tsx watch src/index.ts",
       "build": "tsc",
       "start": "node dist/index.js"
     },
     "dependencies": {
       "bullmq": "^5.x",
       "ioredis": "^5.x",
       "@singr/config": "workspace:*",
       "@singr/shared": "workspace:*",
       "@singr/observability": "workspace:*"
     }
   }
   ```

6. **Update docker-compose to include worker:**
   ```yaml
   # Add to docker/docker-compose.yml
   worker:
     build:
       context: ..
       dockerfile: docker/worker.Dockerfile
     container_name: singr-worker
     environment:
       - NODE_ENV=development
       - REDIS_URL=redis://redis:6379
       - DATABASE_URL=postgresql://singr:password@postgres:5432/singr_dev
     depends_on:
       - postgres
       - redis
     restart: unless-stopped
   ```

**Deliverables:**
- ✅ Mailjet client with template support
- ✅ Email service with all email types (verification, password reset, magic link, 2FA, welcome, invitation)
- ✅ Twilio client with SMS and Verify API support
- ✅ SMS service with verification and 2FA codes
- ✅ BullMQ queue setup for async communication
- ✅ Worker service to process email/SMS jobs
- ✅ Retry logic with exponential backoff
- ✅ Console providers for development
- ✅ Feature flags for email/SMS sending
- ✅ Comprehensive logging and error handling
- ✅ Job persistence and cleanup
- ✅ Rate limiting at worker level

---





## Phase 1: Database Schema & Core Models

### 1.1 PostgreSQL + PostGIS Setup

**Objective:** Initialize database with extensions and migrations infrastructure.

**Duration:** 2-3 days  
**Team Size:** 1-2 developers

**Tasks:**

1. **Create `packages/database/prisma/schema.prisma` with datasource:**
   ```prisma
   generator client {
     provider = "prisma-client-js"
     previewFeatures = ["postgresqlExtensions"]
   }
   
   datasource db {
     provider = "postgresql"
     url      = env("DATABASE_URL")
     extensions = [postgis, pgcrypto]
   }
   ```

2. **Create initial migration (`0001_init.sql`):**
   ```sql
   CREATE EXTENSION IF NOT EXISTS "pgcrypto";
   CREATE EXTENSION IF NOT EXISTS "postgis";
   
   -- Set up updated_at trigger function
   CREATE OR REPLACE FUNCTION set_updated_at()
   RETURNS trigger AS $$
   BEGIN
     NEW.updated_at = NOW();
     RETURN NEW;
   END;
   $$ LANGUAGE plpgsql;
   
   -- Set up audit logging function
   CREATE OR REPLACE FUNCTION record_audit()
   RETURNS trigger AS $$
   DECLARE
     v_old JSONB;
     v_new JSONB;
   BEGIN
     IF (TG_OP = 'DELETE') THEN
       v_old = TO_JSONB(OLD);
       v_new = NULL;
     ELSIF (TG_OP = 'UPDATE') THEN
       v_old = TO_JSONB(OLD);
       v_new = TO_JSONB(NEW);
     ELSE
       v_old = NULL;
       v_new = TO_JSONB(NEW);
     END IF;
   
     INSERT INTO audit_logs (
       audit_logs_id,
       table_name,
       record_id,
       user_id,
       operation,
       old_data,
       new_data
     ) VALUES (
       GEN_RANDOM_UUID(),
       TG_TABLE_NAME,
       COALESCE(NEW.id::TEXT, NEW.*::JSONB ->> 'id', OLD.id::TEXT, OLD.*::JSONB ->> 'id'),
       COALESCE(current_setting('app.current_user_id', true), NULL),
       TG_OP,
       v_old,
       v_new
     );
   
     IF (TG_OP = 'DELETE') THEN
       RETURN OLD;
     ELSE
       RETURN NEW;
     END IF;
   END;
   $$ LANGUAGE plpgsql SECURITY DEFINER;
   
   -- Create ENUM types
   CREATE TYPE branding_owner_type AS ENUM ('platform', 'customer');
   CREATE TYPE branding_status AS ENUM ('active', 'suspended', 'revoked');
   CREATE TYPE organization_user_status AS ENUM ('invited', 'active', 'suspended', 'revoked');
   CREATE TYPE api_key_status AS ENUM ('active', 'revoked', 'expired', 'suspended');
   ```

3. **Add Prisma scripts to `packages/database/package.json`:**
   ```json
   {
     "scripts": {
       "db:generate": "prisma generate",
       "db:migrate:dev": "prisma migrate dev",
       "db:migrate:deploy": "prisma migrate deploy",
       "db:studio": "prisma studio",
       "db:seed": "tsx prisma/seed.ts",
       "db:reset": "prisma migrate reset --force",
       "db:push": "prisma db push"
     }
   }
   ```

4. **Create reusable Prisma client singleton:**
   ```typescript
   // packages/database/src/client.ts
   import { PrismaClient } from '@prisma/client';
   import { createLogger } from '@singr/observability';
   
   const logger = createLogger('prisma');
   
   const globalForPrisma = globalThis as unknown as { prisma: PrismaClient };
   
   export const prisma =
     globalForPrisma.prisma ||
     new PrismaClient({
       log: [
         { emit: 'event', level: 'query' },
         { emit: 'event', level: 'error' },
         { emit: 'event', level: 'warn' },
       ],
     });
   
   if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;
   
   // Log queries in development
   if (process.env.NODE_ENV === 'development') {
     prisma.$on('query', (e) => {
       logger.debug(
         {
           duration: e.duration,
           query: e.query.substring(0, 200),
         },
         'Database query'
       );
     });
   }
   
   prisma.$on('error', (e) => {
     logger.error({ error: e }, 'Database error');
   });
   ```

**Deliverables:**
- ✅ Prisma schema matches backend-plan.MD DDL
- ✅ Migrations run successfully with PostGIS
- ✅ `prisma generate` creates typed client
- ✅ Database triggers for updated_at and audit logs
- ✅ Development and production ready

---

### 1.2 Complete Prisma Schema Implementation

**Objective:** Implement full schema from backend-plan.MD with all relationships.

**Duration:** 3-4 days  
**Team Size:** 2 developers

**Tasks:**

1. **Define all enums and models in `packages/database/prisma/schema.prisma`:**
   ```prisma
   enum BrandingOwnerType {
     platform
     customer
     @@map("branding_owner_type")
   }

   enum BrandingStatus {
     active
     suspended
     revoked
     @@map("branding_status")
   }

   enum OrganizationUserStatus {
     invited
     active
     suspended
     revoked
     @@map("organization_user_status")
   }

   enum ApiKeyStatus {
     active
     revoked
     expired
     suspended
     @@map("api_key_status")
   }

   // ========== Core Identity Models ==========

   model User {
     id              String      @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("users_id")
     email           String      @unique
     passwordHash    String?     @map("password_hash")
     passwordAlgo    String?     @map("password_algo")
     name            String?
     displayName     String?     @map("display_name")
     phoneNumber     String?     @map("phone_number")
     imageUrl        String?     @map("image_url")
     isEmailVerified Boolean     @default(false) @map("is_email_verified")
     lastLoginAt     DateTime?   @map("last_login_at") @db.Timestamptz(6)
     createdAt       DateTime    @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt       DateTime    @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     customerProfile      CustomerProfile?
     singerProfile        SingerProfile?
     accounts             Account[]
     sessions             Session[]
     userRoles            UserRole[]
     organizationUsers    OrganizationUser[] @relation("OrganizationUserUser")
     organizationInvites  OrganizationUser[] @relation("OrganizationUserInvitedBy")
     apiKeys              ApiKey[]           @relation("ApiKeyCreatedBy")
     requests             Request[]          @relation("RequestSubmittedBy")

     @@map("users")
   }

   model Role {
     id              String           @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("roles_id")
     slug            String           @unique
     description     String?
     isSystem        Boolean          @default(false) @map("is_system")
     createdAt       DateTime         @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt       DateTime         @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     rolePermissions RolePermission[]
     userRoles       UserRole[]
     organizationUsers OrganizationUser[]

     @@map("roles")
   }

   model Permission {
     id          String            @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("permissions_id")
     slug        String            @unique
     description String?
     createdAt   DateTime          @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt   DateTime          @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     rolePermissions            RolePermission[]
     organizationUserPermissions OrganizationUserPermission[]

     @@map("permissions")
   }

   model RolePermission {
     id           String     @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("role_permissions_id")
     roleId       String     @map("roles_id") @db.Uuid
     permissionId String     @map("permissions_id") @db.Uuid
     createdAt    DateTime   @default(now()) @map("created_at") @db.Timestamptz(6)

     role       Role       @relation(fields: [roleId], references: [id], onDelete: Cascade, onUpdate: Cascade)
     permission Permission @relation(fields: [permissionId], references: [id], onDelete: Cascade, onUpdate: Cascade)

     @@unique([roleId, permissionId], map: "ux_role_permissions_role_permission")
     @@map("role_permissions")
   }

   model UserRole {
     id        String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("user_roles_id")
     userId    String   @map("users_id") @db.Uuid
     roleId    String   @map("roles_id") @db.Uuid
     createdAt DateTime @default(now()) @map("created_at") @db.Timestamptz(6)

     user User @relation(fields: [userId], references: [id], onDelete: Cascade, onUpdate: Cascade)
     role Role @relation(fields: [roleId], references: [id], onDelete: Cascade, onUpdate: Cascade)

     @@unique([userId, roleId], map: "ux_user_roles_user_role")
     @@map("user_roles")
   }

   model Account {
     id                String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("accounts_id")
     userId            String   @map("users_id") @db.Uuid
     provider          String
     providerAccountId String   @map("provider_account_id")
     type              String
     refreshToken      String?  @map("refresh_token")
     accessToken       String?  @map("access_token")
     expiresAt         BigInt?  @map("expires_at")
     tokenType         String?  @map("token_type")
     scope             String?
     idToken           String?  @map("id_token")
     sessionState      String?  @map("session_state")
     createdAt         DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt         DateTime @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     user User @relation(fields: [userId], references: [id], onDelete: Cascade, onUpdate: Cascade)

     @@unique([provider, providerAccountId])
     @@map("accounts")
   }

   model Session {
     id           String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("sessions_id")
     userId       String   @map("users_id") @db.Uuid
     sessionToken String   @unique @map("session_token")
     expiresAt    DateTime @map("expires_at") @db.Timestamptz(6)
     createdAt    DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt    DateTime @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     user User @relation(fields: [userId], references: [id], onDelete: Cascade, onUpdate: Cascade)

     @@map("sessions")
   }

   model VerificationToken {
     identifier String
     token      String
     expiresAt  DateTime @map("expires_at") @db.Timestamptz(6)
     createdAt  DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt  DateTime @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     @@id([identifier, token])
     @@index([expiresAt], map: "idx_verification_tokens_expires")
     @@map("verification_tokens")
   }

   // ========== Profile Models ==========

   model CustomerProfile {
     id                String      @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("customer_profiles_id")
     userId            String      @unique @map("users_id") @db.Uuid
     legalBusinessName String?     @map("legal_business_name")
     dbaName           String?     @map("dba_name")
     stripeCustomerId  String?     @map("stripe_customer_id")
     contactEmail      String?     @map("contact_email")
     contactPhone      String?     @map("contact_phone")
     timezone          String?     @default("UTC")
     billingAddress    Json?       @map("billing_address")
     metadata          Json?       @default("{}")
     createdAt         DateTime    @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt         DateTime    @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     user               User                    @relation(fields: [userId], references: [id], onDelete: Cascade, onUpdate: Cascade)
     customers          Customer[]
     apiKeys            ApiKey[]
     state              State?
     venues             Venue[]
     systems            System[]
     songdb             SongDb[]
     subscriptions      Subscription[]
     organizationUsers  OrganizationUser[]
     brandedApps        BrandedApp[]

     @@map("customer_profiles")
   }

   model SingerProfile {
     id          String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("singer_profiles_id")
     userId      String   @unique @map("users_id") @db.Uuid
     nickname    String?
     avatarUrl   String?  @map("avatar_url")
     preferences Json?    @default("{}")
     createdAt   DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt   DateTime @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     user            User                 @relation(fields: [userId], references: [id], onDelete: Cascade, onUpdate: Cascade)
     favoriteSongs   SingerFavoriteSong[]
     favoriteVenues  SingerFavoriteVenue[]
     requestHistory  SingerRequestHistory[]
     requests        Request[]

     @@map("singer_profiles")
   }

   // ========== Organization Models ==========

   model OrganizationUser {
     id                 String                 @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("organization_users_id")
     customerProfileId  String                 @map("customer_profiles_id") @db.Uuid
     userId             String                 @map("users_id") @db.Uuid
     invitedByUserId    String?                @map("invited_by_user_id") @db.Uuid
     roleId             String?                @map("role_id") @db.Uuid
     status             OrganizationUserStatus @default(invited)
     invitationToken    String?                @map("invitation_token")
     invitationExpiresAt DateTime?             @map("invitation_expires_at") @db.Timestamptz(6)
     lastAccessedAt     DateTime?              @map("last_accessed_at") @db.Timestamptz(6)
     createdAt          DateTime               @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt          DateTime               @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     customerProfile CustomerProfile @relation(fields: [customerProfileId], references: [id], onDelete: Cascade, onUpdate: Cascade)
     user            User            @relation("OrganizationUserUser", fields: [userId], references: [id], onDelete: Cascade, onUpdate: Cascade)
     invitedBy       User?           @relation("OrganizationUserInvitedBy", fields: [invitedByUserId], references: [id], onDelete: SetNull, onUpdate: Cascade)
     role            Role?           @relation(fields: [roleId], references: [id], onDelete: SetNull, onUpdate: Cascade)
     permissions     OrganizationUserPermission[]

     @@unique([customerProfileId, userId], map: "organization_users_customer_profiles_id_users_id_key")
     @@map("organization_users")
   }

   model OrganizationUserPermission {
     id                  String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("organization_user_permissions_id")
     organizationUserId  String   @map("organization_users_id") @db.Uuid
     permissionId        String   @map("permissions_id") @db.Uuid
     createdAt           DateTime @default(now()) @map("created_at") @db.Timestamptz(6)

     organizationUser OrganizationUser @relation(fields: [organizationUserId], references: [id], onDelete: Cascade, onUpdate: Cascade)
     permission       Permission       @relation(fields: [permissionId], references: [id], onDelete: Cascade, onUpdate: Cascade)

     @@unique([organizationUserId, permissionId], map: "ux_org_user_permissions")
     @@map("organization_user_permissions")
   }
   ```

2. **Continue with Stripe and billing models:**
   ```prisma
   // ========== Stripe Models ==========

   model Customer {
     id                String    @id @db.Uuid @map("customers_id")
     stripeCustomerId  String    @map("stripe_customer_id")
     customerProfileId String    @map("customer_profiles_id") @db.Uuid
     email             String?
     name              String?
     phone             String?
     description       String?
     metadata          Json      @default("{}")
     invoiceSettings   Json      @map("invoice_settings") @default("{}")
     shipping          Json      @default("{}")
     taxExempt         String?   @map("tax_exempt")
     taxIds            Json      @map("tax_ids") @default("[]")
     livemode          Boolean   @default(false)
     createdAt         DateTime  @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt         DateTime  @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     customerProfile   CustomerProfile       @relation(fields: [customerProfileId], references: [id], onDelete: Cascade, onUpdate: Cascade)
     apiKeys           ApiKey[]
     checkoutSessions  StripeCheckoutSession[]

     @@map("customers")
   }

   model StripeCheckoutSession {
     id            String   @id @map("stripe_checkout_sessions_id")
     customerId    String   @map("customers_id") @db.Uuid
     paymentStatus String   @map("payment_status")
     mode          String
     amountTotal   BigInt?  @map("amount_total")
     currency      String
     url           String?
     metadata      Json      @default("{}")
     completedAt   DateTime? @map("completed_at") @db.Timestamptz(6)
     expiresAt     DateTime? @map("expires_at") @db.Timestamptz(6)
     createdAt     DateTime  @default(now()) @map("created_at") @db.Timestamptz(6)

     customer Customer @relation(fields: [customerId], references: [id], onDelete: Cascade, onUpdate: Cascade)

     @@map("stripe_checkout_sessions")
   }

   model StripeProduct {
     id          String   @id @map("products_id")
     name        String?
     description String?
     active      Boolean  @default(true)
     metadata    Json     @default("{}")
     images      String[] @default([])
     livemode    Boolean  @default(false)
     createdAt   DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt   DateTime @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     prices StripePrice[]

     @@map("products")
   }

   model StripePrice {
     id         String       @id @map("prices_id")
     productId  String       @map("product_id")
     active     Boolean      @default(true)
     currency   String       @db.Char(3)
     type       String
     recurring  Json?
     unitAmount BigInt?      @map("unit_amount")
     metadata   Json         @default("{}")
     livemode   Boolean      @default(false)
     createdAt  DateTime     @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt  DateTime     @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     product StripeProduct @relation(fields: [productId], references: [id], onDelete: Cascade, onUpdate: Cascade)

     @@index([productId], map: "idx_prices_product")
     @@index([active], map: "idx_prices_active")
     @@map("prices")
   }

   model Subscription {
     id                 String   @id @map("subscriptions_id")
     customerProfileId  String   @map("customer_profiles_id") @db.Uuid
     status             String
     currentPeriodStart DateTime @map("current_period_start") @db.Timestamptz(6)
     currentPeriodEnd   DateTime @map("current_period_end") @db.Timestamptz(6)
     cancelAtPeriodEnd  Boolean  @default(false) @map("cancel_at_period_end")
     cancelAt           DateTime? @map("cancel_at") @db.Timestamptz(6)
     canceledAt         DateTime? @map("canceled_at") @db.Timestamptz(6)
     metadata           Json     @default("{}")
     livemode           Boolean  @default(false)
     createdAt          DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt          DateTime @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     customerProfile CustomerProfile @relation(fields: [customerProfileId], references: [id], onDelete: Cascade, onUpdate: Cascade)

     @@index([customerProfileId], map: "idx_subscriptions_customer_profile")
     @@index([status], map: "idx_subscriptions_status")
     @@map("subscriptions")
   }

   model StripeWebhookEvent {
     id             Int      @id @default(autoincrement()) @map("stripe_webhook_events_id")
     eventId        String   @unique @map("event_id")
     eventType      String   @map("event_type")
     payload        Json
     processed      Boolean  @default(false)
     processedAt    DateTime? @map("processed_at") @db.Timestamptz(6)
     receivedAt     DateTime @default(now()) @map("received_at") @db.Timestamptz(6)
     livemode       Boolean  @default(false)
     errorMessage   String?  @map("error_message")
     requestId      String?  @map("request_id")
     endpointSecret String?  @map("endpoint_secret")

     @@map("stripe_webhook_events")
   }

   // ========== API Key Models ==========

   model ApiKey {
     id                String       @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("api_keys_id")
     customerProfileId String       @map("customer_profiles_id") @db.Uuid
     customerId        String?      @map("customers_id") @db.Uuid
     createdByUserId   String?      @map("created_by_users_id") @db.Uuid
     description       String?
     apiKeyHash        String       @map("api_key_hash")
     lastUsedAt        DateTime?    @map("last_used_at") @db.Timestamptz(6)
     status            ApiKeyStatus @default(active)
     revokedAt         DateTime?    @map("revoked_at") @db.Timestamptz(6)
     metadata          Json?        @default("{}")
     createdAt         DateTime     @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt         DateTime     @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     customerProfile CustomerProfile @relation(fields: [customerProfileId], references: [id], onDelete: Cascade, onUpdate: Cascade)
     customer        Customer?        @relation(fields: [customerId], references: [id], onDelete: SetNull, onUpdate: Cascade)
     createdBy       User?            @relation("ApiKeyCreatedBy", fields: [createdByUserId], references: [id], onDelete: SetNull, onUpdate: Cascade)

     @@index([customerProfileId], map: "idx_api_keys_customer_profile")
     @@index([customerId], map: "idx_api_keys_customer")
     @@map("api_keys")
   }

   // ========== Venue Models ==========

   model State {
     customerProfileId String @id @map("customer_profiles_id") @db.Uuid
     serial            BigInt @default(1)

     customerProfile CustomerProfile @relation(fields: [customerProfileId], references: [id], onDelete: Cascade, onUpdate: Cascade)

     @@map("state")
   }

   model Venue {
     id                String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("venues_id")
     customerProfileId String   @map("customer_profiles_id") @db.Uuid
     openkjVenueId     Int      @map("openkj_venue_id")
     urlName           String   @unique @map("url_name")
     acceptingRequests Boolean  @default(true) @map("accepting_requests")
     name              String
     address           String
     city              String
     state             String
     postalCode        String   @map("postal_code")
     country           String?
     phoneNumber       String?  @map("phone_number")
     website           String?
     location          Unsupported("geography(Point,4326)")? @map("location")
     createdAt         DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt         DateTime @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     customerProfile CustomerProfile @relation(fields: [customerProfileId], references: [id], onDelete: Cascade, onUpdate: Cascade)
     requests        Request[]
     favoriteVenues  SingerFavoriteVenue[]
     requestHistory  SingerRequestHistory[]

     @@unique([customerProfileId, openkjVenueId], map: "venues_customer_profiles_id_openkj_venue_id_key")
     @@index([customerProfileId], map: "idx_venues_customer_profile")
     @@map("venues")
   }

   model System {
     id                String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("systems_id")
     customerProfileId String   @map("customer_profiles_id") @db.Uuid
     openkjSystemId    Int      @map("openkj_system_id")
     name              String
     configuration     Json?    @default("{}")
     createdAt         DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt         DateTime @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     customerProfile CustomerProfile @relation(fields: [customerProfileId], references: [id], onDelete: Cascade, onUpdate: Cascade)

     @@unique([customerProfileId, openkjSystemId], map: "systems_customer_profiles_id_openkj_system_id_key")
     @@index([customerProfileId], map: "idx_systems_customer_profile")
     @@map("systems")
   }
   ```

3. **Continue with song and request models:**
   ```prisma
   // ========== Song Database Models ==========

   model SongDb {
     id                 BigInt  @id @default(autoincrement()) @map("songdb_id")
     customerProfileId  String  @map("customer_profiles_id") @db.Uuid
     openkjSystemId     Int     @map("openkj_system_id")
     artist             String
     title              String
     combined           String
     normalizedCombined String  @map("normalized_combined")
     createdAt          DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt          DateTime @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     customerProfile CustomerProfile @relation(fields: [customerProfileId], references: [id], onDelete: Cascade, onUpdate: Cascade)

     @@unique([customerProfileId, openkjSystemId, combined], map: "songdb_customer_profiles_id_openkj_system_id_combined_key")
     @@unique([customerProfileId, openkjSystemId, normalizedCombined], map: "songdb_customer_profiles_id_openkj_system_id_normalized_combined_key")
     @@index([customerProfileId, openkjSystemId, artist], map: "idx_songdb_customer_system_artist")
     @@map("songdb")
   }

   // ========== Request Models ==========

   model Request {
     id                BigInt     @id @default(autoincrement()) @map("requests_id")
     venueId           String     @map("venues_id") @db.Uuid
     singerProfileId   String?    @map("singer_profiles_id") @db.Uuid
     submittedByUserId String?    @map("submitted_by_users_id") @db.Uuid
     artist            String
     title             String
     keyChange         Int        @default(0) @map("key_change")
     notes             String?
     processed         Boolean    @default(false)
     requestedAt       DateTime   @default(now()) @map("requested_at") @db.Timestamptz(6)
     processedAt       DateTime?  @map("processed_at") @db.Timestamptz(6)
     createdAt         DateTime   @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt         DateTime   @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     venue         Venue         @relation(fields: [venueId], references: [id], onDelete: Cascade, onUpdate: Cascade)
     singerProfile SingerProfile? @relation(fields: [singerProfileId], references: [id], onDelete: SetNull, onUpdate: Cascade)
     submittedBy   User?          @relation("RequestSubmittedBy", fields: [submittedByUserId], references: [id], onDelete: SetNull, onUpdate: Cascade)

     @@index([venueId, processed], map: "idx_requests_venue_processed")
     @@map("requests")
   }

   // ========== Singer Feature Models ==========

   model SingerFavoriteSong {
     id              String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("singer_favorite_songs_id")
     singerProfileId String   @map("singer_profiles_id") @db.Uuid
     artist          String?
     title           String?
     keyChange       Int      @default(0) @map("key_change")
     metadata        Json?    @default("{}")
     createdAt       DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt       DateTime @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     singerProfile SingerProfile @relation(fields: [singerProfileId], references: [id], onDelete: Cascade, onUpdate: Cascade)

     @@unique([singerProfileId, artist, title, keyChange])
     @@map("singer_favorite_songs")
   }

   model SingerRequestHistory {
     id              String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("singer_request_history_id")
     singerProfileId String   @map("singer_profiles_id") @db.Uuid
     venueId         String   @map("venues_id") @db.Uuid
     artist          String
     title           String
     keyChange       Int      @default(0) @map("key_change")
     requestedAt     DateTime @default(now()) @map("requested_at") @db.Timestamptz(6)
     songFingerprint String   @map("song_fingerprint")
     createdAt       DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt       DateTime @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     singerProfile SingerProfile @relation(fields: [singerProfileId], references: [id], onDelete: Cascade, onUpdate: Cascade)
     venue         Venue         @relation(fields: [venueId], references: [id], onDelete: Cascade, onUpdate: Cascade)

     @@index([singerProfileId, requestedAt], map: "idx_singer_request_history_profile")
     @@map("singer_request_history")
   }

   model SingerFavoriteVenue {
     singerProfileId String   @map("singer_profiles_id") @db.Uuid
     venueId         String   @map("venues_id") @db.Uuid
     createdAt       DateTime @default(now()) @map("created_at") @db.Timestamptz(6)

     singerProfile SingerProfile @relation(fields: [singerProfileId], references: [id], onDelete: Cascade, onUpdate: Cascade)
     venue         Venue         @relation(fields: [venueId], references: [id], onDelete: Cascade, onUpdate: Cascade)

     @@id([singerProfileId, venueId])
     @@map("singer_favorite_venues")
   }

   // ========== Branding Models ==========

   model BrandingProfile {
     id             String          @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("branding_profiles_id")
     ownerType      BrandingOwnerType @map("owner_type")
     ownerId        String?         @map("owner_id") @db.Uuid
     name           String
     logoUrl        String?         @map("logo_url")
     colorPalette   Json            @map("color_palette") @default("{}")
     poweredBySingr Boolean         @default(true) @map("powered_by_singr")
     domain         String?
     appBundleId    String?         @map("app_bundle_id")
     appPackageName String?         @map("app_package_name")
     status         BrandingStatus  @default(active)
     metadata       Json?           @default("{}")
     createdAt      DateTime        @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt      DateTime        @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     brandedApps BrandedApp[]

     @@unique([ownerType, ownerId, name], map: "branding_profiles_owner_type_owner_id_name_key")
     @@map("branding_profiles")
   }

   model BrandedApp {
     id               String         @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("branded_apps_id")
     customerProfileId String        @map("customer_profiles_id") @db.Uuid
     brandingProfileId String        @map("branding_profiles_id") @db.Uuid
     name             String
     platform         String
     bundleIdentifier String?        @map("bundle_identifier")
     status           BrandingStatus @default(active)
     config           Json           @default("{}")
     rateLimitOverride Json?         @map("rate_limit_override")
     createdAt        DateTime       @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt        DateTime       @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     customerProfile CustomerProfile @relation(fields: [customerProfileId], references: [id], onDelete: Cascade, onUpdate: Cascade)
     brandingProfile BrandingProfile @relation(fields: [brandingProfileId], references: [id], onDelete: Restrict, onUpdate: Cascade)
     apiKeys         BrandedAppApiKey[]

     @@map("branded_apps")
   }

   model BrandedAppApiKey {
     id           String         @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("branded_app_api_keys_id")
     brandedAppId String         @map("branded_apps_id") @db.Uuid
     apiKeyHash   String         @map("api_key_hash")
     description  String?
     lastUsedAt   DateTime?      @map("last_used_at") @db.Timestamptz(6)
     status       BrandingStatus @default(active)
     createdAt    DateTime       @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt    DateTime       @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     brandedApp BrandedApp @relation(fields: [brandedAppId], references: [id], onDelete: Cascade, onUpdate: Cascade)

     @@unique([brandedAppId, apiKeyHash])
     @@map("branded_app_api_keys")
   }

   // ========== Audit Models ==========

   model AuditLog {
     id        String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("audit_logs_id")
     tableName String   @map("table_name")
     recordId  String?  @map("record_id")
     userId    String?  @map("user_id") @db.Uuid
     operation String
     oldData   Json?    @map("old_data")
     newData   Json?    @map("new_data")
     createdAt DateTime @default(now()) @map("created_at") @db.Timestamptz(6)

     @@index([tableName, recordId], map: "idx_audit_logs_table_record")
     @@index([userId, createdAt], map: "idx_audit_logs_user_created_at")
     @@map("audit_logs")
   }
   ```

**Deliverables:**
- ✅ Complete Prisma schema with all entities
- ✅ All foreign keys, cascades, and indexes defined
- ✅ Schema validates with `prisma validate`
- ✅ TypeScript types generated from schema
- ✅ Multi-tenancy support through CustomerProfile
- ✅ Full audit trail capability

---

### 1.3 Database Seed Script

**Objective:** Populate database with baseline data for development.

**Duration:** 2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create `packages/database/prisma/seed.ts`:**
   ```typescript
   import { prisma } from '../src/client';
   import { createLogger } from '@singr/observability';
   import { hashPassword } from '@singr/auth';
   import { DEFAULT_ROLES, DEFAULT_PERMISSIONS } from '@singr/config';

   const logger = createLogger('seed');

   async function seed() {
     logger.info('Starting database seed...');

     try {
       // Clear existing data (in development only)
       if (process.env.NODE_ENV !== 'production') {
         logger.info('Clearing existing data...');
         // Order matters for foreign keys
         await prisma.organizationUserPermission.deleteMany();
         await prisma.organizationUser.deleteMany();
         await prisma.userRole.deleteMany();
         await prisma.rolePermission.deleteMany();
         await prisma.role.deleteMany();
         await prisma.permission.deleteMany();
         await prisma.user.deleteMany();
       }

       // Create system roles
       logger.info('Creating system roles...');
       const roles = await Promise.all(
         DEFAULT_ROLES.map((role) =>
           prisma.role.upsert({
             where: { slug: role.slug },
             update: {},
             create: role,
           })
         )
       );

       logger.info(`Created ${roles.length} roles`);

       // Create permissions
       logger.info('Creating permissions...');
       const permissions = await Promise.all(
         DEFAULT_PERMISSIONS.map((permission) =>
           prisma.permission.upsert({
             where: { slug: permission.slug },
             update: {},
             create: permission,
           })
         )
       );

       logger.info(`Created ${permissions.length} permissions`);

       // Attach permissions to roles
       logger.info('Attaching permissions to roles...');
       const adminRole = roles.find((r) => r.slug === 'admin')!;
       const customerOwnerRole = roles.find((r) => r.slug === 'customer_owner')!;
       const singerRole = roles.find((r) => r.slug === 'singer')!;

       // Admin gets all permissions
       await prisma.rolePermission.createMany({
         data: permissions.map((p) => ({
           roleId: adminRole.id,
           permissionId: p.id,
         })),
         skipDuplicates: true,
       });

       // Customer owner gets customer-related permissions
       const customerPermissions = permissions.filter(
         (p) =>
           p.slug.includes('venues:') ||
           p.slug.includes('systems:') ||
           p.slug.includes('api_keys:') ||
           p.slug.includes('songdb:') ||
           p.slug.includes('requests:') ||
           p.slug.includes('organization:') ||
           p.slug.includes('billing:') ||
           p.slug.includes('branding:')
       );

       await prisma.rolePermission.createMany({
         data: customerPermissions.map((p) => ({
           roleId: customerOwnerRole.id,
           permissionId: p.id,
         })),
         skipDuplicates: true,
       });

       logger.info('Permissions attached to roles');

       // Create platform branding profile
       logger.info('Creating platform branding profile...');
       const brandingProfile = await prisma.brandingProfile.upsert({
         where: {
           branding_profiles_owner_type_owner_id_name_key: {
             ownerType: 'platform',
             ownerId: null,
             name: 'Singr Default',
           },
         },
         update: {},
         create: {
           ownerType: 'platform',
           name: 'Singr Default',
           colorPalette: {
             primary: '#6366F1',
             secondary: '#8B5CF6',
             accent: '#EC4899',
           },
           poweredBySingr: true,
           status: 'active',
         },
       });

       logger.info('Platform branding profile created');

       // Create test admin user
       logger.info('Creating test admin user...');
       const adminUser = await prisma.user.upsert({
         where: { email: 'admin@singrkaraoke.com' },
         update: {},
         create: {
           email: 'admin@singrkaraoke.com',
           passwordHash: await hashPassword('Admin123!'),
           passwordAlgo: 'argon2id',
           name: 'Admin User',
           isEmailVerified: true,
           userRoles: {
             create: { roleId: adminRole.id },
           },
         },
       });

       logger.info(`Admin user created: ${adminUser.id}`);

       // Create test customer
       logger.info('Creating test customer...');
       const customerUser = await prisma.user.upsert({
         where: { email: 'customer@example.com' },
         update: {},
         create: {
           email: 'customer@example.com',
           passwordHash: await hashPassword('Customer123!'),
           passwordAlgo: 'argon2id',
           name: 'Test Customer',
           isEmailVerified: true,
           customerProfile: {
             create: {
               legalBusinessName: 'Test Karaoke LLC',
               contactEmail: 'customer@example.com',
               timezone: 'America/New_York',
             },
           },
           userRoles: {
             create: { roleId: customerOwnerRole.id },
           },
         },
         include: { customerProfile: true },
       });

       logger.info(`Customer user created: ${customerUser.id}`);
       logger.info(`Customer profile created: ${customerUser.customerProfile?.id}`);

       // Create test singer
       logger.info('Creating test singer...');
       const singerUser = await prisma.user.upsert({
         where: { email: 'singer@example.com' },
         update: {},
         create: {
           email: 'singer@example.com',
           passwordHash: await hashPassword('Singer123!'),
           passwordAlgo: 'argon2id',
           name: 'Test Singer',
           isEmailVerified: true,
           singerProfile: {
             create: {
               nickname: 'RockStar',
               preferences: {
                 language: 'en',
                 notificationsEnabled: true,
               },
             },
           },
           userRoles: {
             create: { roleId: singerRole.id },
           },
         },
         include: { singerProfile: true },
       });

       logger.info(`Singer user created: ${singerUser.id}`);
       logger.info(`Singer profile created: ${singerUser.singerProfile?.id}`);

       // Create test system for customer
       logger.info('Creating test system...');
       const system = await prisma.system.create({
         data: {
           customerProfileId: customerUser.customerProfile!.id,
           openkjSystemId: 1,
           name: 'Test Karaoke System',
           configuration: {
             region: 'us-east-1',
             venue_count: 1,
           },
         },
       });

       logger.info(`System created: ${system.id}`);

       // Create test venue for customer
       logger.info('Creating test venue...');
       const venue = await prisma.venue.create({
         data: {
           customerProfileId: customerUser.customerProfile!.id,
           openkjVenueId: 1001,
           urlName: 'test-karaoke-bar',
           name: 'Test Karaoke Bar',
           address: '123 Main Street',
           city: 'Nashville',
           state: 'TN',
           postalCode: '37201',
           country: 'USA',
           phoneNumber: '+1-615-555-1234',
           website: 'https://example.com',
           acceptingRequests: true,
         },
       });

       logger.info(`Venue created: ${venue.id}`);

       // Create test songs
       logger.info('Creating test songs...');
       const songs = await prisma.songDb.createMany({
         data: [
           {
             customerProfileId: customerUser.customerProfile!.id,
             openkjSystemId: 1,
             artist: 'Queen',
             title: 'Bohemian Rhapsody',
             combined: 'Queen - Bohemian Rhapsody',
             normalizedCombined: 'queen - bohemian rhapsody',
           },
           {
             customerProfileId: customerUser.customerProfile!.id,
             openkjSystemId: 1,
             artist: 'The Beatles',
             title: 'Hey Jude',
             combined: 'The Beatles - Hey Jude',
             normalizedCombined: 'the beatles - hey jude',
           },
           {
             customerProfileId: customerUser.customerProfile!.id,
             openkjSystemId: 1,
             artist: 'Elton John',
             title: 'Rocket Man',
             combined: 'Elton John - Rocket Man',
             normalizedCombined: 'elton john - rocket man',
           },
         ],
       });

       logger.info(`Created ${songs.count} test songs`);

       logger.info('✅ Database seeded successfully!');
       logger.info('Test credentials:');
       logger.info('  Admin: admin@singrkaraoke.com / Admin123!');
       logger.info('  Customer: customer@example.com / Customer123!');
       logger.info('  Singer: singer@example.com / Singer123!');
     } catch (error) {
       logger.error({ error }, 'Seed failed');
       throw error;
     }
   }

   seed()
     .catch((e) => {
       console.error(e);
       process.exit(1);
     })
     .finally(async () => {
       await prisma.$disconnect();
     });
   ```

2. **Add seed script to package.json:**
   ```json
   {
     "scripts": {
       "db:seed": "tsx prisma/seed.ts"
     }
   }
   ```

**Deliverables:**
- ✅ Seed script creates system roles and permissions
- ✅ Platform branding profile seeded
- ✅ Test users (admin, customer, singer) created with proper roles
- ✅ Test venue and system created
- ✅ Test songs populated
- ✅ `make db-seed` populates fresh database
- ✅ Clear credentials logged for testing

---

### 1.4 Database Audit Triggers

**Objective:** Ensure all table changes are captured in audit_logs.

**Duration:** 1 day  
**Team Size:** 1 developer

**Tasks:**

1. **Create migration `0002_audit_triggers.sql`:**
   ```sql
   -- Apply updated_at trigger to all tables
   DO $$
   DECLARE
     r RECORD;
   BEGIN
     FOR r IN SELECT tablename FROM pg_tables 
              WHERE schemaname = 'public' 
              AND tablename NOT IN ('audit_logs', '_prisma_migrations')
     LOOP
       EXECUTE format(
         'DROP TRIGGER IF EXISTS %I ON %I;',
         r.tablename || '_set_updated_at',
         r.tablename
       );
       EXECUTE format(
         'CREATE TRIGGER %I BEFORE UPDATE ON %I 
          FOR EACH ROW EXECUTE FUNCTION set_updated_at();',
         r.tablename || '_set_updated_at',
         r.tablename
       );
     END LOOP;
   END;
   $$;

   -- Apply audit trigger to all tables except audit_logs
   DO $$
   DECLARE
     r RECORD;
   BEGIN
     FOR r IN SELECT tablename FROM pg_tables 
              WHERE schemaname = 'public' 
              AND tablename NOT IN ('audit_logs', '_prisma_migrations')
     LOOP
       EXECUTE format(
         'DROP TRIGGER IF EXISTS %I ON %I;',
         r.tablename || '_audit',
         r.tablename
       );
       EXECUTE format(
         'CREATE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON %I 
          FOR EACH ROW EXECUTE FUNCTION record_audit();',
         r.tablename || '_audit',
         r.tablename
       );
     END LOOP;
   END;
   $$;

   -- Create indexes for audit log performance
   CREATE INDEX IF NOT EXISTS idx_audit_logs_table_record 
     ON audit_logs (table_name, record_id);

   CREATE INDEX IF NOT EXISTS idx_audit_logs_user_created_at 
     ON audit_logs (user_id, created_at DESC);

   CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at 
     ON audit_logs (created_at DESC);
   ```

2. **Test audit logging:**
   - Create integration tests that verify audit trails
   - Test INSERT, UPDATE, DELETE operations
   - Verify old_data and new_data captured correctly
   - Test user_id is populated when available

**Deliverables:**
- ✅ All tables have updated_at triggers
- ✅ All tables except audit_logs have audit triggers
- ✅ Audit logs capture old_data and new_data as JSONB
- ✅ Manual testing confirms audit trail works
- ✅ Performance indexes created on audit_logs

---

## Phase 2: Authentication & Authorization

### 2.1 Password Hashing & User Management

**Objective:** Secure password handling with Argon2id.

**Duration:** 2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create `packages/auth/src/password.ts`:**
   ```typescript
   import { hash, verify } from '@node-rs/argon2';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('auth:password');

   export const PASSWORD_CONFIG = {
     memoryCost: 19456, // 19 MB
     timeCost: 2,
     outputLen: 32,
     parallelism: 1,
     algorithm: 0, // Argon2id
   };

   export async function hashPassword(password: string): Promise<string> {
     try {
       return await hash(password, PASSWORD_CONFIG);
     } catch (error) {
       logger.error({ error }, 'Password hashing failed');
       throw new Error('Failed to hash password');
     }
   }

   export async function verifyPassword(
     hash: string,
     password: string
   ): Promise<boolean> {
     try {
       return await verify(hash, password, PASSWORD_CONFIG);
     } catch (error) {
       logger.debug({ error }, 'Password verification failed');
       return false;
     }
   }

   export function validatePasswordStrength(password: string): {
     valid: boolean;
     errors: string[];
   } {
     const errors: string[] = [];

     if (password.length < 8) {
       errors.push('Password must be at least 8 characters');
     }
     if (!/[A-Z]/.test(password)) {
       errors.push('Password must contain at least one uppercase letter');
     }
     if (!/[a-z]/.test(password)) {
       errors.push('Password must contain at least one lowercase letter');
     }
     if (!/[0-9]/.test(password)) {
       errors.push('Password must contain at least one number');
     }
     if (!/[^A-Za-z0-9]/.test(password)) {
       errors.push('Password must contain at least one special character');
     }

     return { valid: errors.length === 0, errors };
   }
   ```

2. **Create user service in `packages/auth/src/user-service.ts`:**
   ```typescript
   import { prisma } from '@singr/database';
   import { createLogger } from '@singr/observability';
   import { hashPassword, validatePasswordStrength } from './password';
   import { randomUUID } from 'crypto';

   const logger = createLogger('auth:user-service');

   export interface CreateUserInput {
     email: string;
     password: string;
     name?: string;
     accountType: 'customer' | 'singer';
     customerData?: {
       legalBusinessName?: string;
       contactEmail?: string;
       timezone?: string;
     };
     singerData?: {
       nickname?: string;
     };
   }

   export async function createUser(input: CreateUserInput) {
     // Validate password strength
     const passwordValidation = validatePasswordStrength(input.password);
     if (!passwordValidation.valid) {
       throw new Error(`Password validation failed: ${passwordValidation.errors.join(', ')}`);
     }

     // Check if user already exists
     const existingUser = await prisma.user.findUnique({
       where: { email: input.email.toLowerCase() },
     });

     if (existingUser) {
       throw new Error('User with this email already exists');
     }

     const passwordHash = await hashPassword(input.password);

     const user = await prisma.user.create({
       data: {
         email: input.email.toLowerCase(),
         passwordHash,
         passwordAlgo: 'argon2id',
         name: input.name,
         ...(input.accountType === 'customer' && {
           customerProfile: {
             create: {
               legalBusinessName: input.customerData?.legalBusinessName,
               contactEmail: input.customerData?.contactEmail || input.email,
               timezone: input.customerData?.timezone || 'UTC',
             },
           },
         }),
         ...(input.accountType === 'singer' && {
           singerProfile: {
             create: {
               nickname: input.singerData?.nickname,
             },
           },
         }),
       },
       include: {
         customerProfile: true,
         singerProfile: true,
       },
     });

     // Assign default role
     const roleSlug =
       input.accountType === 'customer' ? 'customer_owner' : 'singer';
     const role = await prisma.role.findUnique({ where: { slug: roleSlug } });

     if (role) {
       await prisma.userRole.create({
         data: { userId: user.id, roleId: role.id },
       });
     }

     // Create verification token
     const verificationToken = randomUUID();
     await prisma.verificationToken.create({
       data: {
         identifier: user.email,
         token: verificationToken,
         expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
       },
     });

     logger.info(
       {
         userId: user.id,
         email: user.email,
         accountType: input.accountType,
       },
       'User created'
     );

     return { user, verificationToken };
   }

   export async function getUserWithRoles(userId: string) {
     return prisma.user.findUnique({
       where: { id: userId },
       include: {
         userRoles: {
           include: {
             role: {
               include: {
                 rolePermissions: {
                   include: { permission: true },
                 },
               },
             },
           },
         },
         customerProfile: true,
         singerProfile: true,
         organizationUsers: {
           include: {
             role: {
               include: {
                 rolePermissions: {
                   include: { permission: true },
                 },
               },
             },
             permissions: {
               include: { permission: true },
             },
           },
         },
       },
     });
   }
   ```

**Deliverables:**
- ✅ Password hashing with Argon2id
- ✅ Password strength validation (8+ chars, uppercase, lowercase, number, special char)
- ✅ User creation with profile initialization
- ✅ Default role assignment
- ✅ Email verification token generation
- ✅ Secure user service with transaction support

---

### 2.2 JWT Implementation

**Objective:** Stateless JWT authentication with refresh tokens.

**Duration:** 2-3 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create `packages/auth/src/jwt.ts`:**
   ```typescript
   import { FastifyJWT } from '@fastify/jwt';
   import { config } from '@singr/config';
   import { prisma } from '@singr/database';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('auth:jwt');

   export interface JWTPayload {
     sub: string; // user ID
     email: string;
     roles: string[]; // global role slugs
     organizations: Array<{
       id: string; // customer_profile_id
       roles: string[];
       permissions: string[];
     }>;
     activeContext?: {
       type: 'customer' | 'singer';
       id: string; // profile ID
     };
     iat: number;
     exp: number;
     jti: string;
     iss: string;
     aud: string;
   }

   declare module '@fastify/jwt' {
     interface FastifyJWT {
       payload: JWTPayload;
       user: JWTPayload;
     }
   }

   export async function buildJWTPayload(userId: string): Promise<JWTPayload> {
     const user = await prisma.user.findUniqueOrThrow({
       where: { id: userId },
       include: {
         userRoles: {
           include: { role: true },
         },
         organizationUsers: {
           where: { status: 'active' },
           include: {
             role: true,
             permissions: {
               include: { permission: true },
             },
           },
         },
         customerProfile: true,
         singerProfile: true,
       },
     });

     const globalRoles = user.userRoles.map((ur) => ur.role.slug);

     const organizations = user.organizationUsers.map((ou) => ({
       id: ou.customerProfileId,
       roles: ou.role ? [ou.role.slug] : [],
       permissions: ou.permissions.map((p) => p.permission.slug),
     }));

     // Default context
     let activeContext: JWTPayload['activeContext'];
     if (user.customerProfile) {
       activeContext = { type: 'customer', id: user.customerProfile.id };
     } else if (user.singerProfile) {
       activeContext = { type: 'singer', id: user.singerProfile.id };
     }

     const now = Math.floor(Date.now() / 1000);

     return {
       sub: user.id,
       email: user.email,
       roles: globalRoles,
       organizations,
       activeContext,
       iat: now,
       exp: now + config.JWT_ACCESS_TTL,
       jti: require('crypto').randomUUID(),
       iss: config.JWT_ISSUER,
       aud: config.JWT_AUDIENCE,
     };
   }

   export function verifyJWTPayload(payload: JWTPayload): void {
     const now = Math.floor(Date.now() / 1000);

     if (payload.exp < now) {
       throw new Error('Token has expired');
     }

     if (payload.iss !== config.JWT_ISSUER) {
       throw new Error('Invalid issuer');
     }

     if (payload.aud !== config.JWT_AUDIENCE) {
       throw new Error('Invalid audience');
     }
   }
   ```

2. **Create refresh token service in `packages/auth/src/refresh-token-service.ts`:**
   ```typescript
   import { Redis } from 'ioredis';
   import { randomBytes } from 'crypto';
   import { config } from '@singr/config';
   import { createLogger } from '@singr/observability';
   import { hashPassword, verifyPassword } from './password';

   const logger = createLogger('auth:refresh-token');

   export class RefreshTokenService {
     constructor(private redis: Redis) {}

     async create(userId: string): Promise<string> {
       const token = randomBytes(32).toString('hex');
       const hashedToken = await hashPassword(token);

       await this.redis.setex(
         `refresh:${userId}`,
         config.JWT_REFRESH_TTL,
         hashedToken
       );

       logger.debug({ userId }, 'Refresh token created');

       return token;
     }

     async verify(userId: string, token: string): Promise<boolean> {
       const stored = await this.redis.get(`refresh:${userId}`);
       if (!stored) {
         logger.debug({ userId }, 'Refresh token not found');
         return false;
       }

       return verifyPassword(stored, token);
     }

     async revoke(userId: string): Promise<void> {
       await this.redis.del(`refresh:${userId}`);
       logger.debug({ userId }, 'Refresh token revoked');
     }

     async revokeJTI(jti: string): Promise<void> {
       await this.redis.setex(`revoked:${jti}`, config.JWT_ACCESS_TTL, '1');
       logger.debug({ jti }, 'JWT revoked');
     }

     async isJTIRevoked(jti: string): Promise<boolean> {
       const result = await this.redis.get(`revoked:${jti}`);
       return result === '1';
     }

     async refreshTokens(
       userId: string,
       oldRefreshToken: string,
       newRefreshTokenFunc: () => Promise<string>
     ): Promise<string> {
       // Verify old token
       const isValid = await this.verify(userId, oldRefreshToken);
       if (!isValid) {
         throw new Error('Invalid refresh token');
       }

       // Revoke old token
       await this.revoke(userId);

       // Create new token
       const newToken = await newRefreshTokenFunc();

       logger.info({ userId }, 'Tokens refreshed');

       return newToken;
     }
   }
   ```

3. **Export auth utilities in `packages/auth/src/index.ts`:**
   ```typescript
   export * from './password';
   export * from './user-service';
   export * from './jwt';
   export * from './refresh-token-service';
   export * from './rbac';
   export * from './context';
   ```

**Deliverables:**
- ✅ JWT signing with ES256
- ✅ JWT payload includes roles, organizations, context
- ✅ Refresh token generation and storage in Redis
- ✅ Token revocation support via Redis denylist
- ✅ JTI revocation for immediate logout
- ✅ Token rotation on refresh

---

### 2.3 RBAC & Permission System

**Objective:** Flexible role and permission evaluation.

**Duration:** 2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create `packages/auth/src/rbac.ts`:**
   ```typescript
   import { prisma } from '@singr/database';
   import { Redis } from 'ioredis';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('auth:rbac');

   export class RBACService {
     constructor(private redis: Redis) {}

     async getUserPermissions(
       userId: string,
       customerProfileId?: string
     ): Promise<Set<string>> {
       const cacheKey = customerProfileId
         ? `permissions:${userId}:${customerProfileId}`
         : `permissions:${userId}`;

       // Check cache
       const cached = await this.redis.get(cacheKey);
       if (cached) {
         return new Set(JSON.parse(cached));
       }

       // Fetch from DB
       const permissions = new Set<string>();

       // Global permissions from roles
       const userRoles = await prisma.userRole.findMany({
         where: { userId },
         include: {
           role: {
             include: {
               rolePermissions: {
                 include: { permission: true },
               },
             },
           },
         },
       });

       userRoles.forEach((ur) => {
         ur.role.rolePermissions.forEach((rp) => {
           permissions.add(rp.permission.slug);
         });
       });

       // Organization-specific permissions
       if (customerProfileId) {
         const orgUser = await prisma.organizationUser.findUnique({
           where: {
             customerProfileId_userId: {
               customerProfileId,
               userId,
             },
           },
           include: {
             role: {
               include: {
                 rolePermissions: {
                   include: { permission: true },
                 },
               },
             },
             permissions: {
               include: { permission: true },
             },
           },
         });

         if (orgUser && orgUser.status === 'active') {
           // Add role permissions
           orgUser.role?.rolePermissions.forEach((rp) => {
             permissions.add(rp.permission.slug);
           });

           // Add override permissions
           orgUser.permissions.forEach((p) => {
             permissions.add(p.permission.slug);
           });
         }
       }

       // Cache for 30 minutes
       await this.redis.setex(
         cacheKey,
         1800,
         JSON.stringify([...permissions])
       );

       logger.debug(
         {
           userId,
           customerProfileId,
           permissionCount: permissions.size,
         },
         'Permissions loaded'
       );

       return permissions;
     }

     async hasPermission(
       userId: string,
       permission: string,
       customerProfileId?: string
     ): Promise<boolean> {
       const permissions = await this.getUserPermissions(
         userId,
         customerProfileId
       );
       return permissions.has(permission);
     }

     async hasAnyPermission(
       userId: string,
       requiredPermissions: string[],
       customerProfileId?: string
     ): Promise<boolean> {
       const permissions = await this.getUserPermissions(
         userId,
         customerProfileId
       );
       return requiredPermissions.some((p) => permissions.has(p));
     }

     async hasAllPermissions(
       userId: string,
       requiredPermissions: string[],
       customerProfileId?: string
     ): Promise<boolean> {
       const permissions = await this.getUserPermissions(
         userId,
         customerProfileId
       );
       return requiredPermissions.every((p) => permissions.has(p));
     }

     async hasRole(userId: string, role: string): Promise<boolean> {
       const userRoles = await prisma.userRole.findMany({
         where: { userId },
         include: { role: true },
       });

       return userRoles.some((ur) => ur.role.slug === role);
     }

     async invalidateCache(userId: string, customerProfileId?: string): Promise<void> {
       if (customerProfileId) {
         await this.redis.del(`permissions:${userId}:${customerProfileId}`);
       } else {
         // Invalidate all caches for user
         const keys = await this.redis.keys(`permissions:${userId}:*`);
         if (keys.length > 0) {
           await this.redis.del(...keys);
         }
       }

       logger.debug(
         { userId, customerProfileId },
         'Permission cache invalidated'
       );
     }
   }
   ```

2. **Create authorization decorators in `packages/auth/src/decorators.ts`:**
   ```typescript
   import { FastifyRequest, FastifyReply } from 'fastify';
   import { RBACService } from './rbac';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('auth:decorators');

   export function requirePermission(permission: string | string[]) {
     const permissions = Array.isArray(permission) ? permission : [permission];

     return async (request: FastifyRequest, reply: FastifyReply) => {
       const { user } = request;

       if (!user) {
         return reply.code(401).send({
           type: 'authentication_failed',
           title: 'Unauthorized',
           detail: 'Authentication required',
         });
       }

       const customerProfileId =
         user.activeContext?.type === 'customer' ? user.activeContext.id : undefined;

       const rbac = new RBACService(request.server.redis);
       const hasPermission = await rbac.hasAnyPermission(
         user.sub,
         permissions,
         customerProfileId
       );

       if (!hasPermission) {
         logger.warn(
           {
             userId: user.sub,
             requiredPermissions: permissions,
           },
           'Permission denied'
         );

         return reply.code(403).send({
           type: 'authorization_denied',
           title: 'Forbidden',
           detail: `Missing required permission: ${permissions.join(' or ')}`,
         });
       }
     };
   }

   export function requireRole(role: string | string[]) {
     const roles = Array.isArray(role) ? role : [role];

     return async (request: FastifyRequest, reply: FastifyReply) => {
       const { user } = request;

       if (!user) {
         return reply.code(401).send({
           type: 'authentication_failed',
           title: 'Unauthorized',
           detail: 'Authentication required',
         });
       }

       const hasRole = roles.some((r) => user.roles.includes(r));

       if (!hasRole) {
         logger.warn(
           {
             userId: user.sub,
             requiredRoles: roles,
             userRoles: user.roles,
           },
           'Role denied'
         );

         return reply.code(403).send({
           type: 'authorization_denied',
           title: 'Forbidden',
           detail: `Missing required role: ${roles.join(' or ')}`,
         });
       }
     };
   }

   export function requireCustomerContext(
     _request: FastifyRequest,
     reply: FastifyReply
   ) {
     const { user } = _request;

     if (!user?.activeContext || user.activeContext.type !== 'customer') {
       return reply.code(403).send({
         type: 'authorization_denied',
         title: 'Customer Context Required',
         detail: 'You must be in a customer context to access this resource',
       });
     }
   }

   export function requireSingerContext(
     _request: FastifyRequest,
     reply: FastifyReply
   ) {
     const { user } = _request;

     if (!user?.activeContext || user.activeContext.type !== 'singer') {
       return reply.code(403).send({
         type: 'authorization_denied',
         title: 'Singer Context Required',
         detail: 'You must be in a singer context to access this resource',
       });
     }
   }
   ```

**Deliverables:**
- ✅ Permission aggregation from global and org-specific roles
- ✅ Redis caching of permission sets (30 min TTL)
- ✅ Cache invalidation on role/permission changes
- ✅ Fastify decorators for route protection
- ✅ Support for `hasPermission`, `hasAnyPermission`, `hasAllPermissions`
- ✅ Context-specific authorization (customer, singer)

---

### 2.4 Context Switching

**Objective:** Allow users to switch between customer and singer contexts.

**Duration:** 1 day  
**Team Size:** 1 developer

**Tasks:**

1. **Create `packages/auth/src/context.ts`:**
   ```typescript
   import { prisma } from '@singr/database';
   import { buildJWTPayload, JWTPayload } from './jwt';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('auth:context');

   export async function switchContext(
     userId: string,
     contextType: 'customer' | 'singer',
     contextId: string
   ): Promise<JWTPayload> {
     // Verify user has access to this context
     if (contextType === 'customer') {
       const profile = await prisma.customerProfile.findFirst({
         where: {
           id: contextId,
           OR: [
             { userId },
             {
               organizationUsers: {
                 some: {
                   userId,
                   status: 'active',
                 },
               },
             },
           ],
         },
       });

       if (!profile) {
         logger.warn(
           { userId, contextId, contextType },
           'Access denied to customer profile'
         );
         throw new Error('Access denied to customer profile');
       }
     } else if (contextType === 'singer') {
       const profile = await prisma.singerProfile.findFirst({
         where: { id: contextId, userId },
       });

       if (!profile) {
         logger.warn(
           { userId, contextId, contextType },
           'Access denied to singer profile'
         );
         throw new Error('Access denied to singer profile');
       }
     }

     // Build new payload with updated context
     const payload = await buildJWTPayload(userId);
     payload.activeContext = { type: contextType, id: contextId };

     logger.info(
       { userId, contextType, contextId },
       'Context switched'
     );

     return payload;
   }

   export async function validateContext(
     userId: string,
     contextType: 'customer' | 'singer',
     contextId: string
   ): Promise<boolean> {
     try {
       await switchContext(userId, contextType, contextId);
       return true;
     } catch {
       return false;
     }
   }
   ```

**Deliverables:**
- ✅ Context switching validates user access
- ✅ New JWT issued with updated activeContext
- ✅ Refresh token remains valid across context switches
- ✅ Support for organization user context access

---

## Phase 3: API Server Foundation

### 3.1 Fastify Server Setup

**Objective:** Bootstrap Fastify with core plugins and middleware.

**Duration:** 2-3 days  
**Team Size:** 1-2 developers

**Tasks:**

1. **Create `apps/api/src/server.ts`:**
   ```typescript
   import Fastify, { FastifyInstance } from 'fastify';
   import cors from '@fastify/cors';
   import helmet from '@fastify/helmet';
   import jwt from '@fastify/jwt';
   import rateLimit from '@fastify/rate-limit';
   import { config } from '@singr/config';
   import { logger, initSentry, Sentry } from '@singr/observability';
   import { prisma } from '@singr/database';
   import { RefreshTokenService } from '@singr/auth';
   import Redis from 'ioredis';

   // Extend Fastify instance with custom properties
   declare module 'fastify' {
     interface FastifyInstance {
       prisma: typeof prisma;
       redis: Redis;
       authenticate: (request: FastifyRequest, reply: FastifyReply) => Promise<void>;
     }
   }

   export async function buildServer(): Promise<FastifyInstance> {
     const server = Fastify({
       logger,
       requestIdLogLabel: 'correlationId',
       disableRequestLogging: false,
       trustProxy: true,
       ajv: {
         customOptions: {
           removeAdditional: 'all',
           coerceTypes: true,
           useDefaults: true,
         },
       },
     });

     // Initialize Sentry
     initSentry();

     // Global error handler
     server.setErrorHandler((error, request, reply) => {
       // Log error with Sentry
       Sentry.captureException(error, {
         user: request.user
           ? { id: request.user.sub, email: request.user.email }
           : undefined,
         extra: {
           correlationId: request.id,
           url: request.url,
           method: request.method,
           params: request.params,
           query: request.query,
         },
       });

       // Don't leak internal errors to clients
       if (error.statusCode && error.statusCode < 500) {
         return reply.send(error);
       }

       request.log.error({ error }, 'Internal server error');
       return reply.code(500).send({
         type: 'internal_error',
         title: 'Internal Server Error',
         detail: 'An unexpected error occurred',
         correlationId: request.id,
       });
     });

     // Not found handler
     server.setNotFoundHandler((request, reply) => {
       return reply.code(404).send({
         type: 'resource_not_found',
         title: 'Not Found',
         detail: `Route ${request.method} ${request.url} not found`,
       });
     });

     // Register helmet for security headers
     await server.register(helmet, {
       contentSecurityPolicy: false, // Disable CSP for API
       crossOriginEmbedderPolicy: false,
     });

     // Register CORS
     await server.register(cors, {
       origin: config.CORS_ORIGINS.split(','),
       credentials: true,
       methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
       allowedHeaders: [
         'Content-Type',
         'Authorization',
         'X-Requested-With',
         'X-API-Key',
       ],
       exposedHeaders: [
         'X-RateLimit-Limit',
         'X-RateLimit-Remaining',
         'X-RateLimit-Reset',
         'X-Request-Id',
       ],
     });

     // Register JWT
     await server.register(jwt, {
       secret: {
         private: config.JWT_PRIVATE_KEY,
         public: config.JWT_PUBLIC_KEY,
       },
       sign: {
         algorithm: 'ES256',
         issuer: config.JWT_ISSUER,
         audience: config.JWT_AUDIENCE,
       },
       verify: {
         algorithms: ['ES256'],
         issuer: config.JWT_ISSUER,
         audience: config.JWT_AUDIENCE,
       },
     });

     // Register rate limiting
     const redis = new Redis(config.REDIS_URL);
     await server.register(rateLimit, {
       global: true,
       max: 100,
       timeWindow: '1 minute',
       redis,
       skipOnError: true,
       keyGenerator: (request) => {
         // Use user ID if authenticated, otherwise IP
         return request.user?.sub || request.ip;
       },
       errorResponseBuilder: (request, context) => {
         return {
           type: 'rate_limited',
           title: 'Too Many Requests',
           detail: `Rate limit exceeded. Retry after ${Math.ceil(context.ttl / 1000)} seconds`,
           retryAfter: Math.ceil(context.ttl / 1000),
         };
       },
     });

     // Decorate with dependencies
     server.decorate('prisma', prisma);
     server.decorate('redis', redis);

     // Auth decorator
     server.decorate('authenticate', async (request, reply) => {
       try {
         await request.jwtVerify();

         // Check if token is revoked
         const refreshTokenService = new RefreshTokenService(server.redis);
         const isRevoked = await refreshTokenService.isJTIRevoked(
           request.user.jti
         );

         if (isRevoked) {
           return reply.code(401).send({
             type: 'authentication_failed',
             title: 'Unauthorized',
             detail: 'Token has been revoked',
           });
         }

         // Set user in Sentry context
         Sentry.setUser({
           id: request.user.sub,
           email: request.user.email,
         });
       } catch (err) {
         return reply.code(401).send({
           type: 'authentication_failed',
           title: 'Unauthorized',
           detail: 'Invalid or expired token',
         });
       }
     });

     // Health check endpoints
     server.get('/healthz', async () => {
       return { status: 'ok', timestamp: new Date().toISOString() };
     });

     server.get('/readyz', async () => {
       try {
         // Check database
         await prisma.$queryRaw`SELECT 1`;

         // Check Redis
         await server.redis.ping();

         return {
           status: 'ok',
           timestamp: new Date().toISOString(),
           checks: {
             database: 'ok',
             redis: 'ok',
           },
         };
       } catch (err) {
         throw server.httpErrors.serviceUnavailable(
           'Service dependencies unavailable'
         );
       }
     });

     // Graceful shutdown
     const closeGracefully = async (signal: string) => {
       logger.info(`Received ${signal}, closing gracefully`);
       await server.close();
       await prisma.$disconnect();
       await redis.quit();
       process.exit(0);
     };

     process.on('SIGINT', () => closeGracefully('SIGINT'));
     process.on('SIGTERM', () => closeGracefully('SIGTERM'));

     return server;
   }
   ```

2. **Create `apps/api/src/index.ts`:**
   ```typescript
   import { buildServer } from './server';
   import { config } from '@singr/config';
   import { logger } from '@singr/observability';

   async function start() {
     try {
       const server = await buildServer();

       // Register routes (will be added in subsequent phases)
       // await server.register(routes);

       await server.listen({
         port: config.PORT,
         host: '0.0.0.0',
       });

       logger.info(
         {
           port: config.PORT,
           environment: config.NODE_ENV,
         },
         'Server listening'
       );
     } catch (err) {
       logger.error({ error: err }, 'Failed to start server');
       process.exit(1);
     }
   }

   start();
   ```

3. **Create development script in `apps/api/package.json`:**
   ```json
   {
     "name": "@singr/api",
     "version": "1.0.0",
     "scripts": {
       "dev": "tsx watch src/index.ts",
       "build": "tsc",
       "start": "node dist/index.js",
       "test": "vitest"
     },
     "dependencies": {
       "fastify": "^4.x",
       "@fastify/cors": "^9.x",
       "@fastify/helmet": "^11.x",
       "@fastify/jwt": "^7.x",
       "@fastify/rate-limit": "^9.x",
       "@fastify/swagger": "^8.x",
       "@fastify/swagger-ui": "^3.x",
       "@singr/database": "workspace:*",
       "@singr/auth": "workspace:*",
       "@singr/config": "workspace:*",
       "@singr/shared": "workspace:*",
       "@singr/observability": "workspace:*",
       "ioredis": "^5.x"
     }
   }
   ```

**Deliverables:**
- ✅ Fastify server with core plugins configured
- ✅ JWT authentication decorator
- ✅ Global rate limiting (100 req/min default)
- ✅ CORS configured for allowed origins
- ✅ Helmet security headers
- ✅ Sentry error tracking integrated
- ✅ Health check endpoints (`/healthz`, `/readyz`)
- ✅ Graceful shutdown handling
- ✅ Correlation ID tracking

---

### 3.2 Request Validation with Zod

**Objective:** Type-safe request validation schemas.

**Duration:** 1-2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create shared validation utilities in `packages/shared/src/validation/index.ts`:**
   ```typescript
   import { z } from 'zod';
   import { FastifyRequest, FastifyReply } from 'fastify';

   export function validateBody<T extends z.ZodTypeAny>(schema: T) {
     return async (request: FastifyRequest, reply: FastifyReply) => {
       const result = schema.safeParse(request.body);

       if (!result.success) {
         return reply.code(400).send({
           type: 'validation_error',
           title: 'Validation Failed',
           detail: 'Request body validation failed',
           errors: result.error.errors.map((e) => ({
             path: e.path.join('.'),
             message: e.message,
             code: e.code,
           })),
         });
       }

       request.body = result.data;
     };
   }

   export function validateQuery<T extends z.ZodTypeAny>(schema: T) {
     return async (request: FastifyRequest, reply: FastifyReply) => {
       const result = schema.safeParse(request.query);

       if (!result.success) {
         return reply.code(400).send({
           type: 'validation_error',
           title: 'Validation Failed',
           detail: 'Query parameter validation failed',
           errors: result.error.errors.map((e) => ({
             path: e.path.join('.'),
             message: e.message,
             code: e.code,
           })),
         });
       }

       request.query = result.data;
     };
   }

   export function validateParams<T extends z.ZodTypeAny>(schema: T) {
     return async (request: FastifyRequest, reply: FastifyReply) => {
       const result = schema.safeParse(request.params);

       if (!result.success) {
         return reply.code(400).send({
           type: 'validation_error',
           title: 'Validation Failed',
           detail: 'Path parameter validation failed',
           errors: result.error.errors.map((e) => ({
             path: e.path.join('.'),
             message: e.message,
             code: e.code,
           })),
         });
       }

       request.params = result.data;
     };
   }
   ```

2. **Create common schemas in `packages/shared/src/validation/schemas.ts`:**
   ```typescript
   import { z } from 'zod';

   // ========== Common Schemas ==========

   export const UUIDSchema = z.string().uuid({
     message: 'Must be a valid UUID',
   });

   export const EmailSchema = z
     .string()
     .email({ message: 'Must be a valid email address' })
     .toLowerCase()
     .trim();

   export const PasswordSchema = z
     .string()
     .min(8, 'Password must be at least 8 characters')
     .regex(/[A-Z]/, 'Must contain at least one uppercase letter')
     .regex(/[a-z]/, 'Must contain at least one lowercase letter')
     .regex(/[0-9]/, 'Must contain at least one number')
     .regex(/[^A-Za-z0-9]/, 'Must contain at least one special character');

   export const PaginationSchema = z.object({
     page: z.coerce.number().int().min(1).default(1),
     limit: z.coerce.number().int().min(1).max(100).default(20),
   });

   export const DateRangeSchema = z.object({
     startDate: z.string().datetime().optional(),
     endDate: z.string().datetime().optional(),
   });

   export const SortOrderSchema = z.enum(['asc', 'desc']).default('asc');

   // ========== Geographic Schemas ==========

   export const LatitudeSchema = z
     .number()
     .min(-90, 'Latitude must be between -90 and 90')
     .max(90, 'Latitude must be between -90 and 90');

   export const LongitudeSchema = z
     .number()
     .min(-180, 'Longitude must be between -180 and 180')
     .max(180, 'Longitude must be between -180 and 180');

   export const LocationSchema = z.object({
     lat: LatitudeSchema,
     lng: LongitudeSchema,
   });

   export const AddressSchema = z.object({
     address: z.string().min(1).max(255),
     city: z.string().min(1).max(100),
     state: z.string().min(2).max(50),
     postalCode: z.string().min(1).max(20),
     country: z.string().max(50).default('USA'),
   });

   // ========== Contact Schemas ==========

   export const PhoneNumberSchema = z
     .string()
     .regex(
       /^\+?[1-9]\d{1,14}$/,
       'Must be a valid phone number in E.164 format'
     )
     .optional();

   export const WebsiteSchema = z
     .string()
     .url({ message: 'Must be a valid URL' })
     .optional();

   // ========== Song Schemas ==========

   export const KeyChangeSchema = z
     .number()
     .int()
     .min(-12, 'Key change must be between -12 and 12')
     .max(12, 'Key change must be between -12 and 12')
     .default(0);

   export const SongSchema = z.object({
     artist: z.string().min(1).max(255),
     title: z.string().min(1).max(255),
     keyChange: KeyChangeSchema,
   });

   // ========== Response Pagination Schema ==========

   export const PaginatedResponseSchema = <T extends z.ZodTypeAny>(
     dataSchema: T
   ) => {
     return z.object({
       data: z.array(dataSchema),
       pagination: z.object({
         page: z.number().int().positive(),
         limit: z.number().int().positive(),
         total: z.number().int().nonnegative(),
         totalPages: z.number().int().nonnegative(),
       }),
     });
   };
   ```

3. **Create validation error types in `packages/shared/src/types/errors.ts`:**
   ```typescript
   export interface ProblemDetails {
     type: string;
     title: string;
     detail: string;
     status?: number;
     instance?: string;
     [key: string]: any;
   }

   export interface ValidationError extends ProblemDetails {
     type: 'validation_error';
     errors: Array<{
       path: string;
       message: string;
       code: string;
     }>;
   }

   export interface AuthenticationError extends ProblemDetails {
     type: 'authentication_failed';
   }

   export interface AuthorizationError extends ProblemDetails {
     type: 'authorization_denied';
   }

   export interface ResourceNotFoundError extends ProblemDetails {
     type: 'resource_not_found';
   }

   export interface ConflictError extends ProblemDetails {
     type: 'conflict';
   }

   export interface RateLimitError extends ProblemDetails {
     type: 'rate_limited';
     retryAfter: number;
   }
   ```

**Deliverables:**
- ✅ Zod validation middleware for body/query/params
- ✅ Problem+JSON error responses for validation failures
- ✅ Common reusable schemas (UUID, Email, Password, Pagination, etc.)
- ✅ Type inference from schemas
- ✅ Geographic and contact validation schemas
- ✅ Consistent error structure across API

---

### 3.3 Route Organization

**Objective:** Modular route structure by domain.

**Duration:** 1 day  
**Team Size:** 1 developer

**Tasks:**

1. **Create route plugin structure:**
   ```
   apps/api/src/routes/
   ├── index.ts              # Register all route plugins
   ├── auth/
   │   ├── index.ts          # Auth route plugin
   │   ├── signin.ts
   │   ├── register.ts
   │   ├── refresh.ts
   │   ├── signout.ts
   │   ├── password.ts
   │   ├── profile.ts
   │   ├── context.ts
   │   └── schemas.ts
   ├── customer/
   │   ├── index.ts
   │   ├── venues.ts
   │   ├── systems.ts
   │   ├── songdb.ts
   │   ├── api-keys.ts
   │   ├── requests.ts
   │   ├── organization.ts
   │   └── schemas.ts
   ├── singer/
   │   ├── index.ts
   │   ├── profile.ts
   │   ├── requests.ts
   │   ├── history.ts
   │   ├── favorites.ts
   │   ├── dashboard.ts
   │   ├── account.ts
   │   └── schemas.ts
   ├── admin/
   │   ├── index.ts
   │   ├── users.ts
   │   ├── roles.ts
   │   ├── organizations.ts
   │   ├── audit.ts
   │   └── schemas.ts
   └── public/
       ├── index.ts
       ├── venues.ts
       ├── songs.ts
       ├── requests.ts
       ├── branding.ts
       └── schemas.ts
   ```

2. **Create route index in `apps/api/src/routes/index.ts`:**
   ```typescript
   import { FastifyInstance, FastifyPluginAsync } from 'fastify';
   import { authRoutes } from './auth';
   import { customerRoutes } from './customer';
   import { singerRoutes } from './singer';
   import { adminRoutes } from './admin';
   import { publicRoutes } from './public';

   export const routes: FastifyPluginAsync = async (server: FastifyInstance) => {
     // Public routes (no authentication required)
     await server.register(publicRoutes, { prefix: '/v1/public' });

     // Authentication routes
     await server.register(authRoutes, { prefix: '/v1/auth' });

     // Customer portal routes
     await server.register(customerRoutes, { prefix: '/v1/customer' });

     // Singer app routes
     await server.register(singerRoutes, { prefix: '/v1/singer' });

     // Admin routes
     await server.register(adminRoutes, { prefix: '/v1/admin' });
   };
   ```

3. **Create example route plugin structure for auth:**
   ```typescript
   // apps/api/src/routes/auth/index.ts
   import { FastifyPluginAsync } from 'fastify';
   import { signinRoute } from './signin';
   import { registerRoute } from './register';
   import { refreshRoute } from './refresh';
   import { signoutRoute } from './signout';
   import { passwordRoute } from './password';
   import { profileRoute } from './profile';
   import { contextRoute } from './context';

   export const authRoutes: FastifyPluginAsync = async (server) => {
     await server.register(signinRoute);
     await server.register(registerRoute);
     await server.register(refreshRoute);
     await server.register(signoutRoute);
     await server.register(passwordRoute);
     await server.register(profileRoute);
     await server.register(contextRoute);
   };
   ```

4. **Create placeholder route files:**
   ```typescript
   // apps/api/src/routes/customer/index.ts
   import { FastifyPluginAsync } from 'fastify';
   // Import individual route files as they're created

   export const customerRoutes: FastifyPluginAsync = async (server) => {
     // Routes will be registered here
     // await server.register(venuesRoute);
     // await server.register(systemsRoute);
     // etc.
   };

   // apps/api/src/routes/singer/index.ts
   import { FastifyPluginAsync } from 'fastify';

   export const singerRoutes: FastifyPluginAsync = async (server) => {
     // Routes will be registered here
   };

   // apps/api/src/routes/admin/index.ts
   import { FastifyPluginAsync } from 'fastify';

   export const adminRoutes: FastifyPluginAsync = async (server) => {
     // Routes will be registered here
   };

   // apps/api/src/routes/public/index.ts
   import { FastifyPluginAsync } from 'fastify';

   export const publicRoutes: FastifyPluginAsync = async (server) => {
     // Routes will be registered here
   };
   ```

5. **Register routes in server:**
   ```typescript
   // Update apps/api/src/server.ts to include routes
   import { routes } from './routes';

   export async function buildServer(): Promise<FastifyInstance> {
     const server = Fastify({
       // ... existing config
     });

     // ... existing middleware setup

     // Register all routes
     await server.register(routes);

     return server;
   }
   ```

**Deliverables:**
- ✅ Modular route plugins by domain
- ✅ Versioned API paths (`/v1/...`)
- ✅ Clear separation of concerns (auth, customer, singer, admin, public)
- ✅ Easy to add new routes
- ✅ Route structure documented
- ✅ Placeholder files ready for implementation

---

### 3.4 Swagger/OpenAPI Documentation

**Objective:** Auto-generate API documentation.

**Duration:** 1-2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Install and configure Swagger in `apps/api/src/server.ts`:**
   ```typescript
   import swagger from '@fastify/swagger';
   import swaggerUi from '@fastify/swagger-ui';

   export async function buildServer(): Promise<FastifyInstance> {
     const server = Fastify({
       // ... existing config
     });

     // ... existing plugins

     // Register Swagger
     await server.register(swagger, {
       openapi: {
         info: {
           title: 'Singr API',
           description: 'Central API for the Singr karaoke platform',
           version: '1.0.0',
           contact: {
             name: 'Singr Support',
             email: 'support@singrkaraoke.com',
           },
         },
         servers: [
           {
             url: 'http://localhost:3000',
             description: 'Development server',
           },
           {
             url: 'https://api.singrkaraoke.com',
             description: 'Production server',
           },
         ],
         components: {
           securitySchemes: {
             bearerAuth: {
               type: 'http',
               scheme: 'bearer',
               bearerFormat: 'JWT',
               description: 'JWT token obtained from /v1/auth/signin',
             },
             apiKey: {
               type: 'apiKey',
               name: 'X-API-Key',
               in: 'header',
               description: 'API key for OpenKJ integration',
             },
           },
         },
         tags: [
           {
             name: 'auth',
             description: 'Authentication and authorization endpoints',
           },
           {
             name: 'public',
             description: 'Public endpoints (no authentication required)',
           },
           {
             name: 'singer',
             description: 'Singer-specific endpoints',
           },
           {
             name: 'customer',
             description: 'Customer portal endpoints',
           },
           {
             name: 'admin',
             description: 'Administrative endpoints',
           },
         ],
       },
     });

     await server.register(swaggerUi, {
       routePrefix: '/docs',
       uiConfig: {
         docExpansion: 'list',
         deepLinking: true,
         displayRequestDuration: true,
       },
       staticCSP: true,
       transformStaticCSP: (header) => header,
     });

     // ... rest of server setup

     return server;
   }
   ```

2. **Add schema example for future routes:**
   ```typescript
   // Example of how to document a route
   server.get(
     '/example',
     {
       schema: {
         tags: ['example'],
         summary: 'Example endpoint',
         description: 'Detailed description of what this endpoint does',
         security: [{ bearerAuth: [] }],
         querystring: {
           type: 'object',
           properties: {
             page: {
               type: 'integer',
               minimum: 1,
               default: 1,
               description: 'Page number for pagination',
             },
             limit: {
               type: 'integer',
               minimum: 1,
               maximum: 100,
               default: 20,
               description: 'Number of items per page',
             },
           },
         },
         response: {
           200: {
             description: 'Successful response',
             type: 'object',
             properties: {
               data: {
                 type: 'array',
                 items: {
                   type: 'object',
                   properties: {
                     id: { type: 'string', format: 'uuid' },
                     name: { type: 'string' },
                   },
                 },
               },
               pagination: {
                 type: 'object',
                 properties: {
                   page: { type: 'integer' },
                   limit: { type: 'integer' },
                   total: { type: 'integer' },
                   totalPages: { type: 'integer' },
                 },
               },
             },
           },
           401: {
             description: 'Unauthorized',
             type: 'object',
             properties: {
               type: { type: 'string' },
               title: { type: 'string' },
               detail: { type: 'string' },
             },
           },
         },
       },
     },
     async (request, reply) => {
       // Handler implementation
     }
   );
   ```

3. **Add script to export OpenAPI spec:**
   ```typescript
   // scripts/export-openapi.ts
   import { buildServer } from '../apps/api/src/server';
   import { writeFileSync } from 'fs';
   import { join } from 'path';

   async function exportOpenAPI() {
     const server = await buildServer();
     await server.ready();

     const spec = server.swagger();

     writeFileSync(
       join(__dirname, '../docs/openapi.json'),
       JSON.stringify(spec, null, 2)
     );
     
     console.log('OpenAPI spec exported to docs/openapi.json');

     await server.close();
   }

   exportOpenAPI();
   ```

**Deliverables:**
- ✅ Swagger UI available at `/docs`
- ✅ OpenAPI 3.0 specification auto-generated
- ✅ Security schemes documented (Bearer JWT, API Key)
- ✅ Tags for route organization
- ✅ Script to export OpenAPI JSON
- ✅ Documentation template for future routes

---

## Phase 4: Authentication Endpoints

### 4.1 User Registration

**Objective:** Implement `/v1/auth/register` endpoints for customer and singer registration with email verification.

**Duration:** 2-3 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create registration schemas in `apps/api/src/routes/auth/schemas.ts`:**
   ```typescript
   import { z } from 'zod';
   import { EmailSchema, PasswordSchema } from '@singr/shared/validation';

   export const RegisterSchema = z.object({
     email: EmailSchema,
     password: PasswordSchema,
     name: z.string().min(1).max(255).optional(),
     accountType: z.enum(['customer', 'singer']),
     customerData: z
       .object({
         legalBusinessName: z.string().min(1).max(255).optional(),
         contactEmail: EmailSchema.optional(),
         timezone: z.string().optional(),
       })
       .optional(),
     singerData: z
       .object({
         nickname: z.string().min(1).max(100).optional(),
       })
       .optional(),
   });

   export const SingerRegisterSchema = z.object({
     email: EmailSchema,
     password: PasswordSchema,
     nickname: z.string().min(1).max(100),
   });

   export const RegisterResponseSchema = z.object({
     id: z.string().uuid(),
     email: z.string().email(),
     name: z.string().nullable(),
     accountType: z.enum(['customer', 'singer']),
     message: z.string(),
   });
   ```

2. **Update user service to enqueue emails in `packages/auth/src/user-service.ts`:**
   ```typescript
   import { prisma } from '@singr/database';
   import { createLogger } from '@singr/observability';
   import { hashPassword, validatePasswordStrength } from './password';
   import { randomUUID } from 'crypto';
   import { Queue } from 'bullmq';
   import type { CommunicationJob } from '@singr/shared/types/jobs';

   const logger = createLogger('auth:user-service');

   export interface CreateUserInput {
     email: string;
     password: string;
     name?: string;
     accountType: 'customer' | 'singer';
     customerData?: {
       legalBusinessName?: string;
       contactEmail?: string;
       timezone?: string;
     };
     singerData?: {
       nickname?: string;
     };
     communicationQueue?: Queue<CommunicationJob>;
   }

   export async function createUser(input: CreateUserInput) {
     // Validate password strength
     const passwordValidation = validatePasswordStrength(input.password);
     if (!passwordValidation.valid) {
       throw new Error(`Password validation failed: ${passwordValidation.errors.join(', ')}`);
     }

     // Check if user already exists
     const existingUser = await prisma.user.findUnique({
       where: { email: input.email.toLowerCase() },
     });

     if (existingUser) {
       throw new Error('User with this email already exists');
     }

     const passwordHash = await hashPassword(input.password);

     const user = await prisma.user.create({
       data: {
         email: input.email.toLowerCase(),
         passwordHash,
         passwordAlgo: 'argon2id',
         name: input.name,
         ...(input.accountType === 'customer' && {
           customerProfile: {
             create: {
               legalBusinessName: input.customerData?.legalBusinessName,
               contactEmail: input.customerData?.contactEmail || input.email,
               timezone: input.customerData?.timezone || 'UTC',
             },
           },
         }),
         ...(input.accountType === 'singer' && {
           singerProfile: {
             create: {
               nickname: input.singerData?.nickname,
             },
           },
         }),
       },
       include: {
         customerProfile: true,
         singerProfile: true,
       },
     });

     // Assign default role
     const roleSlug =
       input.accountType === 'customer' ? 'customer_owner' : 'singer';
     const role = await prisma.role.findUnique({ where: { slug: roleSlug } });

     if (role) {
       await prisma.userRole.create({
         data: { userId: user.id, roleId: role.id },
       });
     }

     // Create verification token
     const verificationToken = randomUUID();
     await prisma.verificationToken.create({
       data: {
         identifier: user.email,
         token: verificationToken,
         expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
       },
     });

     // Enqueue verification email
     if (input.communicationQueue) {
       await input.communicationQueue.add('email', {
         type: 'email',
         to: user.email,
         toName: user.name || undefined,
         subject: 'Verify your Singr account',
         templateId: parseInt(process.env.MAILJET_TEMPLATE_VERIFICATION || '0'),
         variables: {
           user_name: user.name || user.email.split('@')[0],
           verification_link: `${process.env.APP_URL_WEB}/verify-email?token=${verificationToken}`,
           verification_code: verificationToken.substring(0, 6).toUpperCase(),
           expiry_hours: 24,
         },
       });

       logger.info(
         {
           userId: user.id,
           email: user.email,
         },
         'Verification email enqueued'
       );
     }

     logger.info(
       {
         userId: user.id,
         email: user.email,
         accountType: input.accountType,
       },
       'User created'
     );

     return { user, verificationToken };
   }

   export async function getUserWithRoles(userId: string) {
     return prisma.user.findUnique({
       where: { id: userId },
       include: {
         userRoles: {
           include: {
             role: {
               include: {
                 rolePermissions: {
                   include: { permission: true },
                 },
               },
             },
           },
         },
         customerProfile: true,
         singerProfile: true,
         organizationUsers: {
           include: {
             role: {
               include: {
                 rolePermissions: {
                   include: { permission: true },
                 },
               },
             },
             permissions: {
               include: { permission: true },
             },
           },
         },
       },
     });
   }
   ```

3. **Implement registration route in `apps/api/src/routes/auth/register.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateBody } from '@singr/shared/validation';
   import { RegisterSchema, SingerRegisterSchema } from './schemas';
   import { createUser } from '@singr/auth';
   import { createLogger } from '@singr/observability';
   import { createCommunicationQueue } from '@singr/shared/queues/communication-queue';

   const logger = createLogger('routes:auth:register');

   export const registerRoute: FastifyPluginAsync = async (server) => {
     const communicationQueue = createCommunicationQueue(server.redis);

     // General registration endpoint
     server.post(
       '/register',
       {
         schema: {
           tags: ['auth'],
           summary: 'Register new user',
           description: 'Create a new customer or singer account with email verification',
           body: {
             type: 'object',
             required: ['email', 'password', 'accountType'],
             properties: {
               email: { type: 'string', format: 'email' },
               password: { type: 'string', minLength: 8 },
               name: { type: 'string' },
               accountType: { type: 'string', enum: ['customer', 'singer'] },
               customerData: {
                 type: 'object',
                 properties: {
                   legalBusinessName: { type: 'string' },
                   contactEmail: { type: 'string', format: 'email' },
                   timezone: { type: 'string' },
                 },
               },
               singerData: {
                 type: 'object',
                 properties: {
                   nickname: { type: 'string' },
                 },
               },
             },
           },
           response: {
             201: {
               description: 'User created successfully',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 email: { type: 'string' },
                 accountType: { type: 'string' },
                 message: { type: 'string' },
               },
             },
             409: {
               description: 'User already exists',
               type: 'object',
               properties: {
                 type: { type: 'string' },
                 title: { type: 'string' },
                 detail: { type: 'string' },
               },
             },
           },
         },
         preHandler: [validateBody(RegisterSchema)],
         config: {
           rateLimit: {
             max: 3,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const body = request.body as z.infer<typeof RegisterSchema>;

         try {
           const { user } = await createUser({
             email: body.email,
             password: body.password,
             name: body.name,
             accountType: body.accountType,
             customerData: body.customerData,
             singerData: body.singerData,
             communicationQueue,
           });

           logger.info(
             {
               userId: user.id,
               email: user.email,
               accountType: body.accountType,
             },
             'User registered'
           );

           return reply.code(201).send({
             id: user.id,
             email: user.email,
             name: user.name,
             accountType: body.accountType,
             message:
               'Registration successful. Please check your email to verify your account.',
           });
         } catch (error) {
           if (error instanceof Error) {
             if (error.message.includes('already exists')) {
               return reply.code(409).send({
                 type: 'conflict',
                 title: 'User Already Exists',
                 detail: 'A user with this email already exists',
               });
             }

             if (error.message.includes('Password validation failed')) {
               return reply.code(400).send({
                 type: 'validation_error',
                 title: 'Invalid Password',
                 detail: error.message,
               });
             }
           }

           throw error;
         }
       }
     );

     // Lightweight singer registration
     server.post(
       '/register/singer',
       {
         schema: {
           tags: ['auth'],
           summary: 'Quick singer registration',
           description: 'Streamlined registration for singer users with email verification',
           body: {
             type: 'object',
             required: ['email', 'password', 'nickname'],
             properties: {
               email: { type: 'string', format: 'email' },
               password: { type: 'string', minLength: 8 },
               nickname: { type: 'string', minLength: 1, maxLength: 100 },
             },
           },
           response: {
             201: {
               description: 'Singer created successfully',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 email: { type: 'string' },
                 nickname: { type: 'string' },
                 message: { type: 'string' },
               },
             },
           },
         },
         preHandler: [validateBody(SingerRegisterSchema)],
         config: {
           rateLimit: {
             max: 5,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const { email, password, nickname } = request.body as z.infer<
           typeof SingerRegisterSchema
         >;

         try {
           const { user } = await createUser({
             email,
             password,
             accountType: 'singer',
             singerData: { nickname },
             communicationQueue,
           });

           logger.info({ userId: user.id, email }, 'Singer registered');

           return reply.code(201).send({
             id: user.id,
             email: user.email,
             nickname,
             message:
               'Registration successful. Please check your email to verify your account.',
           });
         } catch (error) {
           if (error instanceof Error && error.message.includes('already exists')) {
             return reply.code(409).send({
               type: 'conflict',
               title: 'User Already Exists',
               detail: 'A user with this email already exists',
             });
           }

           throw error;
         }
       }
     );
   };
   ```

**Deliverables:**
- ✅ `POST /v1/auth/register` - General registration endpoint
- ✅ `POST /v1/auth/register/singer` - Streamlined singer registration
- ✅ Rate limiting (3-5 req/hour per IP)
- ✅ Duplicate email detection
- ✅ Profile creation based on account type
- ✅ Verification token generation
- ✅ Email verification queued via BullMQ
- ✅ Mailjet template integration
- ✅ 24-hour verification token expiry
- ✅ OpenAPI documentation
- ✅ Comprehensive error handling

---

### 4.2 Sign In & Token Issuance

**Objective:** Implement credential-based authentication with JWT.

**Duration:** 2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create sign-in schemas:**
   ```typescript
   // Add to apps/api/src/routes/auth/schemas.ts
   export const SignInSchema = z.object({
     email: EmailSchema,
     password: z.string().min(1, 'Password is required'),
   });

   export const SignInResponseSchema = z.object({
     accessToken: z.string(),
     refreshToken: z.string(),
     expiresIn: z.number(),
     tokenType: z.literal('Bearer'),
     user: z.object({
       id: z.string().uuid(),
       email: z.string().email(),
       name: z.string().nullable(),
       roles: z.array(z.string()),
     }),
   });
   ```

2. **Implement sign-in route in `apps/api/src/routes/auth/signin.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateBody } from '@singr/shared/validation';
   import { SignInSchema } from './schemas';
   import { verifyPassword, buildJWTPayload, RefreshTokenService } from '@singr/auth';
   import { config } from '@singr/config';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:auth:signin');

   export const signinRoute: FastifyPluginAsync = async (server) => {
     server.post(
       '/signin',
       {
         schema: {
           tags: ['auth'],
           summary: 'Sign in',
           description: 'Authenticate with email and password to receive JWT tokens',
           body: {
             type: 'object',
             required: ['email', 'password'],
             properties: {
               email: { type: 'string', format: 'email' },
               password: { type: 'string' },
             },
           },
           response: {
             200: {
               description: 'Authentication successful',
               type: 'object',
               properties: {
                 accessToken: { type: 'string' },
                 refreshToken: { type: 'string' },
                 expiresIn: { type: 'number' },
                 tokenType: { type: 'string' },
                 user: {
                   type: 'object',
                   properties: {
                     id: { type: 'string', format: 'uuid' },
                     email: { type: 'string' },
                     name: { type: 'string' },
                     roles: { type: 'array', items: { type: 'string' } },
                   },
                 },
               },
             },
             401: {
               description: 'Invalid credentials',
               type: 'object',
               properties: {
                 type: { type: 'string' },
                 title: { type: 'string' },
                 detail: { type: 'string' },
               },
             },
           },
         },
         preHandler: [validateBody(SignInSchema)],
         config: {
           rateLimit: {
             max: 5,
             timeWindow: '1 minute',
           },
         },
       },
       async (request, reply) => {
         const { email, password } = request.body as z.infer<typeof SignInSchema>;

         // Find user
         const user = await server.prisma.user.findUnique({
           where: { email: email.toLowerCase() },
           include: {
             userRoles: {
               include: { role: true },
             },
           },
         });

         if (!user || !user.passwordHash) {
           logger.warn({ email }, 'Sign in attempt with invalid email');
           return reply.code(401).send({
             type: 'authentication_failed',
             title: 'Invalid Credentials',
             detail: 'Email or password is incorrect',
           });
         }

         // Verify password
         const validPassword = await verifyPassword(user.passwordHash, password);
         if (!validPassword) {
           logger.warn({ email, userId: user.id }, 'Sign in attempt with invalid password');
           return reply.code(401).send({
             type: 'authentication_failed',
             title: 'Invalid Credentials',
             detail: 'Email or password is incorrect',
           });
         }

         // Check email verification
         if (!user.isEmailVerified) {
           logger.warn({ email, userId: user.id }, 'Sign in attempt with unverified email');
           return reply.code(403).send({
             type: 'email_not_verified',
             title: 'Email Not Verified',
             detail: 'Please verify your email before signing in',
           });
         }

         // Build JWT payload
         const payload = await buildJWTPayload(user.id);
         const accessToken = server.jwt.sign(payload);

         // Create refresh token
         const refreshTokenService = new RefreshTokenService(server.redis);
         const refreshToken = await refreshTokenService.create(user.id);

         // Update last login
         await server.prisma.user.update({
           where: { id: user.id },
           data: { lastLoginAt: new Date() },
         });

         logger.info({ userId: user.id, email: user.email }, 'User signed in');

         return reply.send({
           accessToken,
           refreshToken,
           expiresIn: config.JWT_ACCESS_TTL,
           tokenType: 'Bearer',
           user: {
             id: user.id,
             email: user.email,
             name: user.name,
             roles: user.userRoles.map((ur) => ur.role.slug),
           },
         });
       }
     );
   };
   ```

**Deliverables:**
- ✅ `POST /v1/auth/signin` - Credential authentication
- ✅ Password verification with Argon2
- ✅ Email verification check
- ✅ JWT access token issuance
- ✅ Refresh token generation
- ✅ Rate limiting (5 req/min per IP)
- ✅ Last login timestamp update
- ✅ Comprehensive logging

---

### 4.3 Token Refresh & Revocation

**Objective:** Implement token lifecycle management.

**Duration:** 1-2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create refresh schemas:**
   ```typescript
   // Add to apps/api/src/routes/auth/schemas.ts
   export const RefreshTokenSchema = z.object({
     refreshToken: z.string().min(1, 'Refresh token is required'),
   });
   ```

2. **Implement token refresh in `apps/api/src/routes/auth/refresh.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateBody } from '@singr/shared/validation';
   import { RefreshTokenSchema } from './schemas';
   import { buildJWTPayload, RefreshTokenService } from '@singr/auth';
   import { config } from '@singr/config';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:auth:refresh');

   export const refreshRoute: FastifyPluginAsync = async (server) => {
     server.post(
       '/refresh',
       {
         schema: {
           tags: ['auth'],
           summary: 'Refresh access token',
           description: 'Exchange refresh token for new access and refresh tokens',
           body: {
             type: 'object',
             required: ['refreshToken'],
             properties: {
               refreshToken: { type: 'string' },
             },
           },
           response: {
             200: {
               description: 'Tokens refreshed successfully',
               type: 'object',
               properties: {
                 accessToken: { type: 'string' },
                 refreshToken: { type: 'string' },
                 expiresIn: { type: 'number' },
                 tokenType: { type: 'string' },
               },
             },
             401: {
               description: 'Invalid or expired refresh token',
             },
           },
         },
         preHandler: [validateBody(RefreshTokenSchema)],
         config: {
           rateLimit: {
             max: 10,
             timeWindow: '1 minute',
           },
         },
       },
       async (request, reply) => {
         const { refreshToken } = request.body as z.infer<typeof RefreshTokenSchema>;

         // Extract user ID from Authorization header (may be expired)
         let userId: string;
         try {
           const authHeader = request.headers.authorization;
           if (!authHeader?.startsWith('Bearer ')) {
             throw new Error('Missing authorization header');
           }

           const token = authHeader.substring(7);
           const decoded = server.jwt.decode(token) as any;
           userId = decoded.sub;
         } catch (error) {
           logger.warn('Failed to extract user ID from token');
           return reply.code(401).send({
             type: 'authentication_failed',
             title: 'Invalid Token',
             detail: 'Cannot refresh token',
           });
         }

         // Verify refresh token
         const refreshTokenService = new RefreshTokenService(server.redis);
         const valid = await refreshTokenService.verify(userId, refreshToken);

         if (!valid) {
           logger.warn({ userId }, 'Invalid refresh token attempt');
           return reply.code(401).send({
             type: 'authentication_failed',
             title: 'Invalid Refresh Token',
             detail: 'Refresh token is invalid or expired',
           });
         }

         // Issue new tokens
         const payload = await buildJWTPayload(userId);
         const accessToken = server.jwt.sign(payload);
         const newRefreshToken = await refreshTokenService.create(userId);

         logger.info({ userId }, 'Tokens refreshed');

         return reply.send({
           accessToken,
           refreshToken: newRefreshToken,
           expiresIn: config.JWT_ACCESS_TTL,
           tokenType: 'Bearer',
         });
       }
     );
   };
   ```

3. **Implement sign out in `apps/api/src/routes/auth/signout.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { RefreshTokenService } from '@singr/auth';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:auth:signout');

   export const signoutRoute: FastifyPluginAsync = async (server) => {
     server.post(
       '/signout',
       {
         schema: {
           tags: ['auth'],
           summary: 'Sign out',
           description: 'Revoke refresh token and blacklist current JWT',
           security: [{ bearerAuth: [] }],
           response: {
             200: {
               description: 'Signed out successfully',
               type: 'object',
               properties: {
                 message: { type: 'string' },
               },
             },
           },
         },
         preHandler: [server.authenticate],
         config: {
           rateLimit: {
             max: 30,
             timeWindow: '1 minute',
           },
         },
       },
       async (request, reply) => {
         const refreshTokenService = new RefreshTokenService(server.redis);

         // Revoke refresh token
         await refreshTokenService.revoke(request.user.sub);

         // Revoke current JWT
         await refreshTokenService.revokeJTI(request.user.jti);

         logger.info({ userId: request.user.sub }, 'User signed out');

         return reply.send({ message: 'Signed out successfully' });
       }
     );
   };
   ```

**Deliverables:**
- ✅ `POST /v1/auth/refresh` - Token refresh endpoint
- ✅ `POST /v1/auth/signout` - Sign out with token revocation
- ✅ Refresh token rotation
- ✅ JTI revocation for immediate logout
- ✅ Rate limiting on refresh (10/min)

---

### 4.4 Password Reset Flow

**Objective:** Secure password reset via email verification with Mailjet integration.

**Duration:** 2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create password reset schemas:**
   ```typescript
   // Add to apps/api/src/routes/auth/schemas.ts
   export const ForgotPasswordSchema = z.object({
     email: EmailSchema,
   });

   export const ResetPasswordSchema = z.object({
     token: z.string().uuid('Invalid token format'),
     newPassword: PasswordSchema,
   });

   export const VerifyEmailSchema = z.object({
     token: z.string().uuid('Invalid token format'),
   });
   ```

2. **Implement password reset routes in `apps/api/src/routes/auth/password.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateBody } from '@singr/shared/validation';
   import {
     ForgotPasswordSchema,
     ResetPasswordSchema,
     VerifyEmailSchema,
   } from './schemas';
   import { hashPassword, RefreshTokenService } from '@singr/auth';
   import { randomUUID } from 'crypto';
   import { createLogger } from '@singr/observability';
   import { createCommunicationQueue } from '@singr/shared/queues/communication-queue';
   import { config, TOKEN_EXPIRY } from '@singr/config';

   const logger = createLogger('routes:auth:password');

   export const passwordRoute: FastifyPluginAsync = async (server) => {
     const communicationQueue = createCommunicationQueue(server.redis);

     // Request password reset
     server.post(
       '/password/forgot',
       {
         schema: {
           tags: ['auth'],
           summary: 'Request password reset',
           description: 'Send password reset email with verification token',
           body: {
             type: 'object',
             required: ['email'],
             properties: {
               email: { type: 'string', format: 'email' },
             },
           },
           response: {
             200: {
               description: 'Reset email sent (or user not found)',
               type: 'object',
               properties: {
                 message: { type: 'string' },
               },
             },
           },
         },
         preHandler: [validateBody(ForgotPasswordSchema)],
         config: {
           rateLimit: {
             max: 5,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const { email } = request.body as z.infer<typeof ForgotPasswordSchema>;

         const user = await server.prisma.user.findUnique({
           where: { email: email.toLowerCase() },
         });

         // Don't reveal if user exists
         if (!user) {
           logger.debug({ email }, 'Password reset requested for non-existent user');
           return reply.send({
             message: 'If an account exists, a reset link has been sent',
           });
         }

         // Delete any existing reset tokens
         await server.prisma.verificationToken.deleteMany({
           where: { identifier: user.email },
         });

         // Create reset token
         const resetToken = randomUUID();
         await server.prisma.verificationToken.create({
           data: {
             identifier: user.email,
             token: resetToken,
             expiresAt: new Date(Date.now() + TOKEN_EXPIRY.PASSWORD_RESET),
           },
         });

         // Enqueue password reset email
         await communicationQueue.add('email', {
           type: 'email',
           to: user.email,
           toName: user.name || undefined,
           subject: 'Reset your Singr password',
           templateId: config.MAILJET_TEMPLATE_PASSWORD_RESET,
           variables: {
             user_name: user.name || user.email.split('@')[0],
             reset_link: `${config.APP_URL_WEB}/reset-password?token=${resetToken}`,
             expiry_minutes: Math.floor(TOKEN_EXPIRY.PASSWORD_RESET / (1000 * 60)),
           },
         });

         logger.info({ userId: user.id, email: user.email }, 'Password reset requested');

         return reply.send({
           message: 'If an account exists, a reset link has been sent',
         });
       }
     );

     // Reset password with token
     server.post(
       '/password/reset',
       {
         schema: {
           tags: ['auth'],
           summary: 'Reset password',
           description: 'Reset password using verification token',
           body: {
             type: 'object',
             required: ['token', 'newPassword'],
             properties: {
               token: { type: 'string', format: 'uuid' },
               newPassword: { type: 'string', minLength: 8 },
             },
           },
           response: {
             200: {
               description: 'Password reset successful',
               type: 'object',
               properties: {
                 message: { type: 'string' },
               },
             },
             400: {
               description: 'Invalid or expired token',
             },
           },
         },
         preHandler: [validateBody(ResetPasswordSchema)],
         config: {
           rateLimit: {
             max: 5,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const { token, newPassword } = request.body as z.infer<
           typeof ResetPasswordSchema
         >;

         // Find valid token
         const verificationToken = await server.prisma.verificationToken.findFirst({
           where: {
             token,
             expiresAt: { gt: new Date() },
           },
         });

         if (!verificationToken) {
           logger.warn({ token }, 'Invalid or expired password reset token');
           return reply.code(400).send({
             type: 'invalid_token',
             title: 'Invalid or Expired Token',
             detail: 'Password reset token is invalid or has expired',
           });
         }

         // Find user
         const user = await server.prisma.user.findUnique({
           where: { email: verificationToken.identifier },
         });

         if (!user) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'User Not Found',
             detail: 'No user found with this email',
           });
         }

         // Update password
         const newPasswordHash = await hashPassword(newPassword);
         await server.prisma.user.update({
           where: { id: user.id },
           data: {
             passwordHash: newPasswordHash,
             passwordAlgo: 'argon2id',
           },
         });

         // Delete token
         await server.prisma.verificationToken.delete({
           where: {
             identifier_token: {
               identifier: verificationToken.identifier,
               token: verificationToken.token,
             },
           },
         });

         // Revoke all sessions
         const refreshTokenService = new RefreshTokenService(server.redis);
         await refreshTokenService.revoke(user.id);

         // Send confirmation email
         await communicationQueue.add('email', {
           type: 'email',
           to: user.email,
           toName: user.name || undefined,
           subject: 'Your Singr password has been reset',
           htmlPart: `
             <h2>Password Reset Successful</h2>
             <p>Hello ${user.name || 'there'},</p>
             <p>Your password has been successfully reset.</p>
             <p>If you did not perform this action, please contact support immediately.</p>
             <p><a href="${config.APP_URL_WEB}/signin">Sign in to your account</a></p>
           `,
           textPart: `Your password has been successfully reset. If you did not perform this action, please contact support immediately.`,
         });

         logger.info({ userId: user.id }, 'Password reset completed');

         return reply.send({
           message:
             'Password reset successful. Please sign in with your new password.',
         });
       }
     );

     // Verify email
     server.post(
       '/verify-email',
       {
         schema: {
           tags: ['auth'],
           summary: 'Verify email address',
           description: 'Verify email using verification token',
           body: {
             type: 'object',
             required: ['token'],
             properties: {
               token: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'Email verified successfully',
               type: 'object',
               properties: {
                 message: { type: 'string' },
               },
             },
           },
         },
         preHandler: [validateBody(VerifyEmailSchema)],
       },
       async (request, reply) => {
         const { token } = request.body as z.infer<typeof VerifyEmailSchema>;

         // Find valid token
         const verificationToken = await server.prisma.verificationToken.findFirst({
           where: {
             token,
             expiresAt: { gt: new Date() },
           },
         });

         if (!verificationToken) {
           return reply.code(400).send({
             type: 'invalid_token',
             title: 'Invalid or Expired Token',
             detail: 'Email verification token is invalid or has expired',
           });
         }

         // Update user
         const user = await server.prisma.user.update({
           where: { email: verificationToken.identifier },
           data: { isEmailVerified: true },
         });

         // Delete token
         await server.prisma.verificationToken.delete({
           where: {
             identifier_token: {
               identifier: verificationToken.identifier,
               token: verificationToken.token,
             },
           },
         });

         // Send welcome email
         const accountType = user.customerProfile ? 'customer' : 'singer';
         await communicationQueue.add('email', {
           type: 'email',
           to: user.email,
           toName: user.name || undefined,
           subject: 'Welcome to Singr!',
           templateId: config.MAILJET_TEMPLATE_WELCOME,
           variables: {
             user_name: user.name || user.email.split('@')[0],
             account_type: accountType,
             dashboard_link:
               accountType === 'customer'
                 ? config.APP_URL_CUSTOMER
                 : config.APP_URL_WEB,
           },
         });

         logger.info({ userId: user.id, email: user.email }, 'Email verified');

         return reply.send({
           message: 'Email verified successfully',
         });
       }
     );

     // Resend verification email
     server.post(
       '/verify-email/resend',
       {
         schema: {
           tags: ['auth'],
           summary: 'Resend verification email',
           description: 'Request a new email verification token',
           body: {
             type: 'object',
             required: ['email'],
             properties: {
               email: { type: 'string', format: 'email' },
             },
           },
           response: {
             200: {
               description: 'Verification email sent',
               type: 'object',
               properties: {
                 message: { type: 'string' },
               },
             },
           },
         },
         preHandler: [validateBody(ForgotPasswordSchema)],
         config: {
           rateLimit: {
             max: 3,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const { email } = request.body as z.infer<typeof ForgotPasswordSchema>;

         const user = await server.prisma.user.findUnique({
           where: { email: email.toLowerCase() },
         });

         // Don't reveal if user exists
         if (!user) {
           return reply.send({
             message: 'If an account exists, a verification email has been sent',
           });
         }

         if (user.isEmailVerified) {
           return reply.send({
             message: 'Email is already verified',
           });
         }

         // Delete old tokens
         await server.prisma.verificationToken.deleteMany({
           where: { identifier: email },
         });

         // Create new token
         const verificationToken = randomUUID();
         await server.prisma.verificationToken.create({
           data: {
             identifier: email.toLowerCase(),
             token: verificationToken,
             expiresAt: new Date(Date.now() + TOKEN_EXPIRY.EMAIL_VERIFICATION),
           },
         });

         // Enqueue verification email
         await communicationQueue.add('email', {
           type: 'email',
           to: user.email,
           toName: user.name || undefined,
           subject: 'Verify your Singr account',
           templateId: config.MAILJET_TEMPLATE_VERIFICATION,
           variables: {
             user_name: user.name || user.email.split('@')[0],
             verification_link: `${config.APP_URL_WEB}/verify-email?token=${verificationToken}`,
             verification_code: verificationToken.substring(0, 6).toUpperCase(),
             expiry_hours: Math.floor(TOKEN_EXPIRY.EMAIL_VERIFICATION / (1000 * 60 * 60)),
           },
         });

         logger.info({ userId: user.id }, 'Verification email resent');

         return reply.send({
           message: 'If an account exists, a verification email has been sent',
         });
       }
     );
   };
   ```

**Deliverables:**
- ✅ `POST /v1/auth/password/forgot` - Request password reset
- ✅ `POST /v1/auth/password/reset` - Complete password reset
- ✅ `POST /v1/auth/verify-email` - Verify email address
- ✅ `POST /v1/auth/verify-email/resend` - Resend verification
- ✅ Secure token handling with expiration
- ✅ Session revocation on password reset
- ✅ Rate limiting on all endpoints
- ✅ Email notifications via Mailjet
- ✅ Welcome email sent after verification
- ✅ Confirmation email after password reset
- ✅ BullMQ queue integration
- ✅ Token cleanup after use
- ✅ Privacy-preserving responses (don't reveal user existence)

---

### 4.5 User Profile & Context Management

**Objective:** Endpoints for retrieving user profile and switching contexts.

**Duration:** 1-2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create profile and context schemas:**
   ```typescript
   // Add to apps/api/src/routes/auth/schemas.ts
   export const SwitchContextSchema = z.object({
     contextType: z.enum(['customer', 'singer']),
     contextId: z.string().uuid(),
   });

   export const UserProfileSchema = z.object({
     id: z.string().uuid(),
     email: z.string().email(),
     name: z.string().nullable(),
     displayName: z.string().nullable(),
     phoneNumber: z.string().nullable(),
     imageUrl: z.string().url().nullable(),
     isEmailVerified: z.boolean(),
     roles: z.array(z.string()),
     activeContext: z
       .object({
         type: z.enum(['customer', 'singer']),
         id: z.string().uuid(),
       })
       .nullable(),
     customerProfile: z
       .object({
         id: z.string().uuid(),
         legalBusinessName: z.string().nullable(),
         dbaName: z.string().nullable(),
       })
       .nullable(),
     singerProfile: z
       .object({
         id: z.string().uuid(),
         nickname: z.string().nullable(),
         avatarUrl: z.string().url().nullable(),
       })
       .nullable(),
     organizations: z.array(
       z.object({
         id: z.string().uuid(),
         name: z.string(),
         role: z.string(),
         status: z.string(),
       })
     ),
   });
   ```

2. **Implement profile route in `apps/api/src/routes/auth/profile.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:auth:profile');

   export const profileRoute: FastifyPluginAsync = async (server) => {
     server.get(
       '/profile',
       {
         schema: {
           tags: ['auth'],
           summary: 'Get user profile',
           description: 'Retrieve current user profile with roles and contexts',
           security: [{ bearerAuth: [] }],
           response: {
             200: {
               description: 'User profile',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 email: { type: 'string' },
                 name: { type: 'string' },
                 roles: { type: 'array', items: { type: 'string' } },
                 activeContext: {
                   type: 'object',
                   properties: {
                     type: { type: 'string' },
                     id: { type: 'string' },
                   },
                 },
               },
             },
           },
         },
         preHandler: [server.authenticate],
         config: {
           rateLimit: {
             max: 30,
             timeWindow: '1 minute',
           },
         },
       },
       async (request, reply) => {
         const userId = request.user.sub;

         const user = await server.prisma.user.findUnique({
           where: { id: userId },
           include: {
             customerProfile: true,
             singerProfile: true,
             userRoles: {
               include: { role: true },
             },
             organizationUsers: {
               where: { status: 'active' },
               include: {
                 customerProfile: true,
                 role: true,
               },
             },
           },
         });

         if (!user) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'User Not Found',
             detail: 'User profile not found',
           });
         }

         return reply.send({
           id: user.id,
           email: user.email,
           name: user.name,
           displayName: user.displayName,
           phoneNumber: user.phoneNumber,
           imageUrl: user.imageUrl,
           isEmailVerified: user.isEmailVerified,
           roles: user.userRoles.map((ur) => ur.role.slug),
           activeContext: request.user.activeContext || null,
           customerProfile: user.customerProfile
             ? {
                 id: user.customerProfile.id,
                 legalBusinessName: user.customerProfile.legalBusinessName,
                 dbaName: user.customerProfile.dbaName,
               }
             : null,
           singerProfile: user.singerProfile
             ? {
                 id: user.singerProfile.id,
                 nickname: user.singerProfile.nickname,
                 avatarUrl: user.singerProfile.avatarUrl,
               }
             : null,
           organizations: user.organizationUsers.map((ou) => ({
             id: ou.customerProfile.id,
             name:
               ou.customerProfile.dbaName ||
               ou.customerProfile.legalBusinessName ||
               'Organization',
             role: ou.role?.slug || 'member',
             status: ou.status,
           })),
         });
       }
     );
   };
   ```

3. **Implement context switching in `apps/api/src/routes/auth/context.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateBody } from '@singr/shared/validation';
   import { SwitchContextSchema } from './schemas';
   import { switchContext } from '@singr/auth';
   import { config } from '@singr/config';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:auth:context');

   export const contextRoute: FastifyPluginAsync = async (server) => {
     server.post(
       '/context',
       {
         schema: {
           tags: ['auth'],
           summary: 'Switch context',
           description:
             'Switch between customer and singer contexts, returns new JWT',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['contextType', 'contextId'],
             properties: {
               contextType: { type: 'string', enum: ['customer', 'singer'] },
               contextId: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'Context switched successfully',
               type: 'object',
               properties: {
                 accessToken: { type: 'string' },
                 expiresIn: { type: 'number' },
                 tokenType: { type: 'string' },
               },
             },
             403: {
               description: 'Access denied to requested context',
             },
           },
         },
         preHandler: [server.authenticate, validateBody(SwitchContextSchema)],
         config: {
           rateLimit: {
             max: 10,
             timeWindow: '1 minute',
           },
         },
       },
       async (request, reply) => {
         const { contextType, contextId } = request.body as z.infer<
           typeof SwitchContextSchema
         >;

         try {
           const payload = await switchContext(
             request.user.sub,
             contextType,
             contextId
           );

           const accessToken = server.jwt.sign(payload);

           logger.info(
             {
               userId: request.user.sub,
               contextType,
               contextId,
             },
             'Context switched'
           );

           return reply.send({
             accessToken,
             expiresIn: config.JWT_ACCESS_TTL,
             tokenType: 'Bearer',
           });
         } catch (error) {
           if (error instanceof Error) {
             logger.warn(
               {
                 userId: request.user.sub,
                 contextType,
                 contextId,
                 error: error.message,
               },
               'Context switch denied'
             );

             return reply.code(403).send({
               type: 'authorization_denied',
               title: 'Access Denied',
               detail: error.message,
             });
           }

           throw error;
         }
       }
     );
   };
   ```

**Deliverables:**
- ✅ `GET /v1/auth/profile` - Get current user profile
- ✅ `POST /v1/auth/context` - Switch context (customer/singer)
- ✅ Profile includes roles, organizations, and both profile types
- ✅ Context switching validates access
- ✅ New JWT issued with updated context
- ✅ Refresh token remains valid

---

## Phase 4.6: Magic Link & 2FA Authentication

**Objective:** Implement passwordless magic link authentication and two-factor authentication (TOTP and SMS).

**Duration:** 4-5 days  
**Team Size:** 1-2 developers

### 4.6.1 Database Schema for 2FA

**Tasks:**

1. **Create migration for 2FA tables (`packages/database/prisma/migrations/0003_two_factor.sql`):**
   ```sql
   -- Two-factor authentication settings
   CREATE TABLE two_factor_settings (
     two_factor_settings_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     users_id UUID NOT NULL REFERENCES users(users_id) ON DELETE CASCADE,
     totp_enabled BOOLEAN DEFAULT FALSE,
     totp_secret TEXT,
     totp_verified_at TIMESTAMPTZ(6),
     sms_enabled BOOLEAN DEFAULT FALSE,
     sms_phone_number TEXT,
     sms_verified_at TIMESTAMPTZ(6),
     backup_codes_generated_at TIMESTAMPTZ(6),
     created_at TIMESTAMPTZ(6) DEFAULT NOW(),
     updated_at TIMESTAMPTZ(6) DEFAULT NOW(),
     UNIQUE(users_id)
   );

   -- Backup codes for 2FA recovery
   CREATE TABLE two_factor_backup_codes (
     two_factor_backup_codes_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     two_factor_settings_id UUID NOT NULL REFERENCES two_factor_settings(two_factor_settings_id) ON DELETE CASCADE,
     code_hash TEXT NOT NULL,
     used_at TIMESTAMPTZ(6),
     created_at TIMESTAMPTZ(6) DEFAULT NOW()
   );

   -- Magic link tokens
   CREATE TABLE magic_link_tokens (
     magic_link_tokens_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     users_id UUID REFERENCES users(users_id) ON DELETE CASCADE,
     email TEXT NOT NULL,
     token TEXT NOT NULL UNIQUE,
     ip_address TEXT,
     user_agent TEXT,
     expires_at TIMESTAMPTZ(6) NOT NULL,
     used_at TIMESTAMPTZ(6),
     created_at TIMESTAMPTZ(6) DEFAULT NOW()
   );

   -- Indexes
   CREATE INDEX idx_two_factor_settings_user ON two_factor_settings(users_id);
   CREATE INDEX idx_two_factor_backup_codes_settings ON two_factor_backup_codes(two_factor_settings_id);
   CREATE INDEX idx_magic_link_tokens_token ON magic_link_tokens(token);
   CREATE INDEX idx_magic_link_tokens_email ON magic_link_tokens(email);
   CREATE INDEX idx_magic_link_tokens_expires ON magic_link_tokens(expires_at);

   -- Triggers
   CREATE TRIGGER two_factor_settings_set_updated_at BEFORE UPDATE ON two_factor_settings 
     FOR EACH ROW EXECUTE FUNCTION set_updated_at();
   ```

2. **Update Prisma schema (`packages/database/prisma/schema.prisma`):**
   ```prisma
   model TwoFactorSettings {
     id                    String    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("two_factor_settings_id")
     userId                String    @unique @map("users_id") @db.Uuid
     totpEnabled           Boolean   @default(false) @map("totp_enabled")
     totpSecret            String?   @map("totp_secret")
     totpVerifiedAt        DateTime? @map("totp_verified_at") @db.Timestamptz(6)
     smsEnabled            Boolean   @default(false) @map("sms_enabled")
     smsPhoneNumber        String?   @map("sms_phone_number")
     smsVerifiedAt         DateTime? @map("sms_verified_at") @db.Timestamptz(6)
     backupCodesGeneratedAt DateTime? @map("backup_codes_generated_at") @db.Timestamptz(6)
     createdAt             DateTime  @default(now()) @map("created_at") @db.Timestamptz(6)
     updatedAt             DateTime  @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

     user        User                   @relation(fields: [userId], references: [id], onDelete: Cascade, onUpdate: Cascade)
     backupCodes TwoFactorBackupCode[]

     @@map("two_factor_settings")
   }

   model TwoFactorBackupCode {
     id                    String    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("two_factor_backup_codes_id")
     twoFactorSettingsId   String    @map("two_factor_settings_id") @db.Uuid
     codeHash              String    @map("code_hash")
     usedAt                DateTime? @map("used_at") @db.Timestamptz(6)
     createdAt             DateTime  @default(now()) @map("created_at") @db.Timestamptz(6)

     twoFactorSettings TwoFactorSettings @relation(fields: [twoFactorSettingsId], references: [id], onDelete: Cascade, onUpdate: Cascade)

     @@map("two_factor_backup_codes")
   }

   model MagicLinkToken {
     id         String    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid @map("magic_link_tokens_id")
     userId     String?   @map("users_id") @db.Uuid
     email      String
     token      String    @unique
     ipAddress  String?   @map("ip_address")
     userAgent  String?   @map("user_agent")
     expiresAt  DateTime  @map("expires_at") @db.Timestamptz(6)
     usedAt     DateTime? @map("used_at") @db.Timestamptz(6)
     createdAt  DateTime  @default(now()) @map("created_at") @db.Timestamptz(6)

     user User? @relation(fields: [userId], references: [id], onDelete: Cascade, onUpdate: Cascade)

     @@index([token], map: "idx_magic_link_tokens_token")
     @@index([email], map: "idx_magic_link_tokens_email")
     @@index([expiresAt], map: "idx_magic_link_tokens_expires")
     @@map("magic_link_tokens")
   }

   // Add to User model:
   model User {
     // ... existing fields
     twoFactorSettings TwoFactorSettings?
     magicLinkTokens   MagicLinkToken[]
   }
   ```

**Deliverables:**
- ✅ Two-factor settings table
- ✅ Backup codes table with hash storage
- ✅ Magic link tokens table
- ✅ Prisma schema updated
- ✅ Database migration created

---

### 4.6.2 TOTP (Authenticator App) Implementation

**Tasks:**

1. **Install TOTP dependencies:**
   ```bash
   pnpm add otpauth qrcode
   pnpm add -D @types/qrcode
   ```

2. **Create TOTP service in `packages/auth/src/totp-service.ts`:**
   ```typescript
   import { TOTP, Secret } from 'otpauth';
   import { config, TWO_FACTOR } from '@singr/config';
   import { createLogger } from '@singr/observability';
   import QRCode from 'qrcode';

   const logger = createLogger('auth:totp');

   export class TOTPService {
     generateSecret(): string {
       const secret = new Secret({ size: 20 });
       return secret.base32;
     }

     generateQRCode(email: string, secret: string): Promise<string> {
       const totp = new TOTP({
         issuer: config.TWO_FACTOR_ISSUER,
         label: email,
         algorithm: 'SHA1',
         digits: 6,
         period: TWO_FACTOR.TOTP_STEP,
         secret: Secret.fromBase32(secret),
       });

       const uri = totp.toString();
       return QRCode.toDataURL(uri);
     }

     verifyToken(secret: string, token: string): boolean {
       try {
         const totp = new TOTP({
           issuer: config.TWO_FACTOR_ISSUER,
           algorithm: 'SHA1',
           digits: 6,
           period: TWO_FACTOR.TOTP_STEP,
           secret: Secret.fromBase32(secret),
         });

         const delta = totp.validate({
           token,
           window: config.TWO_FACTOR_WINDOW,
         });

         if (delta === null) {
           logger.debug('TOTP token validation failed');
           return false;
         }

         logger.debug({ delta }, 'TOTP token validated');
         return true;
       } catch (error) {
         logger.error({ error }, 'TOTP verification error');
         return false;
       }
     }

     generateBackupCodes(count: number = TWO_FACTOR.BACKUP_CODE_COUNT): string[] {
       const codes: string[] = [];
       const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluding ambiguous chars

       for (let i = 0; i < count; i++) {
         let code = '';
         for (let j = 0; j < TWO_FACTOR.BACKUP_CODE_LENGTH; j++) {
           code += chars.charAt(Math.floor(Math.random() * chars.length));
         }
         codes.push(code);
       }

       return codes;
     }
   }
   ```

3. **Create 2FA schemas in `apps/api/src/routes/auth/schemas.ts`:**
   ```typescript
   // Add to existing schemas
   export const EnableTOTPSchema = z.object({
     password: z.string().min(1),
   });

   export const VerifyTOTPSchema = z.object({
     token: z.string().length(6, 'Token must be 6 digits'),
   });

   export const DisableTwoFactorSchema = z.object({
     password: z.string().min(1),
     method: z.enum(['totp', 'sms']),
   });

   export const TwoFactorChallengeSchema = z.object({
     token: z.string().min(6).max(8),
     method: z.enum(['totp', 'sms', 'backup']),
   });

   export const RequestSMSCodeSchema = z.object({
     phoneNumber: z.string().regex(/^\+[1-9]\d{1,14}$/, 'Must be in E.164 format'),
   });
   ```

4. **Implement TOTP routes in `apps/api/src/routes/auth/two-factor.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateBody } from '@singr/shared/validation';
   import {
     EnableTOTPSchema,
     VerifyTOTPSchema,
     DisableTwoFactorSchema,
     TwoFactorChallengeSchema,
     RequestSMSCodeSchema,
   } from './schemas';
   import { TOTPService } from '@singr/auth/totp-service';
   import { verifyPassword, hashPassword, buildJWTPayload } from '@singr/auth';
   import { createLogger } from '@singr/observability';
   import { createCommunicationQueue } from '@singr/shared/queues/communication-queue';
   import { SMSService } from '@singr/shared/services/sms/sms-service';
   import { config } from '@singr/config';

   const logger = createLogger('routes:auth:two-factor');

   export const twoFactorRoute: FastifyPluginAsync = async (server) => {
     const totpService = new TOTPService();
     const smsService = new SMSService();
     const communicationQueue = createCommunicationQueue(server.redis);

     // Enable TOTP (step 1: generate secret and QR code)
     server.post(
       '/two-factor/totp/enable',
       {
         schema: {
           tags: ['auth'],
           summary: 'Enable TOTP',
           description: 'Generate TOTP secret and QR code for authenticator app',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['password'],
             properties: {
               password: { type: 'string' },
             },
           },
           response: {
             200: {
               description: 'TOTP setup initiated',
               type: 'object',
               properties: {
                 secret: { type: 'string' },
                 qrCode: { type: 'string' },
                 backupCodes: { type: 'array', items: { type: 'string' } },
               },
             },
           },
         },
         preHandler: [server.authenticate, validateBody(EnableTOTPSchema)],
       },
       async (request, reply) => {
         const { password } = request.body as z.infer<typeof EnableTOTPSchema>;
         const userId = request.user.sub;

         const user = await server.prisma.user.findUnique({
           where: { id: userId },
           include: { twoFactorSettings: true },
         });

         if (!user || !user.passwordHash) {
           return reply.code(401).send({
             type: 'authentication_failed',
             title: 'Authentication Failed',
             detail: 'Invalid credentials',
           });
         }

         // Verify password
         const validPassword = await verifyPassword(user.passwordHash, password);
         if (!validPassword) {
           return reply.code(401).send({
             type: 'authentication_failed',
             title: 'Authentication Failed',
             detail: 'Password is incorrect',
           });
         }

         // Generate TOTP secret
         const secret = totpService.generateSecret();
         const qrCode = await totpService.generateQRCode(user.email, secret);

         // Generate backup codes
         const backupCodes = totpService.generateBackupCodes();
         const backupCodeHashes = await Promise.all(
           backupCodes.map((code) => hashPassword(code))
         );

         // Create or update 2FA settings (not enabled yet)
         const twoFactorSettings = await server.prisma.twoFactorSettings.upsert({
           where: { userId },
           create: {
             userId,
             totpSecret: secret,
             totpEnabled: false,
           },
           update: {
             totpSecret: secret,
             totpEnabled: false,
           },
         });

         // Delete old backup codes and create new ones
         await server.prisma.twoFactorBackupCode.deleteMany({
           where: { twoFactorSettingsId: twoFactorSettings.id },
         });

         await server.prisma.twoFactorBackupCode.createMany({
           data: backupCodeHashes.map((codeHash) => ({
             twoFactorSettingsId: twoFactorSettings.id,
             codeHash,
           })),
         });

         await server.prisma.twoFactorSettings.update({
           where: { id: twoFactorSettings.id },
           data: { backupCodesGeneratedAt: new Date() },
         });

         logger.info({ userId }, 'TOTP setup initiated');

         return reply.send({
           secret,
           qrCode,
           backupCodes,
         });
       }
     );

     // Verify and enable TOTP (step 2: verify token from authenticator)
     server.post(
       '/two-factor/totp/verify',
       {
         schema: {
           tags: ['auth'],
           summary: 'Verify and enable TOTP',
           description: 'Verify TOTP token and enable two-factor authentication',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['token'],
             properties: {
               token: { type: 'string', minLength: 6, maxLength: 6 },
             },
           },
           response: {
             200: {
               description: 'TOTP enabled',
               type: 'object',
               properties: {
                 message: { type: 'string' },
               },
             },
           },
         },
         preHandler: [server.authenticate, validateBody(VerifyTOTPSchema)],
       },
       async (request, reply) => {
         const { token } = request.body as z.infer<typeof VerifyTOTPSchema>;
         const userId = request.user.sub;

         const twoFactorSettings = await server.prisma.twoFactorSettings.findUnique({
           where: { userId },
         });

         if (!twoFactorSettings?.totpSecret) {
           return reply.code(400).send({
             type: 'invalid_request',
             title: 'TOTP Not Initialized',
             detail: 'TOTP setup must be initiated first',
           });
         }

         // Verify token
         const valid = totpService.verifyToken(twoFactorSettings.totpSecret, token);

         if (!valid) {
           return reply.code(400).send({
             type: 'invalid_token',
             title: 'Invalid Token',
             detail: 'TOTP token is invalid',
           });
         }

         // Enable TOTP
         await server.prisma.twoFactorSettings.update({
           where: { id: twoFactorSettings.id },
           data: {
             totpEnabled: true,
             totpVerifiedAt: new Date(),
           },
         });

         // Send confirmation email
         const user = await server.prisma.user.findUnique({
           where: { id: userId },
         });

         if (user) {
           await communicationQueue.add('email', {
             type: 'email',
             to: user.email,
             toName: user.name || undefined,
             subject: 'Two-factor authentication enabled',
             htmlPart: `
               <h2>Two-Factor Authentication Enabled</h2>
               <p>Hello ${user.name || 'there'},</p>
               <p>Two-factor authentication using an authenticator app has been successfully enabled on your account.</p>
               <p>If you did not enable this, please contact support immediately.</p>
             `,
             textPart: `Two-factor authentication has been enabled on your account. If you did not enable this, please contact support immediately.`,
           });
         }

         logger.info({ userId }, 'TOTP enabled');

         return reply.send({
           message: 'Two-factor authentication enabled successfully',
         });
       }
     );

     // Disable two-factor authentication
     server.post(
       '/two-factor/disable',
       {
         schema: {
           tags: ['auth'],
           summary: 'Disable two-factor authentication',
           description: 'Disable TOTP or SMS two-factor authentication',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['password', 'method'],
             properties: {
               password: { type: 'string' },
               method: { type: 'string', enum: ['totp', 'sms'] },
             },
           },
           response: {
             200: {
               description: '2FA disabled',
               type: 'object',
               properties: {
                 message: { type: 'string' },
               },
             },
           },
         },
         preHandler: [server.authenticate, validateBody(DisableTwoFactorSchema)],
       },
       async (request, reply) => {
         const { password, method } = request.body as z.infer<
           typeof DisableTwoFactorSchema
         >;
         const userId = request.user.sub;

         const user = await server.prisma.user.findUnique({
           where: { id: userId },
         });

         if (!user || !user.passwordHash) {
           return reply.code(401).send({
             type: 'authentication_failed',
             title: 'Authentication Failed',
             detail: 'Invalid credentials',
           });
         }

         // Verify password
         const validPassword = await verifyPassword(user.passwordHash, password);
         if (!validPassword) {
           return reply.code(401).send({
             type: 'authentication_failed',
             title: 'Authentication Failed',
             detail: 'Password is incorrect',
           });
         }

         // Disable requested method
         const updateData: any = {};
         if (method === 'totp') {
           updateData.totpEnabled = false;
           updateData.totpSecret = null;
           updateData.totpVerifiedAt = null;
         } else if (method === 'sms') {
           updateData.smsEnabled = false;
           updateData.smsPhoneNumber = null;
           updateData.smsVerifiedAt = null;
         }

         await server.prisma.twoFactorSettings.update({
           where: { userId },
           data: updateData,
         });

         // Send confirmation email
         await communicationQueue.add('email', {
           type: 'email',
           to: user.email,
           toName: user.name || undefined,
           subject: 'Two-factor authentication disabled',
           htmlPart: `
             <h2>Two-Factor Authentication Disabled</h2>
             <p>Hello ${user.name || 'there'},</p>
             <p>Two-factor authentication (${method.toUpperCase()}) has been disabled on your account.</p>
             <p>If you did not disable this, please contact support immediately and secure your account.</p>
           `,
           textPart: `Two-factor authentication (${method.toUpperCase()}) has been disabled. If you did not disable this, please contact support immediately.`,
         });

         logger.info({ userId, method }, '2FA disabled');

         return reply.send({
           message: `Two-factor authentication (${method.toUpperCase()}) disabled successfully`,
         });
       }
     );

     // Get 2FA status
     server.get(
       '/two-factor/status',
       {
         schema: {
           tags: ['auth'],
           summary: 'Get 2FA status',
           description: 'Check which 2FA methods are enabled',
           security: [{ bearerAuth: [] }],
           response: {
             200: {
               description: '2FA status',
               type: 'object',
               properties: {
                 totpEnabled: { type: 'boolean' },
                 smsEnabled: { type: 'boolean' },
                 backupCodesGenerated: { type: 'boolean' },
               },
             },
           },
         },
         preHandler: [server.authenticate],
       },
       async (request, reply) => {
         const userId = request.user.sub;

         const twoFactorSettings = await server.prisma.twoFactorSettings.findUnique({
           where: { userId },
         });

         return reply.send({
           totpEnabled: twoFactorSettings?.totpEnabled || false,
           smsEnabled: twoFactorSettings?.smsEnabled || false,
           smsPhoneNumber: twoFactorSettings?.smsPhoneNumber || null,
           backupCodesGenerated: !!twoFactorSettings?.backupCodesGeneratedAt,
         });
       }
     );
   };
   ```

**Deliverables:**
- ✅ TOTP service with QR code generation
- ✅ `POST /v1/auth/two-factor/totp/enable` - Initiate TOTP setup
- ✅ `POST /v1/auth/two-factor/totp/verify` - Verify and enable TOTP
- ✅ `POST /v1/auth/two-factor/disable` - Disable 2FA
- ✅ `GET /v1/auth/two-factor/status` - Check 2FA status
- ✅ Backup code generation (10 codes, 8 characters)
- ✅ Password confirmation required
- ✅ Email notifications for 2FA changes

---

### 4.6.3 SMS Two-Factor Authentication

**Tasks:**

1. **Implement SMS 2FA routes (add to `apps/api/src/routes/auth/two-factor.ts`):**
   ```typescript
   // Add to existing twoFactorRoute
   
   // Enable SMS 2FA (step 1: send verification code)
   server.post(
     '/two-factor/sms/enable',
     {
       schema: {
         tags: ['auth'],
         summary: 'Enable SMS 2FA',
         description: 'Send SMS verification code to enable SMS two-factor authentication',
         security: [{ bearerAuth: [] }],
         body: {
           type: 'object',
           required: ['phoneNumber', 'password'],
           properties: {
             phoneNumber: { type: 'string', pattern: '^\\+[1-9]\\d{1,14}$' },
             password: { type: 'string' },
           },
         },
         response: {
           200: {
             description: 'Verification code sent',
             type: 'object',
             properties: {
               message: { type: 'string' },
               phoneNumber: { type: 'string' },
             },
           },
         },
       },
       preHandler: [server.authenticate, validateBody(RequestSMSCodeSchema.extend({
         password: z.string().min(1),
       }))],
       config: {
         rateLimit: {
           max: 5,
           timeWindow: '1 hour',
         },
       },
     },
     async (request, reply) => {
       const { phoneNumber, password } = request.body as any;
       const userId = request.user.sub;

       const user = await server.prisma.user.findUnique({
         where: { id: userId },
       });

       if (!user || !user.passwordHash) {
         return reply.code(401).send({
           type: 'authentication_failed',
           title: 'Authentication Failed',
           detail: 'Invalid credentials',
         });
       }

       // Verify password
       const validPassword = await verifyPassword(user.passwordHash, password);
       if (!validPassword) {
         return reply.code(401).send({
           type: 'authentication_failed',
           title: 'Authentication Failed',
           detail: 'Password is incorrect',
         });
       }

       // Generate verification code
       const verificationCode = smsService.generateVerificationCode();

       // Store in Redis with 5-minute TTL
       await server.redis.setex(
         `sms_2fa_setup:${userId}`,
         300,
         JSON.stringify({
           phoneNumber,
           code: verificationCode,
           attempts: 0,
         })
       );

       // Send SMS
       await communicationQueue.add('sms', {
         type: 'sms',
         to: phoneNumber,
         body: `Your Singr 2FA setup code is: ${verificationCode}. Valid for 5 minutes.`,
       });

       logger.info({ userId, phoneNumber }, 'SMS 2FA setup code sent');

       return reply.send({
         message: 'Verification code sent to your phone',
         phoneNumber,
       });
     }
   );

   // Verify and enable SMS 2FA (step 2)
   server.post(
     '/two-factor/sms/verify',
     {
       schema: {
         tags: ['auth'],
         summary: 'Verify and enable SMS 2FA',
         description: 'Verify SMS code and enable SMS two-factor authentication',
         security: [{ bearerAuth: [] }],
         body: {
           type: 'object',
           required: ['code'],
           properties: {
             code: { type: 'string', minLength: 6, maxLength: 6 },
           },
         },
         response: {
           200: {
             description: 'SMS 2FA enabled',
             type: 'object',
             properties: {
               message: { type: 'string' },
               backupCodes: { type: 'array', items: { type: 'string' } },
             },
           },
         },
       },
       preHandler: [server.authenticate, validateBody(VerifyTOTPSchema)],
     },
     async (request, reply) => {
       const { token: code } = request.body as z.infer<typeof VerifyTOTPSchema>;
       const userId = request.user.sub;

       // Get pending verification from Redis
       const pendingData = await server.redis.get(`sms_2fa_setup:${userId}`);

       if (!pendingData) {
         return reply.code(400).send({
           type: 'invalid_code',
           title: 'Invalid or Expired Code',
           detail: 'Verification code has expired or does not exist',
         });
       }

       const pending = JSON.parse(pendingData);

       // Check attempts
       if (pending.attempts >= 5) {
         await server.redis.del(`sms_2fa_setup:${userId}`);
         return reply.code(429).send({
           type: 'too_many_attempts',
           title: 'Too Many Attempts',
           detail: 'Maximum verification attempts exceeded',
         });
       }

       // Verify code
       if (pending.code !== code) {
         pending.attempts++;
         await server.redis.setex(
           `sms_2fa_setup:${userId}`,
           300,
           JSON.stringify(pending)
         );

         return reply.code(400).send({
           type: 'invalid_code',
           title: 'Invalid Code',
           detail: `Verification code is incorrect. ${5 - pending.attempts} attempts remaining.`,
         });
       }

       // Generate backup codes
       const backupCodes = totpService.generateBackupCodes();
       const backupCodeHashes = await Promise.all(
         backupCodes.map((code) => hashPassword(code))
       );

       // Enable SMS 2FA
       const twoFactorSettings = await server.prisma.twoFactorSettings.upsert({
         where: { userId },
         create: {
           userId,
           smsEnabled: true,
           smsPhoneNumber: pending.phoneNumber,
           smsVerifiedAt: new Date(),
         },
         update: {
           smsEnabled: true,
           smsPhoneNumber: pending.phoneNumber,
           smsVerifiedAt: new Date(),
         },
       });

       // Save backup codes
       await server.prisma.twoFactorBackupCode.deleteMany({
         where: { twoFactorSettingsId: twoFactorSettings.id },
       });

       await server.prisma.twoFactorBackupCode.createMany({
         data: backupCodeHashes.map((codeHash) => ({
           twoFactorSettingsId: twoFactorSettings.id,
           codeHash,
         })),
       });

       await server.prisma.twoFactorSettings.update({
         where: { id: twoFactorSettings.id },
         data: { backupCodesGeneratedAt: new Date() },
       });

       // Delete verification data
       await server.redis.del(`sms_2fa_setup:${userId}`);

       // Send confirmation email
       const user = await server.prisma.user.findUnique({
         where: { id: userId },
       });

       if (user) {
         await communicationQueue.add('email', {
           type: 'email',
           to: user.email,
           toName: user.name || undefined,
           subject: 'SMS two-factor authentication enabled',
           htmlPart: `
             <h2>SMS Two-Factor Authentication Enabled</h2>
             <p>Hello ${user.name || 'there'},</p>
             <p>SMS two-factor authentication has been enabled for phone number: ${pending.phoneNumber}</p>
             <p>If you did not enable this, please contact support immediately.</p>
           `,
           textPart: `SMS two-factor authentication has been enabled for ${pending.phoneNumber}. If you did not enable this, please contact support immediately.`,
         });
       }

       logger.info({ userId, phoneNumber: pending.phoneNumber }, 'SMS 2FA enabled');

       return reply.send({
         message: 'SMS two-factor authentication enabled successfully',
         backupCodes,
       });
     }
   );
   ```

**Deliverables:**
- ✅ `POST /v1/auth/two-factor/sms/enable` - Send SMS verification code
- ✅ `POST /v1/auth/two-factor/sms/verify` - Verify code and enable SMS 2FA
- ✅ SMS verification via Twilio
- ✅ Backup codes generated for SMS 2FA
- ✅ Rate limiting (5 req/hour)
- ✅ Attempt tracking (max 5 attempts)
- ✅ Email confirmation

---

### 4.6.4 Magic Link Authentication

**Objective:** Implement passwordless authentication via email magic links.

**Duration:** 2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create magic link schemas in `apps/api/src/routes/auth/schemas.ts`:**
   ```typescript
   // Add to existing schemas
   export const RequestMagicLinkSchema = z.object({
     email: EmailSchema,
   });

   export const VerifyMagicLinkSchema = z.object({
     token: z.string().uuid('Invalid token format'),
   });
   ```

2. **Create magic link service in `packages/auth/src/magic-link-service.ts`:**
   ```typescript
   import { PrismaClient } from '@prisma/database';
   import { randomUUID } from 'crypto';
   import { config } from '@singr/config';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('auth:magic-link');

   export class MagicLinkService {
     constructor(private prisma: PrismaClient) {}

     async createMagicLink(
       email: string,
       ipAddress: string,
       userAgent: string
     ): Promise<{ token: string; userId: string | null }> {
       // Check if user exists
       const user = await this.prisma.user.findUnique({
         where: { email: email.toLowerCase() },
       });

       // Generate token
       const token = randomUUID();
       const expiresAt = new Date(Date.now() + config.MAGIC_LINK_TTL * 1000);

       // Create magic link token
       await this.prisma.magicLinkToken.create({
         data: {
           userId: user?.id || null,
           email: email.toLowerCase(),
           token,
           ipAddress,
           userAgent,
           expiresAt,
         },
       });

       logger.info(
         {
           email,
           userId: user?.id,
           ipAddress,
         },
         'Magic link created'
       );

       return { token, userId: user?.id || null };
     }

     async verifyMagicLink(token: string): Promise<{
       valid: boolean;
       email?: string;
       userId?: string;
       error?: string;
     }> {
       const magicLink = await this.prisma.magicLinkToken.findUnique({
         where: { token },
       });

       if (!magicLink) {
         return { valid: false, error: 'Invalid token' };
       }

       if (magicLink.usedAt) {
         return { valid: false, error: 'Token already used' };
       }

       if (magicLink.expiresAt < new Date()) {
         return { valid: false, error: 'Token expired' };
       }

       // Mark as used
       await this.prisma.magicLinkToken.update({
         where: { id: magicLink.id },
         data: { usedAt: new Date() },
       });

       logger.info(
         {
           email: magicLink.email,
           userId: magicLink.userId,
         },
         'Magic link verified'
       );

       return {
         valid: true,
         email: magicLink.email,
         userId: magicLink.userId || undefined,
       };
     }

     async cleanupExpiredTokens(): Promise<number> {
       const result = await this.prisma.magicLinkToken.deleteMany({
         where: {
           expiresAt: { lt: new Date() },
         },
       });

       logger.debug({ count: result.count }, 'Expired magic links cleaned up');

       return result.count;
     }
   }
   ```

3. **Implement magic link routes in `apps/api/src/routes/auth/magic-link.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateBody } from '@singr/shared/validation';
   import { RequestMagicLinkSchema, VerifyMagicLinkSchema } from './schemas';
   import { MagicLinkService } from '@singr/auth/magic-link-service';
   import { buildJWTPayload, RefreshTokenService } from '@singr/auth';
   import { createLogger } from '@singr/observability';
   import { createCommunicationQueue } from '@singr/shared/queues/communication-queue';
   import { config } from '@singr/config';

   const logger = createLogger('routes:auth:magic-link');

   export const magicLinkRoute: FastifyPluginAsync = async (server) => {
     const magicLinkService = new MagicLinkService(server.prisma);
     const communicationQueue = createCommunicationQueue(server.redis);

     // Request magic link
     server.post(
       '/magic-link/request',
       {
         schema: {
           tags: ['auth'],
           summary: 'Request magic link',
           description: 'Send passwordless authentication link via email',
           body: {
             type: 'object',
             required: ['email'],
             properties: {
               email: { type: 'string', format: 'email' },
             },
           },
           response: {
             200: {
               description: 'Magic link sent (or email not found)',
               type: 'object',
               properties: {
                 message: { type: 'string' },
               },
             },
           },
         },
         preHandler: [validateBody(RequestMagicLinkSchema)],
         config: {
           rateLimit: {
             max: 5,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const { email } = request.body as z.infer<typeof RequestMagicLinkSchema>;
         const ipAddress = request.ip;
         const userAgent = request.headers['user-agent'] || 'Unknown';

         // Create magic link (always returns success to prevent email enumeration)
         const { token, userId } = await magicLinkService.createMagicLink(
           email,
           ipAddress,
           userAgent
         );

         // Only send email if user exists
         if (userId) {
           const magicLink = `${config.APP_URL_WEB}/auth/magic?token=${token}`;

           await communicationQueue.add('email', {
             type: 'email',
             to: email,
             subject: 'Sign in to Singr',
             templateId: config.MAILJET_TEMPLATE_MAGIC_LINK,
             variables: {
               user_email: email,
               magic_link: magicLink,
               expiry_minutes: Math.floor(config.MAGIC_LINK_TTL / 60),
               ip_address: ipAddress,
             },
           });

           logger.info({ email, userId, ipAddress }, 'Magic link email sent');
         } else {
           logger.debug({ email, ipAddress }, 'Magic link requested for non-existent user');
         }

         return reply.send({
           message: 'If an account exists, a sign-in link has been sent to your email',
         });
       }
     );

     // Verify magic link and sign in
     server.post(
       '/magic-link/verify',
       {
         schema: {
           tags: ['auth'],
           summary: 'Verify magic link',
           description: 'Verify magic link token and authenticate user',
           body: {
             type: 'object',
             required: ['token'],
             properties: {
               token: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'Authentication successful',
               type: 'object',
               properties: {
                 accessToken: { type: 'string' },
                 refreshToken: { type: 'string' },
                 expiresIn: { type: 'number' },
                 tokenType: { type: 'string' },
                 requiresTwoFactor: { type: 'boolean' },
                 twoFactorMethods: {
                   type: 'array',
                   items: { type: 'string' },
                 },
                 user: {
                   type: 'object',
                   properties: {
                     id: { type: 'string', format: 'uuid' },
                     email: { type: 'string' },
                     name: { type: 'string' },
                   },
                 },
               },
             },
             400: {
               description: 'Invalid or expired token',
             },
           },
         },
         preHandler: [validateBody(VerifyMagicLinkSchema)],
         config: {
           rateLimit: {
             max: 10,
             timeWindow: '1 minute',
           },
         },
       },
       async (request, reply) => {
         const { token } = request.body as z.infer<typeof VerifyMagicLinkSchema>;

         // Verify magic link
         const verification = await magicLinkService.verifyMagicLink(token);

         if (!verification.valid || !verification.userId) {
           return reply.code(400).send({
             type: 'invalid_token',
             title: 'Invalid or Expired Token',
             detail: verification.error || 'Magic link is invalid or has expired',
           });
         }

         // Get user
         const user = await server.prisma.user.findUnique({
           where: { id: verification.userId },
           include: {
             twoFactorSettings: true,
             userRoles: {
               include: { role: true },
             },
           },
         });

         if (!user) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'User Not Found',
             detail: 'User account not found',
           });
         }

         // Check if email is verified
         if (!user.isEmailVerified) {
           return reply.code(403).send({
             type: 'email_not_verified',
             title: 'Email Not Verified',
             detail: 'Please verify your email before signing in',
           });
         }

         // Check if 2FA is enabled
         const twoFactorEnabled =
           user.twoFactorSettings?.totpEnabled || user.twoFactorSettings?.smsEnabled;

         if (twoFactorEnabled) {
           // Store pending 2FA session in Redis (5 minutes)
           const tempToken = randomUUID();
           await server.redis.setex(
             `2fa_pending:${tempToken}`,
             300,
             JSON.stringify({
               userId: user.id,
               email: user.email,
               method: 'magic_link',
             })
           );

           const availableMethods: string[] = [];
           if (user.twoFactorSettings?.totpEnabled) availableMethods.push('totp');
           if (user.twoFactorSettings?.smsEnabled) availableMethods.push('sms');
           availableMethods.push('backup');

           logger.info({ userId: user.id, email: user.email }, 'Magic link verified - 2FA required');

           return reply.send({
             requiresTwoFactor: true,
             twoFactorMethods: availableMethods,
             twoFactorToken: tempToken,
             message: 'Two-factor authentication required',
           });
         }

         // Build JWT payload
         const payload = await buildJWTPayload(user.id);
         const accessToken = server.jwt.sign(payload);

         // Create refresh token
         const refreshTokenService = new RefreshTokenService(server.redis);
         const refreshToken = await refreshTokenService.create(user.id);

         // Update last login
         await server.prisma.user.update({
           where: { id: user.id },
           data: { lastLoginAt: new Date() },
         });

         logger.info({ userId: user.id, email: user.email }, 'Magic link authentication successful');

         return reply.send({
           accessToken,
           refreshToken,
           expiresIn: config.JWT_ACCESS_TTL,
           tokenType: 'Bearer',
           requiresTwoFactor: false,
           user: {
             id: user.id,
             email: user.email,
             name: user.name,
             roles: user.userRoles.map((ur) => ur.role.slug),
           },
         });
       }
     );
   };
   ```

**Deliverables:**
- ✅ `POST /v1/auth/magic-link/request` - Request magic link via email
- ✅ `POST /v1/auth/magic-link/verify` - Verify token and authenticate
- ✅ Magic link service with token generation and verification
- ✅ Email sent via Mailjet with magic link
- ✅ Token expiration (configurable, default 15 minutes)
- ✅ One-time use tokens
- ✅ IP address and user agent tracking
- ✅ Privacy-preserving responses (don't reveal user existence)
- ✅ 2FA integration (challenge if enabled)
- ✅ Rate limiting (5 requests/hour for generation)
- ✅ Cleanup of expired tokens

---

### 4.6.5 Two-Factor Challenge Flow

**Objective:** Complete authentication flow when 2FA is required.

**Duration:** 2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Implement 2FA challenge routes in `apps/api/src/routes/auth/two-factor-challenge.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateBody } from '@singr/shared/validation';
   import { TwoFactorChallengeSchema } from './schemas';
   import { TOTPService } from '@singr/auth/totp-service';
   import { verifyPassword, buildJWTPayload, RefreshTokenService } from '@singr/auth';
   import { createLogger } from '@singr/observability';
   import { createCommunicationQueue } from '@singr/shared/queues/communication-queue';
   import { SMSService } from '@singr/shared/services/sms/sms-service';
   import { config } from '@singr/config';

   const logger = createLogger('routes:auth:two-factor-challenge');

   export const twoFactorChallengeRoute: FastifyPluginAsync = async (server) => {
     const totpService = new TOTPService();
     const smsService = new SMSService();
     const communicationQueue = createCommunicationQueue(server.redis);

     // Request SMS code during sign-in
     server.post(
       '/two-factor/challenge/sms',
       {
         schema: {
           tags: ['auth'],
           summary: 'Request SMS 2FA code',
           description: 'Send SMS code during two-factor authentication challenge',
           body: {
             type: 'object',
             required: ['twoFactorToken'],
             properties: {
               twoFactorToken: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'SMS code sent',
               type: 'object',
               properties: {
                 message: { type: 'string' },
               },
             },
           },
         },
         preHandler: [validateBody(z.object({ twoFactorToken: z.string().uuid() }))],
         config: {
           rateLimit: {
             max: 3,
             timeWindow: '15 minutes',
           },
         },
       },
       async (request, reply) => {
         const { twoFactorToken } = request.body as { twoFactorToken: string };

         // Get pending 2FA session
         const pendingData = await server.redis.get(`2fa_pending:${twoFactorToken}`);

         if (!pendingData) {
           return reply.code(400).send({
             type: 'invalid_token',
             title: 'Invalid Session',
             detail: 'Two-factor authentication session expired',
           });
         }

         const pending = JSON.parse(pendingData);

         // Get user and 2FA settings
         const user = await server.prisma.user.findUnique({
           where: { id: pending.userId },
           include: { twoFactorSettings: true },
         });

         if (!user?.twoFactorSettings?.smsEnabled || !user.twoFactorSettings.smsPhoneNumber) {
           return reply.code(400).send({
             type: 'invalid_request',
             title: 'SMS Not Enabled',
             detail: 'SMS two-factor authentication is not enabled',
           });
         }

         // Generate code
         const code = smsService.generateVerificationCode();

         // Store code in Redis (5 minutes)
         await server.redis.setex(
           `2fa_sms:${twoFactorToken}`,
           300,
           JSON.stringify({ code, attempts: 0 })
         );

         // Send SMS
         await communicationQueue.add('sms', {
           type: 'sms',
           to: user.twoFactorSettings.smsPhoneNumber,
           body: `Your Singr verification code is: ${code}. Valid for 5 minutes.`,
         });

         logger.info({ userId: user.id }, '2FA SMS code sent');

         return reply.send({
           message: 'Verification code sent to your phone',
         });
       }
     );

     // Verify 2FA challenge
     server.post(
       '/two-factor/challenge/verify',
       {
         schema: {
           tags: ['auth'],
           summary: 'Verify 2FA challenge',
           description: 'Complete two-factor authentication challenge',
           body: {
             type: 'object',
             required: ['twoFactorToken', 'token', 'method'],
             properties: {
               twoFactorToken: { type: 'string', format: 'uuid' },
               token: { type: 'string', minLength: 6, maxLength: 8 },
               method: { type: 'string', enum: ['totp', 'sms', 'backup'] },
             },
           },
           response: {
             200: {
               description: 'Authentication successful',
               type: 'object',
               properties: {
                 accessToken: { type: 'string' },
                 refreshToken: { type: 'string' },
                 expiresIn: { type: 'number' },
                 tokenType: { type: 'string' },
                 user: {
                   type: 'object',
                   properties: {
                     id: { type: 'string', format: 'uuid' },
                     email: { type: 'string' },
                     name: { type: 'string' },
                   },
                 },
               },
             },
           },
         },
         preHandler: [validateBody(TwoFactorChallengeSchema.extend({
           twoFactorToken: z.string().uuid(),
         }))],
         config: {
           rateLimit: {
             max: 10,
             timeWindow: '15 minutes',
           },
         },
       },
       async (request, reply) => {
         const { twoFactorToken, token, method } = request.body as z.infer<
           typeof TwoFactorChallengeSchema
         > & { twoFactorToken: string };

         // Get pending 2FA session
         const pendingData = await server.redis.get(`2fa_pending:${twoFactorToken}`);

         if (!pendingData) {
           return reply.code(400).send({
             type: 'invalid_token',
             title: 'Invalid Session',
             detail: 'Two-factor authentication session expired',
           });
         }

         const pending = JSON.parse(pendingData);

         // Get user and 2FA settings
         const user = await server.prisma.user.findUnique({
           where: { id: pending.userId },
           include: {
             twoFactorSettings: {
               include: {
                 backupCodes: {
                   where: { usedAt: null },
                 },
               },
             },
             userRoles: {
               include: { role: true },
             },
           },
         });

         if (!user?.twoFactorSettings) {
           return reply.code(400).send({
             type: 'invalid_request',
             title: '2FA Not Configured',
             detail: 'Two-factor authentication is not configured',
           });
         }

         let valid = false;

         // Verify based on method
         if (method === 'totp') {
           if (!user.twoFactorSettings.totpEnabled || !user.twoFactorSettings.totpSecret) {
             return reply.code(400).send({
               type: 'invalid_request',
               title: 'TOTP Not Enabled',
               detail: 'TOTP is not enabled for this account',
             });
           }

           valid = totpService.verifyToken(user.twoFactorSettings.totpSecret, token);
         } else if (method === 'sms') {
           if (!user.twoFactorSettings.smsEnabled) {
             return reply.code(400).send({
               type: 'invalid_request',
               title: 'SMS Not Enabled',
               detail: 'SMS 2FA is not enabled for this account',
             });
           }

           // Get SMS code from Redis
           const smsData = await server.redis.get(`2fa_sms:${twoFactorToken}`);

           if (!smsData) {
             return reply.code(400).send({
               type: 'invalid_code',
               title: 'Code Expired',
               detail: 'SMS verification code has expired',
             });
           }

           const sms = JSON.parse(smsData);

           if (sms.attempts >= 5) {
             await server.redis.del(`2fa_sms:${twoFactorToken}`);
             return reply.code(429).send({
               type: 'too_many_attempts',
               title: 'Too Many Attempts',
               detail: 'Maximum verification attempts exceeded',
             });
           }

           if (sms.code === token) {
             valid = true;
             await server.redis.del(`2fa_sms:${twoFactorToken}`);
           } else {
             sms.attempts++;
             await server.redis.setex(
               `2fa_sms:${twoFactorToken}`,
               300,
               JSON.stringify(sms)
             );
           }
         } else if (method === 'backup') {
           // Check backup codes
           for (const backupCode of user.twoFactorSettings.backupCodes) {
             const matches = await verifyPassword(backupCode.codeHash, token);
             if (matches) {
               // Mark code as used
               await server.prisma.twoFactorBackupCode.update({
                 where: { id: backupCode.id },
                 data: { usedAt: new Date() },
               });

               valid = true;

               // Send alert email
               await communicationQueue.add('email', {
                 type: 'email',
                 to: user.email,
                 toName: user.name || undefined,
                 subject: 'Backup code used for sign-in',
                 htmlPart: `
                   <h2>Backup Code Used</h2>
                   <p>Hello ${user.name || 'there'},</p>
                   <p>A backup code was used to sign in to your account.</p>
                   <p>You have ${user.twoFactorSettings.backupCodes.length - 1} backup codes remaining.</p>
                   <p>If this wasn't you, please secure your account immediately.</p>
                 `,
                 textPart: `A backup code was used to sign in to your account. You have ${
                   user.twoFactorSettings.backupCodes.length - 1
                 } backup codes remaining.`,
               });

               break;
             }
           }
         }

         if (!valid) {
           logger.warn({ userId: user.id, method }, '2FA verification failed');
           return reply.code(400).send({
             type: 'invalid_token',
             title: 'Invalid Code',
             detail: 'Verification code is incorrect',
           });
         }

         // Delete pending 2FA session
         await server.redis.del(`2fa_pending:${twoFactorToken}`);

         // Build JWT payload
         const payload = await buildJWTPayload(user.id);
         const accessToken = server.jwt.sign(payload);

         // Create refresh token
         const refreshTokenService = new RefreshTokenService(server.redis);
         const refreshToken = await refreshTokenService.create(user.id);

         // Update last login
         await server.prisma.user.update({
           where: { id: user.id },
           data: { lastLoginAt: new Date() },
         });

         logger.info({ userId: user.id, method }, '2FA challenge completed');

         return reply.send({
           accessToken,
           refreshToken,
           expiresIn: config.JWT_ACCESS_TTL,
           tokenType: 'Bearer',
           user: {
             id: user.id,
             email: user.email,
             name: user.name,
             roles: user.userRoles.map((ur) => ur.role.slug),
           },
         });
       }
     );
   };
   ```

2. **Update sign-in route to support 2FA in `apps/api/src/routes/auth/signin.ts`:**
   ```typescript
   // Add after password verification in existing signin route:

   // Check if 2FA is enabled
   const twoFactorSettings = await server.prisma.twoFactorSettings.findUnique({
     where: { userId: user.id },
   });

   const twoFactorEnabled =
     twoFactorSettings?.totpEnabled || twoFactorSettings?.smsEnabled;

   if (twoFactorEnabled) {
     // Store pending 2FA session in Redis (5 minutes)
     const tempToken = randomUUID();
     await server.redis.setex(
       `2fa_pending:${tempToken}`,
       300,
       JSON.stringify({
         userId: user.id,
         email: user.email,
         method: 'password',
       })
     );

     const availableMethods: string[] = [];
     if (twoFactorSettings?.totpEnabled) availableMethods.push('totp');
     if (twoFactorSettings?.smsEnabled) availableMethods.push('sms');
     availableMethods.push('backup');

     logger.info({ userId: user.id, email: user.email }, 'Sign in successful - 2FA required');

     return reply.send({
       requiresTwoFactor: true,
       twoFactorMethods: availableMethods,
       twoFactorToken: tempToken,
       message: 'Two-factor authentication required',
     });
   }

   // ... continue with normal JWT generation
   ```

3. **Register new routes in `apps/api/src/routes/auth/index.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { signinRoute } from './signin';
   import { registerRoute } from './register';
   import { refreshRoute } from './refresh';
   import { signoutRoute } from './signout';
   import { passwordRoute } from './password';
   import { profileRoute } from './profile';
   import { contextRoute } from './context';
   import { twoFactorRoute } from './two-factor';
   import { twoFactorChallengeRoute } from './two-factor-challenge';
   import { magicLinkRoute } from './magic-link';

   export const authRoutes: FastifyPluginAsync = async (server) => {
     await server.register(signinRoute);
     await server.register(registerRoute);
     await server.register(refreshRoute);
     await server.register(signoutRoute);
     await server.register(passwordRoute);
     await server.register(profileRoute);
     await server.register(contextRoute);
     await server.register(twoFactorRoute);
     await server.register(twoFactorChallengeRoute);
     await server.register(magicLinkRoute);
   };
   ```

**Deliverables:**
- ✅ `POST /v1/auth/two-factor/challenge/sms` - Request SMS code during sign-in
- ✅ `POST /v1/auth/two-factor/challenge/verify` - Verify 2FA challenge
- ✅ Support for TOTP, SMS, and backup code verification
- ✅ Temporary session storage in Redis (5 minutes)
- ✅ Integration with sign-in and magic link flows
- ✅ Backup code usage tracking
- ✅ Alert emails when backup codes are used
- ✅ Rate limiting on challenge verification
- ✅ Attempt tracking for SMS codes

---

### 4.6.6 Backup Code Management

**Objective:** Allow users to regenerate backup codes.

**Duration:** 1 day  
**Team Size:** 1 developer

**Tasks:**

1. **Add backup code routes to `apps/api/src/routes/auth/two-factor.ts`:**
   ```typescript
   // Add to existing twoFactorRoute

   // Regenerate backup codes
   server.post(
     '/two-factor/backup-codes/regenerate',
     {
       schema: {
         tags: ['auth'],
         summary: 'Regenerate backup codes',
         description: 'Generate new backup codes (invalidates old ones)',
         security: [{ bearerAuth: [] }],
         body: {
           type: 'object',
           required: ['password'],
           properties: {
             password: { type: 'string' },
           },
         },
         response: {
           200: {
             description: 'Backup codes regenerated',
             type: 'object',
             properties: {
               backupCodes: { type: 'array', items: { type: 'string' } },
             },
           },
         },
       },
       preHandler: [
         server.authenticate,
         validateBody(z.object({ password: z.string().min(1) })),
       ],
       config: {
         rateLimit: {
           max: 3,
           timeWindow: '1 hour',
         },
       },
     },
     async (request, reply) => {
       const { password } = request.body as { password: string };
       const userId = request.user.sub;

       const user = await server.prisma.user.findUnique({
         where: { id: userId },
         include: { twoFactorSettings: true },
       });

       if (!user || !user.passwordHash) {
         return reply.code(401).send({
           type: 'authentication_failed',
           title: 'Authentication Failed',
           detail: 'Invalid credentials',
         });
       }

       // Verify password
       const validPassword = await verifyPassword(user.passwordHash, password);
       if (!validPassword) {
         return reply.code(401).send({
           type: 'authentication_failed',
           title: 'Authentication Failed',
           detail: 'Password is incorrect',
         });
       }

       if (!user.twoFactorSettings) {
         return reply.code(400).send({
           type: 'invalid_request',
           title: '2FA Not Configured',
           detail: 'Two-factor authentication must be enabled first',
         });
       }

       // Generate new backup codes
       const backupCodes = totpService.generateBackupCodes();
       const backupCodeHashes = await Promise.all(
         backupCodes.map((code) => hashPassword(code))
       );

       // Delete old backup codes
       await server.prisma.twoFactorBackupCode.deleteMany({
         where: { twoFactorSettingsId: user.twoFactorSettings.id },
       });

       // Create new backup codes
       await server.prisma.twoFactorBackupCode.createMany({
         data: backupCodeHashes.map((codeHash) => ({
           twoFactorSettingsId: user.twoFactorSettings!.id,
           codeHash,
         })),
       });

       // Update timestamp
       await server.prisma.twoFactorSettings.update({
         where: { id: user.twoFactorSettings.id },
         data: { backupCodesGeneratedAt: new Date() },
       });

       // Send confirmation email
       await communicationQueue.add('email', {
         type: 'email',
         to: user.email,
         toName: user.name || undefined,
         subject: 'Backup codes regenerated',
         htmlPart: `
           <h2>Backup Codes Regenerated</h2>
           <p>Hello ${user.name || 'there'},</p>
           <p>New backup codes have been generated for your account.</p>
           <p>Your old backup codes are no longer valid.</p>
           <p>If you did not request this, please contact support immediately.</p>
         `,
         textPart: `New backup codes have been generated for your account. Your old backup codes are no longer valid.`,
       });

       logger.info({ userId }, 'Backup codes regenerated');

       return reply.send({
         backupCodes,
       });
     }
   );

   // View remaining backup codes count
   server.get(
     '/two-factor/backup-codes/count',
     {
       schema: {
         tags: ['auth'],
         summary: 'Get backup codes count',
         description: 'Check how many unused backup codes remain',
         security: [{ bearerAuth: [] }],
         response: {
           200: {
             description: 'Backup codes count',
             type: 'object',
             properties: {
               total: { type: 'integer' },
               remaining: { type: 'integer' },
               generatedAt: { type: 'string', format: 'date-time' },
             },
           },
         },
       },
       preHandler: [server.authenticate],
     },
     async (request, reply) => {
       const userId = request.user.sub;

       const twoFactorSettings = await server.prisma.twoFactorSettings.findUnique({
         where: { userId },
         include: {
           backupCodes: true,
         },
       });

       if (!twoFactorSettings) {
         return reply.send({
           total: 0,
           remaining: 0,
           generatedAt: null,
         });
       }

       const total = twoFactorSettings.backupCodes.length;
       const remaining = twoFactorSettings.backupCodes.filter(
         (code) => !code.usedAt
       ).length;

       return reply.send({
         total,
         remaining,
         generatedAt: twoFactorSettings.backupCodesGeneratedAt?.toISOString() || null,
       });
     }
   );
   ```

**Deliverables:**
- ✅ `POST /v1/auth/two-factor/backup-codes/regenerate` - Generate new backup codes
- ✅ `GET /v1/auth/two-factor/backup-codes/count` - Check remaining backup codes
- ✅ Password confirmation required
- ✅ Old codes invalidated when regenerating
- ✅ Email confirmation sent
- ✅ Rate limiting (3 req/hour)

---

**End of Phase 4.6. Complete deliverables:**

### Phase 4.6 Summary

**Complete Authentication Features:**
- ✅ TOTP (Time-based One-Time Password) with authenticator apps
- ✅ SMS two-factor authentication via Twilio
- ✅ Magic link passwordless authentication via Mailjet
- ✅ Backup codes for account recovery (10 codes, 8 characters each)
- ✅ Two-factor challenge flow integrated with sign-in
- ✅ Two-factor challenge flow integrated with magic links
- ✅ 2FA status endpoint
- ✅ 2FA enable/disable with password confirmation
- ✅ Backup code regeneration
- ✅ SMS code request during sign-in
- ✅ Rate limiting on all 2FA endpoints
- ✅ Email notifications for all 2FA changes
- ✅ Comprehensive audit logging
- ✅ Redis-based temporary session storage
- ✅ QR code generation for TOTP setup
- ✅ Magic link expiration and one-time use
- ✅ IP address and user agent tracking for magic links

---

## Phase 5: Public Venue Discovery & Guest Features

### 5.1 Venue Listing & Search

**Objective:** Allow anyone to discover karaoke venues with filtering and search.

**Duration:** 2-3 days  
**Team Size:** 1-2 developers

**Tasks:**

1. **Create venue schemas in `apps/api/src/routes/public/schemas.ts`:**
   ```typescript
   import { z } from 'zod';
   import { PaginationSchema, SortOrderSchema } from '@singr/shared/validation';

   export const VenueListQuerySchema = PaginationSchema.extend({
     city: z.string().max(100).optional(),
     state: z.string().max(50).optional(),
     country: z.string().max(50).optional(),
     acceptingRequests: z.coerce.boolean().optional(),
     search: z.string().max(100).optional(),
     sort: z.enum(['name', 'city', 'distance', 'created']).default('name'),
     order: SortOrderSchema,
   });

   export const VenueNearbyQuerySchema = z.object({
     lat: z.coerce.number().min(-90).max(90),
     lng: z.coerce.number().min(-180).max(180),
     radius: z.coerce.number().min(1).max(100).default(25), // miles
     limit: z.coerce.number().int().min(1).max(50).default(20),
     acceptingRequests: z.coerce.boolean().optional(),
   });

   export const VenueParamsSchema = z.object({
     urlName: z.string().min(1),
   });

   export const VenueListItemSchema = z.object({
     id: z.string().uuid(),
     urlName: z.string(),
     name: z.string(),
     address: z.string(),
     city: z.string(),
     state: z.string(),
     postalCode: z.string(),
     country: z.string().nullable(),
     phoneNumber: z.string().nullable(),
     website: z.string().nullable(),
     acceptingRequests: z.boolean(),
     distance: z.number().optional(),
     location: z
       .object({
         lat: z.number(),
         lng: z.number(),
       })
       .nullable(),
   });

   export const VenueDetailSchema = VenueListItemSchema.extend({
     openkjVenueId: z.number(),
     systems: z.array(
       z.object({
         id: z.string().uuid(),
         name: z.string(),
         openkjSystemId: z.number(),
       })
     ),
     branding: z
       .object({
         logoUrl: z.string().nullable(),
         colorPalette: z.record(z.string()),
         poweredBySingr: z.boolean(),
       })
       .nullable(),
     stats: z.object({
       totalSongs: z.number(),
       requestsToday: z.number(),
     }),
   });
   ```

2. **Implement venue service in `packages/shared/src/services/venue-service.ts`:**
   ```typescript
   import { PrismaClient } from '@prisma/database';
   import { Redis } from 'ioredis';
   import { CACHE_TTL } from '@singr/config';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('services:venue');

   export interface VenueFilters {
     city?: string;
     state?: string;
     country?: string;
     acceptingRequests?: boolean;
     search?: string;
   }

   export interface PaginationParams {
     page: number;
     limit: number;
     sort?: string;
     order?: 'asc' | 'desc';
   }

   export interface NearbyVenuesParams {
     lat: number;
     lng: number;
     radius: number;
     limit: number;
     acceptingRequests?: boolean;
   }

   export class VenueService {
     constructor(
       private prisma: PrismaClient,
       private redis: Redis
     ) {}

     async listVenues(filters: VenueFilters, pagination: PaginationParams) {
       const cacheKey = `venues:list:${JSON.stringify({ filters, pagination })}`;
       const cached = await this.redis.get(cacheKey);

       if (cached) {
         logger.debug('Venues list cache hit');
         return JSON.parse(cached);
       }

       const where: any = {};

       if (filters.city) {
         where.city = { contains: filters.city, mode: 'insensitive' };
       }
       if (filters.state) {
         where.state = { equals: filters.state, mode: 'insensitive' };
       }
       if (filters.country) {
         where.country = { equals: filters.country, mode: 'insensitive' };
       }
       if (filters.acceptingRequests !== undefined) {
         where.acceptingRequests = filters.acceptingRequests;
       }
       if (filters.search) {
         where.name = { contains: filters.search, mode: 'insensitive' };
       }

       const [venues, total] = await Promise.all([
         this.prisma.venue.findMany({
           where,
           skip: (pagination.page - 1) * pagination.limit,
           take: pagination.limit,
           orderBy: {
             [pagination.sort || 'name']: pagination.order || 'asc',
           },
         }),
         this.prisma.venue.count({ where }),
       ]);

       const result = {
         data: venues.map(this.formatVenueListItem),
         pagination: {
           page: pagination.page,
           limit: pagination.limit,
           total,
           totalPages: Math.ceil(total / pagination.limit),
         },
       };

       await this.redis.setex(
         cacheKey,
         CACHE_TTL.VENUES_LIST,
         JSON.stringify(result)
       );

       logger.debug({ count: venues.length, total }, 'Venues listed');

       return result;
     }

     async findNearbyVenues(params: NearbyVenuesParams) {
       const radiusMeters = params.radius * 1609.34;

       const query = `
         SELECT 
           venues_id as id,
           url_name,
           accepting_requests,
           name,
           address,
           city,
           state,
           postal_code,
           country,
           phone_number,
           website,
           ST_Y(location::geometry) as lat,
           ST_X(location::geometry) as lng,
           ST_Distance(
             location,
             ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
           ) / 1609.34 as distance_miles
         FROM venues
         WHERE 
           ST_DWithin(
             location,
             ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
             $3
           )
           ${params.acceptingRequests !== undefined ? 'AND accepting_requests = $4' : ''}
         ORDER BY distance_miles ASC
         LIMIT $${params.acceptingRequests !== undefined ? '5' : '4'}
       `;

       const queryParams =
         params.acceptingRequests !== undefined
           ? [params.lng, params.lat, radiusMeters, params.acceptingRequests, params.limit]
           : [params.lng, params.lat, radiusMeters, params.limit];

       const venues = await this.prisma.$queryRawUnsafe<any[]>(query, ...queryParams);

       logger.debug(
         { lat: params.lat, lng: params.lng, radius: params.radius, count: venues.length },
         'Nearby venues found'
       );

       return venues.map((v) => ({
         id: v.id,
         urlName: v.url_name,
         name: v.name,
         address: v.address,
         city: v.city,
         state: v.state,
         postalCode: v.postal_code,
         country: v.country,
         phoneNumber: v.phone_number,
         website: v.website,
         acceptingRequests: v.accepting_requests,
         distance: parseFloat(v.distance_miles.toFixed(2)),
         location: v.lat && v.lng ? { lat: parseFloat(v.lat), lng: parseFloat(v.lng) } : null,
       }));
     }

     async getVenueByUrlName(urlName: string, includeDetails = false) {
       const cacheKey = `venue:${urlName}:${includeDetails}`;
       const cached = await this.redis.get(cacheKey);

       if (cached) {
         logger.debug({ urlName }, 'Venue cache hit');
         return JSON.parse(cached);
       }

       const venue = await this.prisma.venue.findUnique({
         where: { urlName },
         include: {
           customerProfile: {
             include: {
               brandedApps: {
                 include: {
                   brandingProfile: true,
                 },
                 take: 1,
               },
             },
           },
           systems: includeDetails,
         },
       });

       if (!venue) {
         return null;
       }

       let stats = null;
       if (includeDetails) {
         const [totalSongs, requestsToday] = await Promise.all([
           this.prisma.songDb.count({
             where: { customerProfileId: venue.customerProfileId },
           }),
           this.prisma.request.count({
             where: {
               venueId: venue.id,
               requestedAt: {
                 gte: new Date(new Date().setHours(0, 0, 0, 0)),
               },
             },
           }),
         ]);

         stats = { totalSongs, requestsToday };
       }

       const result = this.formatVenueDetail(venue, stats);
       await this.redis.setex(
         cacheKey,
         CACHE_TTL.VENUE_DETAIL,
         JSON.stringify(result)
       );

       logger.debug({ urlName, includeDetails }, 'Venue retrieved');

       return result;
     }

     private formatVenueListItem(venue: any) {
       return {
         id: venue.id,
         urlName: venue.urlName,
         name: venue.name,
         address: venue.address,
         city: venue.city,
         state: venue.state,
         postalCode: venue.postalCode,
         country: venue.country,
         phoneNumber: venue.phoneNumber,
         website: venue.website,
         acceptingRequests: venue.acceptingRequests,
         location: null,
       };
     }

     private formatVenueDetail(venue: any, stats: any) {
       const branding = venue.customerProfile.brandedApps[0]?.brandingProfile;

       return {
         ...this.formatVenueListItem(venue),
         openkjVenueId: venue.openkjVenueId,
         systems:
           venue.systems?.map((s: any) => ({
             id: s.id,
             name: s.name,
             openkjSystemId: s.openkjSystemId,
           })) || [],
         branding: branding
           ? {
               logoUrl: branding.logoUrl,
               colorPalette: branding.colorPalette,
               poweredBySingr: branding.poweredBySingr,
             }
           : null,
         stats,
       };
     }

     async invalidateVenueCache(urlName: string) {
       const keys = await this.redis.keys(`venue:${urlName}:*`);
       if (keys.length > 0) {
         await this.redis.del(...keys);
       }

       const listKeys = await this.redis.keys('venues:list:*');
       if (listKeys.length > 0) {
         await this.redis.del(...listKeys);
       }

       logger.debug({ urlName }, 'Venue cache invalidated');
     }
   }
   ```

3. **Implement venue routes in `apps/api/src/routes/public/venues.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateQuery, validateParams } from '@singr/shared/validation';
   import {
     VenueListQuerySchema,
     VenueNearbyQuerySchema,
     VenueParamsSchema,
   } from './schemas';
   import { VenueService } from '@singr/shared/services/venue-service';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:public:venues');

   export const venuesRoute: FastifyPluginAsync = async (server) => {
     const venueService = new VenueService(server.prisma, server.redis);

     // List venues
     server.get(
       '/venues',
       {
         schema: {
           tags: ['public'],
           summary: 'List all venues',
           description: 'Get paginated list of venues with optional filters',
           querystring: {
             type: 'object',
             properties: {
               page: { type: 'integer', minimum: 1, default: 1 },
               limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
               city: { type: 'string' },
               state: { type: 'string' },
               country: { type: 'string' },
               acceptingRequests: { type: 'boolean' },
               search: { type: 'string' },
               sort: { type: 'string', enum: ['name', 'city', 'distance', 'created'] },
               order: { type: 'string', enum: ['asc', 'desc'] },
             },
           },
           response: {
             200: {
               description: 'List of venues',
               type: 'object',
               properties: {
                 data: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       id: { type: 'string', format: 'uuid' },
                       name: { type: 'string' },
                       city: { type: 'string' },
                       state: { type: 'string' },
                       acceptingRequests: { type: 'boolean' },
                     },
                   },
                 },
                 pagination: {
                   type: 'object',
                   properties: {
                     page: { type: 'integer' },
                     limit: { type: 'integer' },
                     total: { type: 'integer' },
                     totalPages: { type: 'integer' },
                   },
                 },
               },
             },
           },
         },
         preHandler: [validateQuery(VenueListQuerySchema)],
         config: {
           rateLimit: {
             max: 60,
             timeWindow: '1 minute',
           },
         },
       },
       async (request, reply) => {
         const query = request.query as z.infer<typeof VenueListQuerySchema>;

         const { page, limit, sort, order, ...filters } = query;

         const result = await venueService.listVenues(filters, {
           page,
           limit,
           sort,
           order,
         });

         return reply.send(result);
       }
     );

     // Find nearby venues
     server.get(
       '/venues/nearby',
       {
         schema: {
           tags: ['public'],
           summary: 'Find nearby venues',
           description: 'Get venues within specified radius using PostGIS',
           querystring: {
             type: 'object',
             required: ['lat', 'lng'],
             properties: {
               lat: { type: 'number', minimum: -90, maximum: 90 },
               lng: { type: 'number', minimum: -180, maximum: 180 },
               radius: { type: 'number', minimum: 1, maximum: 100, default: 25 },
               limit: { type: 'integer', minimum: 1, maximum: 50, default: 20 },
               acceptingRequests: { type: 'boolean' },
             },
           },
           response: {
             200: {
               description: 'Nearby venues',
               type: 'object',
               properties: {
                 data: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       id: { type: 'string', format: 'uuid' },
                       name: { type: 'string' },
                       distance: { type: 'number' },
                       acceptingRequests: { type: 'boolean' },
                     },
                   },
                 },
                 query: {
                   type: 'object',
                   properties: {
                     lat: { type: 'number' },
                     lng: { type: 'number' },
                     radius: { type: 'number' },
                   },
                 },
               },
             },
           },
         },
         preHandler: [validateQuery(VenueNearbyQuerySchema)],
         config: {
           rateLimit: {
             max: 60,
             timeWindow: '1 minute',
           },
         },
       },
       async (request, reply) => {
         const query = request.query as z.infer<typeof VenueNearbyQuerySchema>;

         const venues = await venueService.findNearbyVenues(query);

         return reply.send({
           data: venues,
           query: {
             lat: query.lat,
             lng: query.lng,
             radius: query.radius,
           },
         });
       }
     );

     // Get venue details
     server.get(
       '/venues/:urlName',
       {
         schema: {
           tags: ['public'],
           summary: 'Get venue details',
           description: 'Get detailed information about a specific venue',
           params: {
             type: 'object',
             properties: {
               urlName: { type: 'string' },
             },
           },
           response: {
             200: {
               description: 'Venue details',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 name: { type: 'string' },
                 address: { type: 'string' },
                 city: { type: 'string' },
                 state: { type: 'string' },
                 acceptingRequests: { type: 'boolean' },
                 systems: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       id: { type: 'string', format: 'uuid' },
                       name: { type: 'string' },
                     },
                   },
                 },
                 stats: {
                   type: 'object',
                   properties: {
                     totalSongs: { type: 'integer' },
                     requestsToday: { type: 'integer' },
                   },
                 },
               },
             },
             404: {
               description: 'Venue not found',
             },
           },
         },
         preHandler: [validateParams(VenueParamsSchema)],
         config: {
           rateLimit: {
             max: 60,
             timeWindow: '1 minute',
           },
         },
       },
       async (request, reply) => {
         const { urlName } = request.params as z.infer<typeof VenueParamsSchema>;

         const venue = await venueService.getVenueByUrlName(urlName, true);

         if (!venue) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Venue Not Found',
             detail: `No venue found with URL name: ${urlName}`,
           });
         }

         return reply.send(venue);
       }
     );
   };
   ```

**Deliverables:**
- ✅ `GET /v1/public/venues` - Paginated venue listing with filters
- ✅ `GET /v1/public/venues/nearby` - PostGIS proximity search
- ✅ `GET /v1/public/venues/:urlName` - Detailed venue information
- ✅ Redis caching (5-10 min TTL)
- ✅ Rate limiting (60 req/min per IP)
- ✅ Distance calculation in miles
- ✅ Search by name, filter by location/status

---

### 5.2 Song Database Search

**Objective:** Allow users to search venue songbooks.

**Duration:** 2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create song search schemas:**
   ```typescript
   // Add to apps/api/src/routes/public/schemas.ts
   export const SongSearchQuerySchema = z.object({
     q: z.string().min(1).max(200),
     venueId: z.string().uuid().optional(),
     systemId: z.string().uuid().optional(),
     page: z.coerce.number().int().min(1).default(1),
     limit: z.coerce.number().int().min(1).max(100).default(20),
     sortBy: z.enum(['relevance', 'artist', 'title']).default('relevance'),
   });

   export const SongSearchResultSchema = z.object({
     id: z.number(),
     artist: z.string(),
     title: z.string(),
     combined: z.string(),
     systemId: z.string().uuid().optional(),
     systemName: z.string().optional(),
     venueId: z.string().uuid().optional(),
     venueName: z.string().optional(),
   });

   export const VenueSongsQuerySchema = PaginationSchema.extend({
     artist: z.string().max(100).optional(),
     letter: z.string().length(1).optional(),
     systemId: z.string().uuid().optional(),
   });
   ```

2. **Implement song service in `packages/shared/src/services/song-service.ts`:**
   ```typescript
   import { PrismaClient } from '@prisma/database';
   import { Redis } from 'ioredis';
   import { CACHE_TTL } from '@singr/config';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('services:song');

   export interface SongSearchParams {
     query: string;
     venueId?: string;
     systemId?: string;
     page: number;
     limit: number;
     sortBy: 'relevance' | 'artist' | 'title';
   }

   export class SongService {
     constructor(
       private prisma: PrismaClient,
       private redis: Redis
     ) {}

     async searchSongs(params: SongSearchParams) {
       const cacheKey = `songs:search:${JSON.stringify(params)}`;
       const cached = await this.redis.get(cacheKey);

       if (cached) {
         logger.debug('Song search cache hit');
         return JSON.parse(cached);
       }

       const where: any = {};

       if (params.venueId) {
         const venue = await this.prisma.venue.findUnique({
           where: { id: params.venueId },
           select: { customerProfileId: true },
         });

         if (venue) {
           where.customerProfileId = venue.customerProfileId;
         }
       }

       if (params.systemId) {
         const system = await this.prisma.system.findUnique({
           where: { id: params.systemId },
           select: { openkjSystemId: true, customerProfileId: true },
         });

         if (system) {
           where.openkjSystemId = system.openkjSystemId;
           where.customerProfileId = system.customerProfileId;
         }
       }

       const searchTerms = params.query
         .toLowerCase()
         .split(/\s+/)
         .filter(Boolean);

       where.OR = searchTerms.flatMap((term) => [
         { artist: { contains: term, mode: 'insensitive' } },
         { title: { contains: term, mode: 'insensitive' } },
         { normalizedCombined: { contains: term, mode: 'insensitive' } },
       ]);

       let orderBy: any = { artist: 'asc' };
       if (params.sortBy === 'title') {
         orderBy = { title: 'asc' };
       }

       const [songs, total] = await Promise.all([
         this.prisma.songDb.findMany({
           where,
           skip: (params.page - 1) * params.limit,
           take: params.limit,
           orderBy,
           include: {
             customerProfile: {
               include: {
                 venues: {
                   take: 1,
                 },
               },
             },
           },
         }),
         this.prisma.songDb.count({ where }),
       ]);

       const systemIds = [...new Set(songs.map((s) => s.openkjSystemId))];
       const systems = await this.prisma.system.findMany({
         where: {
           openkjSystemId: { in: systemIds },
         },
         select: {
           openkjSystemId: true,
           name: true,
           id: true,
         },
       });

       const systemMap = new Map(
         systems.map((s) => [s.openkjSystemId, { id: s.id, name: s.name }])
       );

       const result = {
         data: songs.map((song) => {
           const system = systemMap.get(song.openkjSystemId);
           const venue = song.customerProfile.venues[0];

           return {
             id: Number(song.id),
             artist: song.artist,
             title: song.title,
             combined: song.combined,
             systemId: system?.id,
             systemName: system?.name,
             venueId: venue?.id,
             venueName: venue?.name,
           };
         }),
         pagination: {
           page: params.page,
           limit: params.limit,
           total,
           totalPages: Math.ceil(total / params.limit),
         },
         query: params.query,
       };

       await this.redis.setex(
         cacheKey,
         CACHE_TTL.SONGDB_SEARCH,
         JSON.stringify(result)
       );

       logger.debug({ query: params.query, count: songs.length, total }, 'Songs searched');

       return result;
     }
   }
   ```

3. **Implement song routes in `apps/api/src/routes/public/songs.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateQuery, validateParams } from '@singr/shared/validation';
   import { SongSearchQuerySchema, VenueSongsQuerySchema, VenueParamsSchema } from './schemas';
   import { SongService } from '@singr/shared/services/song-service';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:public:songs');

   export const songsRoute: FastifyPluginAsync = async (server) => {
     const songService = new SongService(server.prisma, server.redis);

     // Search songs
     server.get(
       '/songs/search',
       {
         schema: {
           tags: ['public'],
           summary: 'Search songs',
           description: 'Search for songs across all venues or within specific venue/system',
           querystring: {
             type: 'object',
             required: ['q'],
             properties: {
               q: { type: 'string', minLength: 1, maxLength: 200 },
               venueId: { type: 'string', format: 'uuid' },
               systemId: { type: 'string', format: 'uuid' },
               page: { type: 'integer', minimum: 1, default: 1 },
               limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
               sortBy: { type: 'string', enum: ['relevance', 'artist', 'title'] },
             },
           },
           response: {
             200: {
               description: 'Search results',
               type: 'object',
               properties: {
                 data: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       id: { type: 'integer' },
                       artist: { type: 'string' },
                       title: { type: 'string' },
                       combined: { type: 'string' },
                     },
                   },
                 },
                 pagination: {
                   type: 'object',
                   properties: {
                     page: { type: 'integer' },
                     limit: { type: 'integer' },
                     total: { type: 'integer' },
                     totalPages: { type: 'integer' },
                   },
                 },
               },
             },
           },
         },
         preHandler: [validateQuery(SongSearchQuerySchema)],
         config: {
           rateLimit: {
             max: 60,
             timeWindow: '1 minute',
           },
         },
       },
       async (request, reply) => {
         const query = request.query as z.infer<typeof SongSearchQuerySchema>;

         const result = await songService.searchSongs({
           query: query.q,
           venueId: query.venueId,
           systemId: query.systemId,
           page: query.page,
           limit: query.limit,
           sortBy: query.sortBy,
         });

         return reply.send(result);
       }
     );

     // Browse venue songs
     server.get(
       '/venues/:urlName/songs',
       {
         schema: {
           tags: ['public'],
           summary: 'Browse venue songs',
           description: 'Get paginated list of songs available at a venue',
           params: {
             type: 'object',
             properties: {
               urlName: { type: 'string' },
             },
           },
           querystring: {
             type: 'object',
             properties: {
               page: { type: 'integer', minimum: 1, default: 1 },
               limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
               artist: { type: 'string' },
               letter: { type: 'string', minLength: 1, maxLength: 1 },
               systemId: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'Venue songs',
               type: 'object',
               properties: {
                 venue: {
                   type: 'object',
                   properties: {
                     id: { type: 'string', format: 'uuid' },
                     name: { type: 'string' },
                   },
                 },
                 data: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       id: { type: 'integer' },
                       artist: { type: 'string' },
                       title: { type: 'string' },
                     },
                   },
                 },
                 availableLetters: {
                   type: 'array',
                   items: { type: 'string' },
                 },
               },
             },
           },
         },
         preHandler: [validateParams(VenueParamsSchema), validateQuery(VenueSongsQuerySchema)],
         config: {
           rateLimit: {
             max: 60,
             timeWindow: '1 minute',
           },
         },
       },
       async (request, reply) => {
         const { urlName } = request.params as z.infer<typeof VenueParamsSchema>;
         const query = request.query as z.infer<typeof VenueSongsQuerySchema>;

         const venue = await server.prisma.venue.findUnique({
           where: { urlName },
           select: {
             id: true,
             name: true,
             customerProfileId: true,
           },
         });

         if (!venue) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Venue Not Found',
             detail: 'Venue not found',
           });
         }

         const where: any = {
           customerProfileId: venue.customerProfileId,
         };

         if (query.artist) {
           where.artist = { contains: query.artist, mode: 'insensitive' };
         }

         if (query.letter) {
           where.artist = {
             ...where.artist,
             startsWith: query.letter.toUpperCase(),
           };
         }

         if (query.systemId) {
           const system = await server.prisma.system.findUnique({
             where: { id: query.systemId },
             select: { openkjSystemId: true },
           });

           if (system) {
             where.openkjSystemId = system.openkjSystemId;
           }
         }

         const [songs, total] = await Promise.all([
           server.prisma.songDb.findMany({
             where,
             skip: (query.page - 1) * query.limit,
             take: query.limit,
             orderBy: [{ artist: 'asc' }, { title: 'asc' }],
           }),
           server.prisma.songDb.count({ where }),
         ]);

         const availableLetters = await server.prisma.$queryRaw<
           Array<{ letter: string }>
         >`
           SELECT DISTINCT UPPER(LEFT(artist, 1)) as letter
           FROM songdb
           WHERE customer_profiles_id = ${venue.customerProfileId}::uuid
           ORDER BY letter
         `;

         return reply.send({
           venue: {
             id: venue.id,
             name: venue.name,
           },
           data: songs.map((s) => ({
             id: Number(s.id),
             artist: s.artist,
             title: s.title,
             combined: s.combined,
           })),
           pagination: {
             page: query.page,
             limit: query.limit,
             total,
             totalPages: Math.ceil(total / query.limit),
           },
           availableLetters: availableLetters.map((l) => l.letter),
         });
       }
     );
   };
   ```

**Deliverables:**
- ✅ `GET /v1/public/songs/search` - Full-text song search
- ✅ `GET /v1/public/venues/:urlName/songs` - Browse venue songbook
- ✅ Search by artist, title, or combined
- ✅ Filter by venue or system
- ✅ Alphabet navigation support
- ✅ Redis caching (5 min TTL)
- ✅ Rate limiting (60 req/min)

---

### 5.3 Guest Request Submission

**Objective:** Allow unauthenticated users to submit song requests.

**Duration:** 2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create request schemas:**
   ```typescript
   // Add to apps/api/src/routes/public/schemas.ts
   export const PublicRequestSchema = z.object({
     venueId: z.string().uuid(),
     artist: z.string().min(1).max(255),
     title: z.string().min(1).max(255),
     keyChange: z.number().int().min(-12).max(12).default(0),
     notes: z.string().max(500).optional(),
     guestName: z.string().min(1).max(100).optional(),
   });

   export const RequestResponseSchema = z.object({
     id: z.number(),
     venueId: z.string().uuid(),
     venueName: z.string(),
     artist: z.string(),
     title: z.string(),
     keyChange: z.number(),
     notes: z.string().nullable(),
     requestedAt: z.string().datetime(),
     processed: z.boolean(),
   });
   ```

2. **Implement request service in `packages/shared/src/services/request-service.ts`:**
   ```typescript
   import { PrismaClient } from '@prisma/database';
   import { Redis } from 'ioredis';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('services:request');

   export interface CreateRequestInput {
     venueId: string;
     artist: string;
     title: string;
     keyChange?: number;
     notes?: string;
     singerProfileId?: string;
     submittedByUserId?: string;
     guestName?: string;
   }

   export class RequestService {
     constructor(
       private prisma: PrismaClient,
       private redis: Redis
     ) {}

     async createRequest(input: CreateRequestInput) {
       const venue = await this.prisma.venue.findUnique({
         where: { id: input.venueId },
         select: {
           id: true,
           name: true,
           acceptingRequests: true,
           customerProfileId: true,
         },
       });

       if (!venue) {
         throw new Error('Venue not found');
       }

       if (!venue.acceptingRequests) {
         throw new Error('Venue is not currently accepting requests');
       }

       // Rate limit per venue
       const rateLimitKey = `rate:request:venue:${input.venueId}`;
       const currentCount = await this.redis.incr(rateLimitKey);

       if (currentCount === 1) {
         await this.redis.expire(rateLimitKey, 3600);
       }

       if (currentCount > 50) {
         throw new Error('Request rate limit exceeded for this venue');
       }

       // Per-user rate limit if authenticated
       if (input.singerProfileId) {
         const userRateLimitKey = `rate:request:user:${input.singerProfileId}`;
         const userCount = await this.redis.incr(userRateLimitKey);

         if (userCount === 1) {
           await this.redis.expire(userRateLimitKey, 3600);
         }

         if (userCount > 10) {
           throw new Error('You have reached your hourly request limit');
         }
       }

       const request = await this.prisma.request.create({
         data: {
           venueId: input.venueId,
           artist: input.artist,
           title: input.title,
           keyChange: input.keyChange || 0,
           notes: input.notes || null,
           singerProfileId: input.singerProfileId || null,
           submittedByUserId: input.submittedByUserId || null,
         },
         include: {
           venue: {
             select: { name: true },
           },
         },
       });

       // Add to request history if authenticated
       if (input.singerProfileId) {
         await this.createRequestHistory({
           singerProfileId: input.singerProfileId,
           venueId: input.venueId,
           artist: input.artist,
           title: input.title,
           keyChange: input.keyChange || 0,
         });
       }

       logger.info(
         {
           requestId: request.id,
           venueId: input.venueId,
           singerProfileId: input.singerProfileId,
           guestName: input.guestName,
         },
         'Song request created'
       );

       return {
         id: Number(request.id),
         venueId: request.venueId,
         venueName: request.venue.name,
         artist: request.artist,
         title: request.title,
         keyChange: request.keyChange,
         notes: request.notes,
         requestedAt: request.requestedAt.toISOString(),
         processed: request.processed,
       };
     }

     private async createRequestHistory(input: {
       singerProfileId: string;
       venueId: string;
       artist: string;
       title: string;
       keyChange: number;
     }) {
       const songFingerprint = `${input.artist.toLowerCase()}:${input.title.toLowerCase()}`;

       await this.prisma.singerRequestHistory.create({
         data: {
           singerProfileId: input.singerProfileId,
           venueId: input.venueId,
           artist: input.artist,
           title: input.title,
           keyChange: input.keyChange,
           songFingerprint,
         },
       });
     }
   }
   ```

3. **Implement request route in `apps/api/src/routes/public/requests.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateBody } from '@singr/shared/validation';
   import { PublicRequestSchema } from './schemas';
   import { RequestService } from '@singr/shared/services/request-service';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:public:requests');

   export const requestsRoute: FastifyPluginAsync = async (server) => {
     const requestService = new RequestService(server.prisma, server.redis);

     server.post(
       '/requests',
       {
         schema: {
           tags: ['public'],
           summary: 'Submit song request',
           description: 'Submit a song request to a venue (authentication optional)',
           body: {
             type: 'object',
             required: ['venueId', 'artist', 'title'],
             properties: {
               venueId: { type: 'string', format: 'uuid' },
               artist: { type: 'string', minLength: 1, maxLength: 255 },
               title: { type: 'string', minLength: 1, maxLength: 255 },
               keyChange: { type: 'integer', minimum: -12, maximum: 12, default: 0 },
               notes: { type: 'string', maxLength: 500 },
               guestName: { type: 'string', minLength: 1, maxLength: 100 },
             },
           },
           response: {
             201: {
               description: 'Request created',
               type: 'object',
               properties: {
                 id: { type: 'integer' },
                 venueId: { type: 'string', format: 'uuid' },
                 venueName: { type: 'string' },
                 artist: { type: 'string' },
                 title: { type: 'string' },
                 requestedAt: { type: 'string', format: 'date-time' },
               },
             },
             404: {
               description: 'Venue not found',
             },
             422: {
               description: 'Venue not accepting requests',
             },
             429: {
               description: 'Rate limit exceeded',
             },
           },
         },
         preHandler: [validateBody(PublicRequestSchema)],
         config: {
           rateLimit: {
             max: 10,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const body = request.body as z.infer<typeof PublicRequestSchema>;

         try {
           const result = await requestService.createRequest({
             venueId: body.venueId,
             artist: body.artist,
             title: body.title,
             keyChange: body.keyChange,
             notes: body.notes,
             guestName: body.guestName,
           });

           return reply.code(201).send(result);
         } catch (error) {
           if (error instanceof Error) {
             if (error.message.includes('not found')) {
               return reply.code(404).send({
                 type: 'resource_not_found',
                 title: 'Venue Not Found',
                 detail: error.message,
               });
             }

             if (error.message.includes('rate limit')) {
               return reply.code(429).send({
                 type: 'rate_limited',
                 title: 'Too Many Requests',
                 detail: error.message,
               });
             }

             if (error.message.includes('not accepting')) {
               return reply.code(422).send({
                 type: 'unprocessable_entity',
                 title: 'Requests Not Accepted',
                 detail: error.message,
               });
             }
           }

           throw error;
         }
       }
     );
   };
   ```

4. **Register all public routes in `apps/api/src/routes/public/index.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { venuesRoute } from './venues';
   import { songsRoute } from './songs';
   import { requestsRoute } from './requests';

   export const publicRoutes: FastifyPluginAsync = async (server) => {
     await server.register(venuesRoute);
     await server.register(songsRoute);
     await server.register(requestsRoute);
   };
   ```

**Deliverables:**
- ✅ `POST /v1/public/requests` - Anonymous request submission
- ✅ Venue validation and accepting_requests check
- ✅ Rate limiting: 10 req/hour per IP, 50 req/hour per venue
- ✅ Request history tracking for authenticated users
- ✅ Guest name capture for anonymous users
- ✅ Proper error handling with Problem+JSON

---

---

## Phase 6: Singer Account & Profile Management

### 6.1 Singer Profile Management

**Objective:** Allow singers to view and update their profiles.

**Duration:** 2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create singer profile schemas in `apps/api/src/routes/singer/schemas.ts`:**
   ```typescript
   import { z } from 'zod';
   import { PaginationSchema, EmailSchema, PasswordSchema } from '@singr/shared/validation';

   export const SingerProfileSchema = z.object({
     id: z.string().uuid(),
     userId: z.string().uuid(),
     nickname: z.string().nullable(),
     avatarUrl: z.string().url().nullable(),
     email: z.string().email(),
     name: z.string().nullable(),
     phoneNumber: z.string().nullable(),
     preferences: z.record(z.any()),
     createdAt: z.string().datetime(),
   });

   export const UpdateSingerProfileSchema = z.object({
     nickname: z.string().min(1).max(100).optional(),
     name: z.string().min(1).max(255).optional(),
     phoneNumber: z.string().max(20).optional(),
     preferences: z.record(z.any()).optional(),
   });

   export const SingerRequestSchema = z.object({
     venueId: z.string().uuid(),
     artist: z.string().min(1).max(255),
     title: z.string().min(1).max(255),
     keyChange: z.number().int().min(-12).max(12).default(0),
     notes: z.string().max(500).optional(),
   });

   export const RequestParamsSchema = z.object({
     id: z.coerce.number().int().positive(),
   });

   export const SingerRequestResponseSchema = z.object({
     id: z.number(),
     venueId: z.string().uuid(),
     venueName: z.string(),
     venueUrlName: z.string(),
     artist: z.string(),
     title: z.string(),
     keyChange: z.number(),
     notes: z.string().nullable(),
     requestedAt: z.string().datetime(),
     processed: z.boolean(),
     processedAt: z.string().datetime().nullable(),
   });

   export const UpdateEmailSchema = z.object({
     newEmail: EmailSchema,
     password: z.string().min(1),
   });

   export const ChangePasswordSchema = z.object({
     currentPassword: z.string().min(1),
     newPassword: PasswordSchema,
   });

   export const UpdatePhoneNumberSchema = z.object({
     phoneNumber: z.string().regex(/^\+[1-9]\d{1,14}$/, 'Must be in E.164 format'),
     password: z.string().min(1),
   });

   export const VerifyPhoneNumberSchema = z.object({
     code: z.string().length(6, 'Code must be 6 digits'),
   });
   ```

2. **Implement profile routes in `apps/api/src/routes/singer/profile.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateBody } from '@singr/shared/validation';
   import { UpdateSingerProfileSchema } from './schemas';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:singer:profile');

   export const profileRoute: FastifyPluginAsync = async (server) => {
     // Get current profile
     server.get(
       '/profile',
       {
         schema: {
           tags: ['singer'],
           summary: 'Get singer profile',
           description: 'Retrieve current singer profile information',
           security: [{ bearerAuth: [] }],
           response: {
             200: {
               description: 'Singer profile',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 userId: { type: 'string', format: 'uuid' },
                 nickname: { type: 'string' },
                 email: { type: 'string' },
                 name: { type: 'string' },
                 phoneNumber: { type: 'string' },
                 preferences: { type: 'object' },
               },
             },
             404: {
               description: 'Profile not found',
             },
           },
         },
         preHandler: [server.authenticate],
       },
       async (request, reply) => {
         const userId = request.user.sub;

         const user = await server.prisma.user.findUnique({
           where: { id: userId },
           include: {
             singerProfile: true,
           },
         });

         if (!user?.singerProfile) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Singer Profile Not Found',
             detail: 'No singer profile exists for this user',
           });
         }

         return reply.send({
           id: user.singerProfile.id,
           userId: user.id,
           nickname: user.singerProfile.nickname,
           avatarUrl: user.singerProfile.avatarUrl,
           email: user.email,
           name: user.name,
           phoneNumber: user.phoneNumber,
           preferences: user.singerProfile.preferences,
           createdAt: user.singerProfile.createdAt.toISOString(),
         });
       }
     );

     // Update profile
     server.patch(
       '/profile',
       {
         schema: {
           tags: ['singer'],
           summary: 'Update singer profile',
           description: 'Update singer profile information',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             properties: {
               nickname: { type: 'string', minLength: 1, maxLength: 100 },
               name: { type: 'string', minLength: 1, maxLength: 255 },
               phoneNumber: { type: 'string', maxLength: 20 },
               preferences: { type: 'object' },
             },
           },
           response: {
             200: {
               description: 'Profile updated',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 nickname: { type: 'string' },
                 name: { type: 'string' },
               },
             },
           },
         },
         preHandler: [server.authenticate, validateBody(UpdateSingerProfileSchema)],
       },
       async (request, reply) => {
         const userId = request.user.sub;
         const body = request.body as z.infer<typeof UpdateSingerProfileSchema>;

         const user = await server.prisma.user.findUnique({
           where: { id: userId },
           include: { singerProfile: true },
         });

         if (!user?.singerProfile) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Singer Profile Not Found',
             detail: 'No singer profile exists for this user',
           });
         }

         // Update user fields
         const userUpdate: any = {};
         if (body.name !== undefined) userUpdate.name = body.name;
         if (body.phoneNumber !== undefined) userUpdate.phoneNumber = body.phoneNumber;

         // Update singer profile fields
         const profileUpdate: any = {};
         if (body.nickname !== undefined) profileUpdate.nickname = body.nickname;
         if (body.preferences !== undefined) {
           profileUpdate.preferences = {
             ...user.singerProfile.preferences,
             ...body.preferences,
           };
         }

         // Execute updates
         const [updatedUser, updatedProfile] = await Promise.all([
           Object.keys(userUpdate).length > 0
             ? server.prisma.user.update({
                 where: { id: userId },
                 data: userUpdate,
               })
             : Promise.resolve(user),
           Object.keys(profileUpdate).length > 0
             ? server.prisma.singerProfile.update({
                 where: { id: user.singerProfile.id },
                 data: profileUpdate,
               })
             : Promise.resolve(user.singerProfile),
         ]);

         logger.info({ userId, singerProfileId: updatedProfile.id }, 'Singer profile updated');

         return reply.send({
           id: updatedProfile.id,
           userId: updatedUser.id,
           nickname: updatedProfile.nickname,
           avatarUrl: updatedProfile.avatarUrl,
           email: updatedUser.email,
           name: updatedUser.name,
           phoneNumber: updatedUser.phoneNumber,
           preferences: updatedProfile.preferences,
           createdAt: updatedProfile.createdAt.toISOString(),
         });
       }
     );
   };
   ```

**Deliverables:**
- ✅ `GET /v1/singer/profile` - Retrieve current profile
- ✅ `PATCH /v1/singer/profile` - Update nickname, name, phone, preferences
- ✅ Authenticated access required
- ✅ Preferences stored as JSON

---

### 6.2 Authenticated Request Submission

**Objective:** Allow authenticated singers to submit requests with tracking.

**Duration:** 1-2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Implement singer request routes in `apps/api/src/routes/singer/requests.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateBody, validateParams } from '@singr/shared/validation';
   import { SingerRequestSchema, RequestParamsSchema } from './schemas';
   import { RequestService } from '@singr/shared/services/request-service';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:singer:requests');

   export const requestsRoute: FastifyPluginAsync = async (server) => {
     const requestService = new RequestService(server.prisma, server.redis);

     // Submit authenticated request
     server.post(
       '/requests',
       {
         schema: {
           tags: ['singer'],
           summary: 'Submit song request',
           description: 'Submit a song request as an authenticated singer',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['venueId', 'artist', 'title'],
             properties: {
               venueId: { type: 'string', format: 'uuid' },
               artist: { type: 'string' },
               title: { type: 'string' },
               keyChange: { type: 'integer', minimum: -12, maximum: 12, default: 0 },
               notes: { type: 'string', maxLength: 500 },
             },
           },
           response: {
             201: {
               description: 'Request created',
               type: 'object',
               properties: {
                 id: { type: 'integer' },
                 venueId: { type: 'string', format: 'uuid' },
                 venueName: { type: 'string' },
                 artist: { type: 'string' },
                 title: { type: 'string' },
               },
             },
           },
         },
         preHandler: [server.authenticate, validateBody(SingerRequestSchema)],
         config: {
           rateLimit: {
             max: 10,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const body = request.body as z.infer<typeof SingerRequestSchema>;
         const userId = request.user.sub;

         // Get singer profile
         const singerProfile = await server.prisma.singerProfile.findUnique({
           where: { userId },
         });

         if (!singerProfile) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Singer Profile Not Found',
             detail: 'No singer profile found for this user',
           });
         }

         try {
           const result = await requestService.createRequest({
             venueId: body.venueId,
             artist: body.artist,
             title: body.title,
             keyChange: body.keyChange,
             notes: body.notes,
             singerProfileId: singerProfile.id,
             submittedByUserId: userId,
           });

           return reply.code(201).send(result);
         } catch (error) {
           if (error instanceof Error) {
             if (error.message.includes('not found')) {
               return reply.code(404).send({
                 type: 'resource_not_found',
                 title: 'Venue Not Found',
                 detail: error.message,
               });
             }

             if (error.message.includes('rate limit')) {
               return reply.code(429).send({
                 type: 'rate_limited',
                 title: 'Too Many Requests',
                 detail: error.message,
               });
             }

             if (error.message.includes('not accepting')) {
               return reply.code(422).send({
                 type: 'unprocessable_entity',
                 title: 'Requests Not Accepted',
                 detail: error.message,
               });
             }
           }

           throw error;
         }
       }
     );

     // Get specific request
     server.get(
       '/requests/:id',
       {
         schema: {
           tags: ['singer'],
           summary: 'Get request details',
           description: 'Retrieve details of a specific request',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'integer' },
             },
           },
           response: {
             200: {
               description: 'Request details',
               type: 'object',
               properties: {
                 id: { type: 'integer' },
                 venueId: { type: 'string', format: 'uuid' },
                 venueName: { type: 'string' },
                 artist: { type: 'string' },
                 title: { type: 'string' },
                 keyChange: { type: 'integer' },
                 processed: { type: 'boolean' },
               },
             },
             404: {
               description: 'Request not found',
             },
           },
         },
         preHandler: [server.authenticate, validateParams(RequestParamsSchema)],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof RequestParamsSchema>;
         const userId = request.user.sub;

         const requestRecord = await server.prisma.request.findFirst({
           where: {
             id: BigInt(id),
             submittedByUserId: userId,
           },
           include: {
             venue: {
               select: {
                 id: true,
                 name: true,
                 urlName: true,
               },
             },
           },
         });

         if (!requestRecord) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Request Not Found',
             detail: 'Request not found or access denied',
           });
         }

         return reply.send({
           id: Number(requestRecord.id),
           venueId: requestRecord.venueId,
           venueName: requestRecord.venue.name,
           venueUrlName: requestRecord.venue.urlName,
           artist: requestRecord.artist,
           title: requestRecord.title,
           keyChange: requestRecord.keyChange,
           notes: requestRecord.notes,
           requestedAt: requestRecord.requestedAt.toISOString(),
           processed: requestRecord.processed,
           processedAt: requestRecord.processedAt?.toISOString() || null,
         });
       }
     );
   };
   ```

**Deliverables:**
- ✅ `POST /v1/singer/requests` - Authenticated request submission
- ✅ `GET /v1/singer/requests/:id` - View specific request
- ✅ Automatic request history tracking
- ✅ User-specific rate limiting (10 req/hour)
- ✅ Authorization: users can only view their own requests

---

### 6.3 Singer Account Management

**Objective:** Allow singers to update email, change password, and manage account with email/SMS verification.

**Duration:** 2-3 days  
**Team Size:** 1 developer

**Tasks:**

1. **Implement account management routes in `apps/api/src/routes/singer/account.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateBody } from '@singr/shared/validation';
   import {
     UpdateEmailSchema,
     ChangePasswordSchema,
     UpdatePhoneNumberSchema,
     VerifyPhoneNumberSchema,
   } from './schemas';
   import { verifyPassword, hashPassword, RefreshTokenService } from '@singr/auth';
   import { randomUUID } from 'crypto';
   import { createLogger } from '@singr/observability';
   import { createCommunicationQueue } from '@singr/shared/queues/communication-queue';
   import { SMSService } from '@singr/shared/services/sms/sms-service';
   import { config, TOKEN_EXPIRY } from '@singr/config';

   const logger = createLogger('routes:singer:account');

   export const accountRoute: FastifyPluginAsync = async (server) => {
     const communicationQueue = createCommunicationQueue(server.redis);
     const smsService = new SMSService();

     // Update email
     server.patch(
       '/account/email',
       {
         schema: {
           tags: ['singer'],
           summary: 'Update email',
           description: 'Change email address (requires password confirmation)',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['newEmail', 'password'],
             properties: {
               newEmail: { type: 'string', format: 'email' },
               password: { type: 'string' },
             },
           },
           response: {
             200: {
               description: 'Email updated',
               type: 'object',
               properties: {
                 email: { type: 'string' },
                 isEmailVerified: { type: 'boolean' },
                 message: { type: 'string' },
               },
             },
             401: {
               description: 'Invalid password',
             },
             409: {
               description: 'Email already exists',
             },
           },
         },
         preHandler: [server.authenticate, validateBody(UpdateEmailSchema)],
         config: {
           rateLimit: {
             max: 5,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const { newEmail, password } = request.body as z.infer<
           typeof UpdateEmailSchema
         >;
         const userId = request.user.sub;

         // Get user
         const user = await server.prisma.user.findUnique({
           where: { id: userId },
         });

         if (!user || !user.passwordHash) {
           return reply.code(401).send({
             type: 'authentication_failed',
             title: 'Authentication Failed',
             detail: 'Invalid credentials',
           });
         }

         // Verify password
         const validPassword = await verifyPassword(user.passwordHash, password);
         if (!validPassword) {
           logger.warn({ userId }, 'Email update failed - invalid password');
           return reply.code(401).send({
             type: 'authentication_failed',
             title: 'Authentication Failed',
             detail: 'Current password is incorrect',
           });
         }

         // Check if new email already exists
         const existingUser = await server.prisma.user.findUnique({
           where: { email: newEmail.toLowerCase() },
         });

         if (existingUser) {
           return reply.code(409).send({
             type: 'conflict',
             title: 'Email Already Exists',
             detail: 'This email is already registered',
           });
         }

         // Update email and mark as unverified
         const updatedUser = await server.prisma.user.update({
           where: { id: userId },
           data: {
             email: newEmail.toLowerCase(),
             isEmailVerified: false,
           },
         });

         // Create verification token
         const verificationToken = randomUUID();
         await server.prisma.verificationToken.create({
           data: {
             identifier: newEmail.toLowerCase(),
             token: verificationToken,
             expiresAt: new Date(Date.now() + TOKEN_EXPIRY.EMAIL_VERIFICATION),
           },
         });

         // Enqueue verification email
         await communicationQueue.add('email', {
           type: 'email',
           to: newEmail,
           toName: user.name || undefined,
           subject: 'Verify your new email address',
           templateId: config.MAILJET_TEMPLATE_VERIFICATION,
           variables: {
             user_name: user.name || newEmail.split('@')[0],
             verification_link: `${config.APP_URL_WEB}/verify-email?token=${verificationToken}`,
             verification_code: verificationToken.substring(0, 6).toUpperCase(),
             expiry_hours: Math.floor(TOKEN_EXPIRY.EMAIL_VERIFICATION / (1000 * 60 * 60)),
           },
         });

         // Send notification to old email
         await communicationQueue.add('email', {
           type: 'email',
           to: user.email,
           toName: user.name || undefined,
           subject: 'Your Singr email has been changed',
           htmlPart: `
             <h2>Email Address Changed</h2>
             <p>Hello ${user.name || 'there'},</p>
             <p>Your Singr email address has been changed to: <strong>${newEmail}</strong></p>
             <p>If you did not make this change, please contact support immediately.</p>
           `,
           textPart: `Your Singr email address has been changed to: ${newEmail}. If you did not make this change, please contact support immediately.`,
         });

         logger.info({ userId, oldEmail: user.email, newEmail }, 'Email updated');

         return reply.send({
           email: updatedUser.email,
           isEmailVerified: updatedUser.isEmailVerified,
           message: 'Email updated. Please check your inbox to verify.',
         });
       }
     );

     // Change password
     server.post(
       '/account/password',
       {
         schema: {
           tags: ['singer'],
           summary: 'Change password',
           description: 'Change account password (revokes all sessions)',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['currentPassword', 'newPassword'],
             properties: {
               currentPassword: { type: 'string' },
               newPassword: { type: 'string', minLength: 8 },
             },
           },
           response: {
             200: {
               description: 'Password changed',
               type: 'object',
               properties: {
                 message: { type: 'string' },
               },
             },
             401: {
               description: 'Invalid password',
             },
           },
         },
         preHandler: [server.authenticate, validateBody(ChangePasswordSchema)],
         config: {
           rateLimit: {
             max: 5,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const { currentPassword, newPassword } = request.body as z.infer<
           typeof ChangePasswordSchema
         >;
         const userId = request.user.sub;

         // Get user
         const user = await server.prisma.user.findUnique({
           where: { id: userId },
         });

         if (!user || !user.passwordHash) {
           return reply.code(401).send({
             type: 'authentication_failed',
             title: 'Authentication Failed',
             detail: 'Invalid credentials',
           });
         }

         // Verify current password
         const validPassword = await verifyPassword(user.passwordHash, currentPassword);

         if (!validPassword) {
           logger.warn({ userId }, 'Password change failed - invalid password');
           return reply.code(401).send({
             type: 'authentication_failed',
             title: 'Authentication Failed',
             detail: 'Current password is incorrect',
           });
         }

         // Hash new password
         const newPasswordHash = await hashPassword(newPassword);

         // Update password
         await server.prisma.user.update({
           where: { id: userId },
           data: {
             passwordHash: newPasswordHash,
             passwordAlgo: 'argon2id',
           },
         });

         // Revoke all existing sessions
         const refreshTokenService = new RefreshTokenService(server.redis);
         await refreshTokenService.revoke(userId);
         await refreshTokenService.revokeJTI(request.user.jti);

         // Send confirmation email
         await communicationQueue.add('email', {
           type: 'email',
           to: user.email,
           toName: user.name || undefined,
           subject: 'Your Singr password has been changed',
           htmlPart: `
             <h2>Password Changed</h2>
             <p>Hello ${user.name || 'there'},</p>
             <p>Your Singr password has been successfully changed.</p>
             <p>If you did not make this change, please contact support immediately.</p>
             <p><a href="${config.APP_URL_WEB}/signin">Sign in to your account</a></p>
           `,
           textPart: `Your Singr password has been successfully changed. If you did not make this change, please contact support immediately.`,
         });

         logger.info({ userId }, 'Password changed');

         return reply.send({
           message: 'Password changed successfully. Please sign in again.',
         });
       }
     );

     // Update phone number (initiates SMS verification)
     server.patch(
       '/account/phone',
       {
         schema: {
           tags: ['singer'],
           summary: 'Update phone number',
           description: 'Change phone number and initiate SMS verification',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['phoneNumber', 'password'],
             properties: {
               phoneNumber: { type: 'string', pattern: '^\\+[1-9]\\d{1,14}$' },
               password: { type: 'string' },
             },
           },
           response: {
             200: {
               description: 'Verification code sent',
               type: 'object',
               properties: {
                 message: { type: 'string' },
                 phoneNumber: { type: 'string' },
               },
             },
           },
         },
         preHandler: [server.authenticate, validateBody(UpdatePhoneNumberSchema)],
         config: {
           rateLimit: {
             max: 5,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const { phoneNumber, password } = request.body as z.infer<
           typeof UpdatePhoneNumberSchema
         >;
         const userId = request.user.sub;

         // Get user
         const user = await server.prisma.user.findUnique({
           where: { id: userId },
         });

         if (!user || !user.passwordHash) {
           return reply.code(401).send({
             type: 'authentication_failed',
             title: 'Authentication Failed',
             detail: 'Invalid credentials',
           });
         }

         // Verify password
         const validPassword = await verifyPassword(user.passwordHash, password);
         if (!validPassword) {
           logger.warn({ userId }, 'Phone update failed - invalid password');
           return reply.code(401).send({
             type: 'authentication_failed',
             title: 'Authentication Failed',
             detail: 'Password is incorrect',
           });
         }

         // Generate verification code
         const verificationCode = smsService.generateVerificationCode();

         // Store pending phone number and code in Redis (5 minutes TTL)
         await server.redis.setex(
           `phone_verification:${userId}`,
           300,
           JSON.stringify({
             phoneNumber,
             code: verificationCode,
             attempts: 0,
           })
         );

         // Send SMS verification code
         await communicationQueue.add('sms', {
           type: 'sms',
           to: phoneNumber,
           body: `Your Singr verification code is: ${verificationCode}. Valid for 5 minutes.`,
         });

         logger.info({ userId, phoneNumber }, 'Phone verification code sent');

         return reply.send({
           message: 'Verification code sent to your phone',
           phoneNumber,
         });
       }
     );

     // Verify phone number
     server.post(
       '/account/phone/verify',
       {
         schema: {
           tags: ['singer'],
           summary: 'Verify phone number',
           description: 'Complete phone number verification with SMS code',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['code'],
             properties: {
               code: { type: 'string', minLength: 6, maxLength: 6 },
             },
           },
           response: {
             200: {
               description: 'Phone verified',
               type: 'object',
               properties: {
                 phoneNumber: { type: 'string' },
                 message: { type: 'string' },
               },
             },
             400: {
               description: 'Invalid or expired code',
             },
           },
         },
         preHandler: [server.authenticate, validateBody(VerifyPhoneNumberSchema)],
         config: {
           rateLimit: {
             max: 10,
             timeWindow: '15 minutes',
           },
         },
       },
       async (request, reply) => {
         const { code } = request.body as z.infer<typeof VerifyPhoneNumberSchema>;
         const userId = request.user.sub;

         // Get pending verification from Redis
         const pendingData = await server.redis.get(`phone_verification:${userId}`);

         if (!pendingData) {
           return reply.code(400).send({
             type: 'invalid_code',
             title: 'Invalid or Expired Code',
             detail: 'Verification code has expired or does not exist',
           });
         }

         const pending = JSON.parse(pendingData);

         // Check attempt count
         if (pending.attempts >= 5) {
           await server.redis.del(`phone_verification:${userId}`);
           return reply.code(429).send({
             type: 'too_many_attempts',
             title: 'Too Many Attempts',
             detail: 'Maximum verification attempts exceeded. Please request a new code.',
           });
         }

         // Verify code
         if (pending.code !== code) {
           pending.attempts++;
           await server.redis.setex(
             `phone_verification:${userId}`,
             300,
             JSON.stringify(pending)
           );

           logger.warn({ userId, attempts: pending.attempts }, 'Invalid phone verification code');

           return reply.code(400).send({
             type: 'invalid_code',
             title: 'Invalid Code',
             detail: `Verification code is incorrect. ${5 - pending.attempts} attempts remaining.`,
           });
         }

         // Update phone number
         await server.prisma.user.update({
           where: { id: userId },
           data: {
             phoneNumber: pending.phoneNumber,
           },
         });

         // Delete verification data
         await server.redis.del(`phone_verification:${userId}`);

         // Send confirmation email
         const user = await server.prisma.user.findUnique({
           where: { id: userId },
         });

         if (user) {
           await communicationQueue.add('email', {
             type: 'email',
             to: user.email,
             toName: user.name || undefined,
             subject: 'Your phone number has been verified',
             htmlPart: `
               <h2>Phone Number Verified</h2>
               <p>Hello ${user.name || 'there'},</p>
               <p>Your phone number <strong>${pending.phoneNumber}</strong> has been successfully verified.</p>
               <p>If you did not make this change, please contact support immediately.</p>
             `,
             textPart: `Your phone number ${pending.phoneNumber} has been successfully verified. If you did not make this change, please contact support immediately.`,
           });
         }

         logger.info({ userId, phoneNumber: pending.phoneNumber }, 'Phone number verified');

         return reply.send({
           phoneNumber: pending.phoneNumber,
           message: 'Phone number verified successfully',
         });
       }
     );

     // Delete account
     server.delete(
       '/account',
       {
         schema: {
           tags: ['singer'],
           summary: 'Delete account',
           description: 'Permanently delete singer account (requires password)',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['password'],
             properties: {
               password: { type: 'string' },
             },
           },
           response: {
             204: {
               description: 'Account deleted',
             },
             401: {
               description: 'Invalid password',
             },
           },
         },
         preHandler: [
           server.authenticate,
           validateBody(z.object({ password: z.string().min(1) })),
         ],
         config: {
           rateLimit: {
             max: 3,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const { password } = request.body as { password: string };
         const userId = request.user.sub;

         // Get user
         const user = await server.prisma.user.findUnique({
           where: { id: userId },
         });

         if (!user || !user.passwordHash) {
           return reply.code(401).send({
             type: 'authentication_failed',
             title: 'Authentication Failed',
             detail: 'Invalid credentials',
           });
         }

         // Verify password
         const validPassword = await verifyPassword(user.passwordHash, password);
         if (!validPassword) {
           logger.warn({ userId }, 'Account deletion failed - invalid password');
           return reply.code(401).send({
             type: 'authentication_failed',
             title: 'Authentication Failed',
             detail: 'Password is incorrect',
           });
         }

         // Send goodbye email before deletion
         await communicationQueue.add('email', {
           type: 'email',
           to: user.email,
           toName: user.name || undefined,
           subject: 'Your Singr account has been deleted',
           htmlPart: `
             <h2>Account Deleted</h2>
             <p>Hello ${user.name || 'there'},</p>
             <p>Your Singr account has been permanently deleted as requested.</p>
             <p>We're sorry to see you go. If you'd like to return, you can always create a new account.</p>
             <p>If you did not request this deletion, please contact support immediately at support@singrkaraoke.com</p>
           `,
           textPart: `Your Singr account has been permanently deleted. If you did not request this, please contact support at support@singrkaraoke.com`,
         });

         // Delete user (cascades to profiles, requests, etc.)
         await server.prisma.user.delete({
           where: { id: userId },
         });

         // Revoke sessions
         const refreshTokenService = new RefreshTokenService(server.redis);
         await refreshTokenService.revoke(userId);
         await refreshTokenService.revokeJTI(request.user.jti);

         logger.info({ userId, email: user.email }, 'Account deleted');

         return reply.code(204).send();
       }
     );
   };
   ```

2. **Register all singer routes in `apps/api/src/routes/singer/index.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { profileRoute } from './profile';
   import { requestsRoute } from './requests';
   import { accountRoute } from './account';

   export const singerRoutes: FastifyPluginAsync = async (server) => {
     await server.register(profileRoute);
     await server.register(requestsRoute);
     await server.register(accountRoute);
   };
   ```

**Deliverables:**
- ✅ `PATCH /v1/singer/account/email` - Update email with verification
- ✅ `POST /v1/singer/account/password` - Change password
- ✅ `PATCH /v1/singer/account/phone` - Update phone number (initiate SMS verification)
- ✅ `POST /v1/singer/account/phone/verify` - Verify phone with SMS code
- ✅ `DELETE /v1/singer/account` - Delete account
- ✅ Password confirmation required for all operations
- ✅ Session revocation on password change
- ✅ Email notifications for security events via Mailjet
- ✅ SMS verification for phone number changes via Twilio
- ✅ Rate limiting (5 req/hour for sensitive operations)
- ✅ Attempt tracking for SMS verification (max 5 attempts)
- ✅ Redis-based pending verification storage
- ✅ BullMQ queue integration for emails/SMS
- ✅ Comprehensive audit logging
- ✅ Goodbye email on account deletion
- ✅ Confirmation emails for all account changes
- ✅ Security notifications sent to old email addresses

---

## Phase 7: Singer History, Favorites & Personalization

### 7.1 Request History Management

**Objective:** Track and display singer's request history across all venues.

**Duration:** 2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create history schemas in `apps/api/src/routes/singer/schemas.ts`:**
   ```typescript
   // Add to existing schemas
   export const RequestHistoryQuerySchema = PaginationSchema.extend({
     venueId: z.string().uuid().optional(),
     startDate: z.string().datetime().optional(),
     endDate: z.string().datetime().optional(),
     artist: z.string().max(100).optional(),
     title: z.string().max(100).optional(),
   });

   export const RequestHistoryItemSchema = z.object({
     id: z.string().uuid(),
     venueId: z.string().uuid(),
     venueName: z.string(),
     venueUrlName: z.string(),
     artist: z.string(),
     title: z.string(),
     keyChange: z.number(),
     requestedAt: z.string().datetime(),
     requestCount: z.number(),
   });

   export const RequestStatsSchema = z.object({
     totalRequests: z.number(),
     uniqueSongs: z.number(),
     uniqueVenues: z.number(),
     mostRequestedSong: z.object({
       artist: z.string(),
       title: z.string(),
       count: z.number(),
     }).nullable(),
     favoriteVenue: z.object({
       id: z.string().uuid(),
       name: z.string(),
       requestCount: z.number(),
     }).nullable(),
   });
   ```

2. **Create history service in `packages/shared/src/services/singer-history-service.ts`:**
   ```typescript
   import { PrismaClient } from '@prisma/database';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('services:singer-history');

   export interface HistoryFilters {
     venueId?: string;
     startDate?: Date;
     endDate?: Date;
     artist?: string;
     title?: string;
   }

   export class SingerHistoryService {
     constructor(private prisma: PrismaClient) {}

     async getRequestHistory(
       singerProfileId: string,
       filters: HistoryFilters,
       pagination: { page: number; limit: number }
     ) {
       const where: any = { singerProfileId };

       if (filters.venueId) {
         where.venueId = filters.venueId;
       }

       if (filters.startDate) {
         where.requestedAt = { gte: filters.startDate };
       }

       if (filters.endDate) {
         where.requestedAt = {
           ...where.requestedAt,
           lte: filters.endDate,
         };
       }

       if (filters.artist) {
         where.artist = { contains: filters.artist, mode: 'insensitive' };
       }

       if (filters.title) {
         where.title = { contains: filters.title, mode: 'insensitive' };
       }

       const [history, total] = await Promise.all([
         this.prisma.singerRequestHistory.findMany({
           where,
           skip: (pagination.page - 1) * pagination.limit,
           take: pagination.limit,
           orderBy: { requestedAt: 'desc' },
           include: {
             venue: {
               select: {
                 id: true,
                 name: true,
                 urlName: true,
               },
             },
           },
         }),
         this.prisma.singerRequestHistory.count({ where }),
       ]);

       return {
         data: history.map((h) => ({
           id: h.id,
           venueId: h.venueId,
           venueName: h.venue.name,
           venueUrlName: h.venue.urlName,
           artist: h.artist,
           title: h.title,
           keyChange: h.keyChange,
           requestedAt: h.requestedAt.toISOString(),
         })),
         pagination: {
           page: pagination.page,
           limit: pagination.limit,
           total,
           totalPages: Math.ceil(total / pagination.limit),
         },
       };
     }

     async getRequestStats(singerProfileId: string) {
       // Total requests
       const totalRequests = await this.prisma.singerRequestHistory.count({
         where: { singerProfileId },
       });

       // Unique songs (by fingerprint)
       const uniqueSongs = await this.prisma.singerRequestHistory.groupBy({
         by: ['songFingerprint'],
         where: { singerProfileId },
       });

       // Unique venues
       const uniqueVenues = await this.prisma.singerRequestHistory.groupBy({
         by: ['venueId'],
         where: { singerProfileId },
       });

       // Most requested song
       const songCounts = await this.prisma.singerRequestHistory.groupBy({
         by: ['artist', 'title'],
         where: { singerProfileId },
         _count: { id: true },
         orderBy: { _count: { id: 'desc' } },
         take: 1,
       });

       const mostRequestedSong = songCounts[0]
         ? {
             artist: songCounts[0].artist,
             title: songCounts[0].title,
             count: songCounts[0]._count.id,
           }
         : null;

       // Favorite venue (most requests)
       const venueCounts = await this.prisma.singerRequestHistory.groupBy({
         by: ['venueId'],
         where: { singerProfileId },
         _count: { id: true },
         orderBy: { _count: { id: 'desc' } },
         take: 1,
       });

       let favoriteVenue = null;
       if (venueCounts[0]) {
         const venue = await this.prisma.venue.findUnique({
           where: { id: venueCounts[0].venueId },
           select: { id: true, name: true },
         });

         if (venue) {
           favoriteVenue = {
             id: venue.id,
             name: venue.name,
             requestCount: venueCounts[0]._count.id,
           };
         }
       }

       logger.debug(
         {
           singerProfileId,
           totalRequests,
           uniqueSongs: uniqueSongs.length,
           uniqueVenues: uniqueVenues.length,
         },
         'Request stats calculated'
       );

       return {
         totalRequests,
         uniqueSongs: uniqueSongs.length,
         uniqueVenues: uniqueVenues.length,
         mostRequestedSong,
         favoriteVenue,
       };
     }

     async deleteHistory(singerProfileId: string, historyId: string) {
       const history = await this.prisma.singerRequestHistory.findFirst({
         where: {
           id: historyId,
           singerProfileId,
         },
       });

       if (!history) {
         throw new Error('History item not found');
       }

       await this.prisma.singerRequestHistory.delete({
         where: { id: historyId },
       });

       logger.info({ singerProfileId, historyId }, 'History item deleted');
     }

     async clearHistory(
       singerProfileId: string,
       beforeDate?: Date
     ): Promise<number> {
       const where: any = { singerProfileId };

       if (beforeDate) {
         where.requestedAt = { lt: beforeDate };
       }

       const result = await this.prisma.singerRequestHistory.deleteMany({
         where,
       });

       logger.info(
         {
           singerProfileId,
           count: result.count,
           beforeDate,
         },
         'History cleared'
       );

       return result.count;
     }
   }
   ```

3. **Implement history routes in `apps/api/src/routes/singer/history.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateQuery, validateParams } from '@singr/shared/validation';
   import { RequestHistoryQuerySchema } from './schemas';
   import { SingerHistoryService } from '@singr/shared/services/singer-history-service';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:singer:history');

   export const historyRoute: FastifyPluginAsync = async (server) => {
     const historyService = new SingerHistoryService(server.prisma);

     // Get request history
     server.get(
       '/history',
       {
         schema: {
           tags: ['singer'],
           summary: 'Get request history',
           description: 'Retrieve singer request history with filters',
           security: [{ bearerAuth: [] }],
           querystring: {
             type: 'object',
             properties: {
               page: { type: 'integer', minimum: 1, default: 1 },
               limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
               venueId: { type: 'string', format: 'uuid' },
               startDate: { type: 'string', format: 'date-time' },
               endDate: { type: 'string', format: 'date-time' },
               artist: { type: 'string' },
               title: { type: 'string' },
             },
           },
           response: {
             200: {
               description: 'Request history',
               type: 'object',
               properties: {
                 data: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       id: { type: 'string', format: 'uuid' },
                       venueId: { type: 'string', format: 'uuid' },
                       venueName: { type: 'string' },
                       artist: { type: 'string' },
                       title: { type: 'string' },
                       keyChange: { type: 'integer' },
                       requestedAt: { type: 'string', format: 'date-time' },
                     },
                   },
                 },
                 pagination: {
                   type: 'object',
                   properties: {
                     page: { type: 'integer' },
                     limit: { type: 'integer' },
                     total: { type: 'integer' },
                     totalPages: { type: 'integer' },
                   },
                 },
               },
             },
           },
         },
         preHandler: [server.authenticate, validateQuery(RequestHistoryQuerySchema)],
       },
       async (request, reply) => {
         const query = request.query as z.infer<typeof RequestHistoryQuerySchema>;
         const userId = request.user.sub;

         const singerProfile = await server.prisma.singerProfile.findUnique({
           where: { userId },
         });

         if (!singerProfile) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Singer Profile Not Found',
             detail: 'No singer profile found for this user',
           });
         }

         const { page, limit, startDate, endDate, ...filters } = query;

         const result = await historyService.getRequestHistory(
           singerProfile.id,
           {
             ...filters,
             startDate: startDate ? new Date(startDate) : undefined,
             endDate: endDate ? new Date(endDate) : undefined,
           },
           { page, limit }
         );

         return reply.send(result);
       }
     );

     // Get request statistics
     server.get(
       '/history/stats',
       {
         schema: {
           tags: ['singer'],
           summary: 'Get request statistics',
           description: 'Retrieve statistics about singer request history',
           security: [{ bearerAuth: [] }],
           response: {
             200: {
               description: 'Request statistics',
               type: 'object',
               properties: {
                 totalRequests: { type: 'integer' },
                 uniqueSongs: { type: 'integer' },
                 uniqueVenues: { type: 'integer' },
                 mostRequestedSong: {
                   type: 'object',
                   properties: {
                     artist: { type: 'string' },
                     title: { type: 'string' },
                     count: { type: 'integer' },
                   },
                 },
                 favoriteVenue: {
                   type: 'object',
                   properties: {
                     id: { type: 'string', format: 'uuid' },
                     name: { type: 'string' },
                     requestCount: { type: 'integer' },
                   },
                 },
               },
             },
           },
         },
         preHandler: [server.authenticate],
       },
       async (request, reply) => {
         const userId = request.user.sub;

         const singerProfile = await server.prisma.singerProfile.findUnique({
           where: { userId },
         });

         if (!singerProfile) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Singer Profile Not Found',
             detail: 'No singer profile found for this user',
           });
         }

         const stats = await historyService.getRequestStats(singerProfile.id);

         return reply.send(stats);
       }
     );

     // Delete single history item
     server.delete(
       '/history/:id',
       {
         schema: {
           tags: ['singer'],
           summary: 'Delete history item',
           description: 'Delete a single request from history',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             204: {
               description: 'History item deleted',
             },
             404: {
               description: 'History item not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           validateParams(z.object({ id: z.string().uuid() })),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as { id: string };
         const userId = request.user.sub;

         const singerProfile = await server.prisma.singerProfile.findUnique({
           where: { userId },
         });

         if (!singerProfile) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Singer Profile Not Found',
             detail: 'No singer profile found for this user',
           });
         }

         try {
           await historyService.deleteHistory(singerProfile.id, id);
           return reply.code(204).send();
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'History Item Not Found',
               detail: 'History item not found or access denied',
             });
           }
           throw error;
         }
       }
     );

     // Clear all history or history before date
     server.delete(
       '/history',
       {
         schema: {
           tags: ['singer'],
           summary: 'Clear history',
           description: 'Clear all request history or history before a specific date',
           security: [{ bearerAuth: [] }],
           querystring: {
             type: 'object',
             properties: {
               beforeDate: { type: 'string', format: 'date-time' },
             },
           },
           response: {
             200: {
               description: 'History cleared',
               type: 'object',
               properties: {
                 deletedCount: { type: 'integer' },
               },
             },
           },
         },
         preHandler: [server.authenticate],
         config: {
           rateLimit: {
             max: 5,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const { beforeDate } = request.query as { beforeDate?: string };
         const userId = request.user.sub;

         const singerProfile = await server.prisma.singerProfile.findUnique({
           where: { userId },
         });

         if (!singerProfile) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Singer Profile Not Found',
             detail: 'No singer profile found for this user',
           });
         }

         const deletedCount = await historyService.clearHistory(
           singerProfile.id,
           beforeDate ? new Date(beforeDate) : undefined
         );

         return reply.send({ deletedCount });
       }
     );
   };
   ```

**Deliverables:**
- ✅ `GET /v1/singer/history` - Get request history with filters
- ✅ `GET /v1/singer/history/stats` - Get statistics (total requests, unique songs/venues, favorites)
- ✅ `DELETE /v1/singer/history/:id` - Delete single history item
- ✅ `DELETE /v1/singer/history` - Clear all or partial history
- ✅ Filter by venue, date range, artist, title
- ✅ Pagination support
- ✅ Most requested song calculation
- ✅ Favorite venue calculation
- ✅ Rate limiting on bulk delete

---

### 7.2 Favorite Songs Management

**Objective:** Allow singers to save and manage their favorite songs.

**Duration:** 2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create favorite songs schemas:**
   ```typescript
   // Add to apps/api/src/routes/singer/schemas.ts
   export const FavoriteSongQuerySchema = PaginationSchema.extend({
     artist: z.string().max(100).optional(),
     title: z.string().max(100).optional(),
     search: z.string().max(200).optional(),
   });

   export const AddFavoriteSongSchema = z.object({
     artist: z.string().min(1).max(255),
     title: z.string().min(1).max(255),
     keyChange: z.number().int().min(-12).max(12).default(0),
     metadata: z.record(z.any()).optional(),
   });

   export const UpdateFavoriteSongSchema = z.object({
     keyChange: z.number().int().min(-12).max(12).optional(),
     metadata: z.record(z.any()).optional(),
   });

   export const FavoriteSongResponseSchema = z.object({
     id: z.string().uuid(),
     artist: z.string(),
     title: z.string(),
     keyChange: z.number(),
     metadata: z.record(z.any()),
     createdAt: z.string().datetime(),
     updatedAt: z.string().datetime(),
   });
   ```

2. **Create favorite songs service in `packages/shared/src/services/favorite-songs-service.ts`:**
   ```typescript
   import { PrismaClient } from '@prisma/database';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('services:favorite-songs');

   export interface FavoriteSongFilters {
     artist?: string;
     title?: string;
     search?: string;
   }

   export interface AddFavoriteSongInput {
     singerProfileId: string;
     artist: string;
     title: string;
     keyChange?: number;
     metadata?: Record<string, any>;
   }

   export class FavoriteSongsService {
     constructor(private prisma: PrismaClient) {}

     async listFavoriteSongs(
       singerProfileId: string,
       filters: FavoriteSongFilters,
       pagination: { page: number; limit: number }
     ) {
       const where: any = { singerProfileId };

       if (filters.artist) {
         where.artist = { contains: filters.artist, mode: 'insensitive' };
       }

       if (filters.title) {
         where.title = { contains: filters.title, mode: 'insensitive' };
       }

       if (filters.search) {
         where.OR = [
           { artist: { contains: filters.search, mode: 'insensitive' } },
           { title: { contains: filters.search, mode: 'insensitive' } },
         ];
       }

       const [favorites, total] = await Promise.all([
         this.prisma.singerFavoriteSong.findMany({
           where,
           skip: (pagination.page - 1) * pagination.limit,
           take: pagination.limit,
           orderBy: [{ artist: 'asc' }, { title: 'asc' }],
         }),
         this.prisma.singerFavoriteSong.count({ where }),
       ]);

       return {
         data: favorites.map((f) => ({
           id: f.id,
           artist: f.artist || '',
           title: f.title || '',
           keyChange: f.keyChange,
           metadata: f.metadata || {},
           createdAt: f.createdAt.toISOString(),
           updatedAt: f.updatedAt.toISOString(),
         })),
         pagination: {
           page: pagination.page,
           limit: pagination.limit,
           total,
           totalPages: Math.ceil(total / pagination.limit),
         },
       };
     }

     async addFavoriteSong(input: AddFavoriteSongInput) {
       // Check if already exists
       const existing = await this.prisma.singerFavoriteSong.findFirst({
         where: {
           singerProfileId: input.singerProfileId,
           artist: input.artist,
           title: input.title,
           keyChange: input.keyChange || 0,
         },
       });

       if (existing) {
         throw new Error('This song is already in your favorites');
       }

       const favorite = await this.prisma.singerFavoriteSong.create({
         data: {
           singerProfileId: input.singerProfileId,
           artist: input.artist,
           title: input.title,
           keyChange: input.keyChange || 0,
           metadata: input.metadata || {},
         },
       });

       logger.info(
         {
           singerProfileId: input.singerProfileId,
           favoriteId: favorite.id,
           artist: input.artist,
           title: input.title,
         },
         'Favorite song added'
       );

       return {
         id: favorite.id,
         artist: favorite.artist || '',
         title: favorite.title || '',
         keyChange: favorite.keyChange,
         metadata: favorite.metadata || {},
         createdAt: favorite.createdAt.toISOString(),
         updatedAt: favorite.updatedAt.toISOString(),
       };
     }

     async updateFavoriteSong(
       favoriteId: string,
       singerProfileId: string,
       input: { keyChange?: number; metadata?: Record<string, any> }
     ) {
       const favorite = await this.prisma.singerFavoriteSong.findFirst({
         where: {
           id: favoriteId,
           singerProfileId,
         },
       });

       if (!favorite) {
         throw new Error('Favorite song not found');
       }

       const updated = await this.prisma.singerFavoriteSong.update({
         where: { id: favoriteId },
         data: {
           keyChange: input.keyChange,
           metadata: input.metadata
             ? { ...favorite.metadata, ...input.metadata }
             : undefined,
         },
       });

       logger.info(
         {
           singerProfileId,
           favoriteId,
         },
         'Favorite song updated'
       );

       return {
         id: updated.id,
         artist: updated.artist || '',
         title: updated.title || '',
         keyChange: updated.keyChange,
         metadata: updated.metadata || {},
         createdAt: updated.createdAt.toISOString(),
         updatedAt: updated.updatedAt.toISOString(),
       };
     }

     async deleteFavoriteSong(favoriteId: string, singerProfileId: string) {
       const favorite = await this.prisma.singerFavoriteSong.findFirst({
         where: {
           id: favoriteId,
           singerProfileId,
         },
       });

       if (!favorite) {
         throw new Error('Favorite song not found');
       }

       await this.prisma.singerFavoriteSong.delete({
         where: { id: favoriteId },
       });

       logger.info({ singerProfileId, favoriteId }, 'Favorite song deleted');
     }

     async getFavoriteSong(favoriteId: string, singerProfileId: string) {
       const favorite = await this.prisma.singerFavoriteSong.findFirst({
         where: {
           id: favoriteId,
           singerProfileId,
         },
       });

       if (!favorite) {
         throw new Error('Favorite song not found');
       }

       return {
         id: favorite.id,
         artist: favorite.artist || '',
         title: favorite.title || '',
         keyChange: favorite.keyChange,
         metadata: favorite.metadata || {},
         createdAt: favorite.createdAt.toISOString(),
         updatedAt: favorite.updatedAt.toISOString(),
       };
     }
   }
   ```

3. **Implement favorite songs routes in `apps/api/src/routes/singer/favorites.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateQuery, validateParams, validateBody } from '@singr/shared/validation';
   import {
     FavoriteSongQuerySchema,
     AddFavoriteSongSchema,
     UpdateFavoriteSongSchema,
   } from './schemas';
   import { FavoriteSongsService } from '@singr/shared/services/favorite-songs-service';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:singer:favorites');

   export const favoritesRoute: FastifyPluginAsync = async (server) => {
     const favoritesService = new FavoriteSongsService(server.prisma);

     // List favorite songs
     server.get(
       '/favorites/songs',
       {
         schema: {
           tags: ['singer'],
           summary: 'List favorite songs',
           description: 'Get all favorite songs with filters',
           security: [{ bearerAuth: [] }],
           querystring: {
             type: 'object',
             properties: {
               page: { type: 'integer', minimum: 1, default: 1 },
               limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
               artist: { type: 'string' },
               title: { type: 'string' },
               search: { type: 'string' },
             },
           },
           response: {
             200: {
               description: 'Favorite songs',
               type: 'object',
               properties: {
                 data: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       id: { type: 'string', format: 'uuid' },
                       artist: { type: 'string' },
                       title: { type: 'string' },
                       keyChange: { type: 'integer' },
                     },
                   },
                 },
                 pagination: {
                   type: 'object',
                   properties: {
                     page: { type: 'integer' },
                     limit: { type: 'integer' },
                     total: { type: 'integer' },
                     totalPages: { type: 'integer' },
                   },
                 },
               },
             },
           },
         },
         preHandler: [server.authenticate, validateQuery(FavoriteSongQuerySchema)],
       },
       async (request, reply) => {
         const query = request.query as z.infer<typeof FavoriteSongQuerySchema>;
         const userId = request.user.sub;

         const singerProfile = await server.prisma.singerProfile.findUnique({
           where: { userId },
         });

         if (!singerProfile) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Singer Profile Not Found',
             detail: 'No singer profile found for this user',
           });
         }

         const { page, limit, ...filters } = query;

         const result = await favoritesService.listFavoriteSongs(
           singerProfile.id,
           filters,
           { page, limit }
         );

         return reply.send(result);
       }
     );

     // Add favorite song
     server.post(
       '/favorites/songs',
       {
         schema: {
           tags: ['singer'],
           summary: 'Add favorite song',
           description: 'Add a song to favorites',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['artist', 'title'],
             properties: {
               artist: { type: 'string', minLength: 1, maxLength: 255 },
               title: { type: 'string', minLength: 1, maxLength: 255 },
               keyChange: { type: 'integer', minimum: -12, maximum: 12, default: 0 },
               metadata: { type: 'object' },
             },
           },
           response: {
             201: {
               description: 'Favorite song added',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 artist: { type: 'string' },
                 title: { type: 'string' },
                 keyChange: { type: 'integer' },
               },
             },
             409: {
               description: 'Song already in favorites',
             },
           },
         },
         preHandler: [server.authenticate, validateBody(AddFavoriteSongSchema)],
       },
       async (request, reply) => {
         const body = request.body as z.infer<typeof AddFavoriteSongSchema>;
         const userId = request.user.sub;

         const singerProfile = await server.prisma.singerProfile.findUnique({
           where: { userId },
         });

         if (!singerProfile) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Singer Profile Not Found',
             detail: 'No singer profile found for this user',
           });
         }

         try {
           const favorite = await favoritesService.addFavoriteSong({
             singerProfileId: singerProfile.id,
             ...body,
           });

           return reply.code(201).send(favorite);
         } catch (error) {
           if (error instanceof Error && error.message.includes('already in')) {
             return reply.code(409).send({
               type: 'conflict',
               title: 'Already in Favorites',
               detail: error.message,
             });
           }
           throw error;
         }
       }
     );

     // Get favorite song details
     server.get(
       '/favorites/songs/:id',
       {
         schema: {
           tags: ['singer'],
           summary: 'Get favorite song',
           description: 'Get details of a specific favorite song',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'Favorite song details',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 artist: { type: 'string' },
                 title: { type: 'string' },
                 keyChange: { type: 'integer' },
                 metadata: { type: 'object' },
               },
             },
             404: {
               description: 'Favorite song not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           validateParams(z.object({ id: z.string().uuid() })),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as { id: string };
         const userId = request.user.sub;

         const singerProfile = await server.prisma.singerProfile.findUnique({
           where: { userId },
         });

         if (!singerProfile) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Singer Profile Not Found',
             detail: 'No singer profile found for this user',
           });
         }

         try {
           const favorite = await favoritesService.getFavoriteSong(
             id,
             singerProfile.id
           );
           return reply.send(favorite);
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'Favorite Not Found',
               detail: 'Favorite song not found or access denied',
             });
           }
           throw error;
         }
       }
     );

     // Update favorite song
     server.patch(
       '/favorites/songs/:id',
       {
         schema: {
           tags: ['singer'],
           summary: 'Update favorite song',
           description: 'Update key change or metadata for a favorite song',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           body: {
             type: 'object',
             properties: {
               keyChange: { type: 'integer', minimum: -12, maximum: 12 },
               metadata: { type: 'object' },
             },
           },
           response: {
             200: {
               description: 'Favorite song updated',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 artist: { type: 'string' },
                 title: { type: 'string' },
                 keyChange: { type: 'integer' },
               },
             },
           },
         },
         preHandler: [
           server.authenticate,
           validateParams(z.object({ id: z.string().uuid() })),
           validateBody(UpdateFavoriteSongSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as { id: string };
         const body = request.body as z.infer<typeof UpdateFavoriteSongSchema>;
         const userId = request.user.sub;

         const singerProfile = await server.prisma.singerProfile.findUnique({
           where: { userId },
         });

         if (!singerProfile) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Singer Profile Not Found',
             detail: 'No singer profile found for this user',
           });
         }

         try {
           const favorite = await favoritesService.updateFavoriteSong(
             id,
             singerProfile.id,
             body
           );
           return reply.send(favorite);
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'Favorite Not Found',
               detail: 'Favorite song not found or access denied',
             });
           }
           throw error;
         }
       }
     );

     // Delete favorite song
     server.delete(
       '/favorites/songs/:id',
       {
         schema: {
           tags: ['singer'],
           summary: 'Delete favorite song',
           description: 'Remove a song from favorites',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             204: {
               description: 'Favorite song deleted',
             },
             404: {
               description: 'Favorite song not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           validateParams(z.object({ id: z.string().uuid() })),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as { id: string };
         const userId = request.user.sub;

         const singerProfile = await server.prisma.singerProfile.findUnique({
           where: { userId },
         });

         if (!singerProfile) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Singer Profile Not Found',
             detail: 'No singer profile found for this user',
           });
         }

         try {
           await favoritesService.deleteFavoriteSong(id, singerProfile.id);
           return reply.code(204).send();
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'Favorite Not Found',
               detail: 'Favorite song not found or access denied',
             });
           }
           throw error;
         }
       }
     );
   };
   ```

**Deliverables:**
- ✅ `GET /v1/singer/favorites/songs` - List favorite songs with filters
- ✅ `POST /v1/singer/favorites/songs` - Add song to favorites
- ✅ `GET /v1/singer/favorites/songs/:id` - Get favorite song details
- ✅ `PATCH /v1/singer/favorites/songs/:id` - Update key change or metadata
- ✅ `DELETE /v1/singer/favorites/songs/:id` - Remove from favorites
- ✅ Search by artist, title, or combined
- ✅ Duplicate detection
- ✅ Metadata support for custom fields
- ✅ Pagination support

---

### 7.3 Favorite Venues Management

**Objective:** Allow singers to save and manage their favorite venues.

**Duration:** 1-2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create favorite venues schemas:**
   ```typescript
   // Add to apps/api/src/routes/singer/schemas.ts
   export const FavoriteVenueQuerySchema = PaginationSchema.extend({
     city: z.string().max(100).optional(),
     state: z.string().max(50).optional(),
     search: z.string().max(100).optional(),
   });

   export const AddFavoriteVenueSchema = z.object({
     venueId: z.string().uuid(),
   });

   export const FavoriteVenueResponseSchema = z.object({
     venueId: z.string().uuid(),
     venueName: z.string(),
     venueUrlName: z.string(),
     address: z.string(),
     city: z.string(),
     state: z.string(),
     postalCode: z.string(),
     phoneNumber: z.string().nullable(),
     website: z.string().nullable(),
     acceptingRequests: z.boolean(),
     addedAt: z.string().datetime(),
   });
   ```

2. **Create favorite venues service in `packages/shared/src/services/favorite-venues-service.ts`:**
   ```typescript
   import { PrismaClient } from '@prisma/database';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('services:favorite-venues');

   export interface FavoriteVenueFilters {
     city?: string;
     state?: string;
     search?: string;
   }

   export class FavoriteVenuesService {
     constructor(private prisma: PrismaClient) {}

     async listFavoriteVenues(
       singerProfileId: string,
       filters: FavoriteVenueFilters,
       pagination: { page: number; limit: number }
     ) {
       const where: any = { singerProfileId };

       // Build venue filters
       const venueWhere: any = {};

       if (filters.city) {
         venueWhere.city = { contains: filters.city, mode: 'insensitive' };
       }

       if (filters.state) {
         venueWhere.state = { equals: filters.state, mode: 'insensitive' };
       }

       if (filters.search) {
         venueWhere.name = { contains: filters.search, mode: 'insensitive' };
       }

       if (Object.keys(venueWhere).length > 0) {
         where.venue = venueWhere;
       }

       const [favorites, total] = await Promise.all([
         this.prisma.singerFavoriteVenue.findMany({
           where,
           skip: (pagination.page - 1) * pagination.limit,
           take: pagination.limit,
           orderBy: { createdAt: 'desc' },
           include: {
             venue: true,
           },
         }),
         this.prisma.singerFavoriteVenue.count({ where }),
       ]);

       return {
         data: favorites.map((f) => ({
           venueId: f.venueId,
           venueName: f.venue.name,
           venueUrlName: f.venue.urlName,
           address: f.venue.address,
           city: f.venue.city,
           state: f.venue.state,
           postalCode: f.venue.postalCode,
           phoneNumber: f.venue.phoneNumber,
           website: f.venue.website,
           acceptingRequests: f.venue.acceptingRequests,
           addedAt: f.createdAt.toISOString(),
         })),
         pagination: {
           page: pagination.page,
           limit: pagination.limit,
           total,
           totalPages: Math.ceil(total / pagination.limit),
         },
       };
     }

     async addFavoriteVenue(singerProfileId: string, venueId: string) {
       // Check if venue exists
       const venue = await this.prisma.venue.findUnique({
         where: { id: venueId },
       });

       if (!venue) {
         throw new Error('Venue not found');
       }

       // Check if already favorited
       const existing = await this.prisma.singerFavoriteVenue.findUnique({
         where: {
           singerProfileId_venueId: {
             singerProfileId,
             venueId,
           },
         },
       });

       if (existing) {
         throw new Error('Venue is already in your favorites');
       }

       const favorite = await this.prisma.singerFavoriteVenue.create({
         data: {
           singerProfileId,
           venueId,
         },
         include: {
           venue: true,
         },
       });

       logger.info(
         {
           singerProfileId,
           venueId,
           venueName: venue.name,
         },
         'Favorite venue added'
       );

       return {
         venueId: favorite.venueId,
         venueName: favorite.venue.name,
         venueUrlName: favorite.venue.urlName,
         address: favorite.venue.address,
         city: favorite.venue.city,
         state: favorite.venue.state,
         postalCode: favorite.venue.postalCode,
         phoneNumber: favorite.venue.phoneNumber,
         website: favorite.venue.website,
         acceptingRequests: favorite.venue.acceptingRequests,
         addedAt: favorite.createdAt.toISOString(),
       };
     }

     async removeFavoriteVenue(singerProfileId: string, venueId: string) {
       const favorite = await this.prisma.singerFavoriteVenue.findUnique({
         where: {
           singerProfileId_venueId: {
             singerProfileId,
             venueId,
           },
         },
       });

       if (!favorite) {
         throw new Error('Favorite venue not found');
       }

       await this.prisma.singerFavoriteVenue.delete({
         where: {
           singerProfileId_venueId: {
             singerProfileId,
             venueId,
           },
         },
       });

       logger.info({ singerProfileId, venueId }, 'Favorite venue removed');
     }

     async isFavorite(singerProfileId: string, venueId: string): Promise<boolean> {
       const favorite = await this.prisma.singerFavoriteVenue.findUnique({
         where: {
           singerProfileId_venueId: {
             singerProfileId,
             venueId,
           },
         },
       });

       return !!favorite;
     }

     async getFavoriteVenue(singerProfileId: string, venueId: string) {
       const favorite = await this.prisma.singerFavoriteVenue.findUnique({
         where: {
           singerProfileId_venueId: {
             singerProfileId,
             venueId,
           },
         },
         include: {
           venue: true,
         },
       });

       if (!favorite) {
         throw new Error('Favorite venue not found');
       }

       return {
         venueId: favorite.venueId,
         venueName: favorite.venue.name,
         venueUrlName: favorite.venue.urlName,
         address: favorite.venue.address,
         city: favorite.venue.city,
         state: favorite.venue.state,
         postalCode: favorite.venue.postalCode,
         phoneNumber: favorite.venue.phoneNumber,
         website: favorite.venue.website,
         acceptingRequests: favorite.venue.acceptingRequests,
         addedAt: favorite.createdAt.toISOString(),
       };
     }
   }
   ```

3. **Implement favorite venues routes in `apps/api/src/routes/singer/favorites.ts`:**
   ```typescript
   // Add to existing favoritesRoute

   // List favorite venues
   server.get(
     '/favorites/venues',
     {
       schema: {
         tags: ['singer'],
         summary: 'List favorite venues',
         description: 'Get all favorite venues with filters',
         security: [{ bearerAuth: [] }],
         querystring: {
           type: 'object',
           properties: {
             page: { type: 'integer', minimum: 1, default: 1 },
             limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
             city: { type: 'string' },
             state: { type: 'string' },
             search: { type: 'string' },
           },
         },
         response: {
           200: {
             description: 'Favorite venues',
             type: 'object',
             properties: {
               data: {
                 type: 'array',
                 items: {
                   type: 'object',
                   properties: {
                     venueId: { type: 'string', format: 'uuid' },
                     venueName: { type: 'string' },
                     venueUrlName: { type: 'string' },
                     city: { type: 'string' },
                     state: { type: 'string' },
                     acceptingRequests: { type: 'boolean' },
                     addedAt: { type: 'string', format: 'date-time' },
                   },
                 },
               },
               pagination: {
                 type: 'object',
                 properties: {
                   page: { type: 'integer' },
                   limit: { type: 'integer' },
                   total: { type: 'integer' },
                   totalPages: { type: 'integer' },
                 },
               },
             },
           },
         },
       },
       preHandler: [server.authenticate, validateQuery(FavoriteVenueQuerySchema)],
     },
     async (request, reply) => {
       const query = request.query as z.infer<typeof FavoriteVenueQuerySchema>;
       const userId = request.user.sub;

       const singerProfile = await server.prisma.singerProfile.findUnique({
         where: { userId },
       });

       if (!singerProfile) {
         return reply.code(404).send({
           type: 'resource_not_found',
           title: 'Singer Profile Not Found',
           detail: 'No singer profile found for this user',
         });
       }

       const { page, limit, ...filters } = query;

       const favoriteVenuesService = new FavoriteVenuesService(server.prisma);
       const result = await favoriteVenuesService.listFavoriteVenues(
         singerProfile.id,
         filters,
         { page, limit }
       );

       return reply.send(result);
     }
   );

   // Add favorite venue
   server.post(
     '/favorites/venues',
     {
       schema: {
         tags: ['singer'],
         summary: 'Add favorite venue',
         description: 'Add a venue to favorites',
         security: [{ bearerAuth: [] }],
         body: {
           type: 'object',
           required: ['venueId'],
           properties: {
             venueId: { type: 'string', format: 'uuid' },
           },
         },
         response: {
           201: {
             description: 'Favorite venue added',
             type: 'object',
             properties: {
               venueId: { type: 'string', format: 'uuid' },
               venueName: { type: 'string' },
               venueUrlName: { type: 'string' },
               city: { type: 'string' },
               state: { type: 'string' },
               acceptingRequests: { type: 'boolean' },
               addedAt: { type: 'string', format: 'date-time' },
             },
           },
           404: {
             description: 'Venue not found',
           },
           409: {
             description: 'Venue already in favorites',
           },
         },
       },
       preHandler: [server.authenticate, validateBody(AddFavoriteVenueSchema)],
     },
     async (request, reply) => {
       const { venueId } = request.body as z.infer<typeof AddFavoriteVenueSchema>;
       const userId = request.user.sub;

       const singerProfile = await server.prisma.singerProfile.findUnique({
         where: { userId },
       });

       if (!singerProfile) {
         return reply.code(404).send({
           type: 'resource_not_found',
           title: 'Singer Profile Not Found',
           detail: 'No singer profile found for this user',
         });
       }

       const favoriteVenuesService = new FavoriteVenuesService(server.prisma);

       try {
         const favorite = await favoriteVenuesService.addFavoriteVenue(
           singerProfile.id,
           venueId
         );

         return reply.code(201).send(favorite);
       } catch (error) {
         if (error instanceof Error) {
           if (error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'Venue Not Found',
               detail: error.message,
             });
           }
           if (error.message.includes('already in')) {
             return reply.code(409).send({
               type: 'conflict',
               title: 'Already in Favorites',
               detail: error.message,
             });
           }
         }
         throw error;
       }
     }
   );

   // Get favorite venue details
   server.get(
     '/favorites/venues/:venueId',
     {
       schema: {
         tags: ['singer'],
         summary: 'Get favorite venue',
         description: 'Get details of a specific favorite venue',
         security: [{ bearerAuth: [] }],
         params: {
           type: 'object',
           properties: {
             venueId: { type: 'string', format: 'uuid' },
           },
         },
         response: {
           200: {
             description: 'Favorite venue details',
             type: 'object',
             properties: {
               venueId: { type: 'string', format: 'uuid' },
               venueName: { type: 'string' },
               venueUrlName: { type: 'string' },
               address: { type: 'string' },
               city: { type: 'string' },
               state: { type: 'string' },
               acceptingRequests: { type: 'boolean' },
               addedAt: { type: 'string', format: 'date-time' },
             },
           },
           404: {
             description: 'Favorite venue not found',
           },
         },
       },
       preHandler: [
         server.authenticate,
         validateParams(z.object({ venueId: z.string().uuid() })),
       ],
     },
     async (request, reply) => {
       const { venueId } = request.params as { venueId: string };
       const userId = request.user.sub;

       const singerProfile = await server.prisma.singerProfile.findUnique({
         where: { userId },
       });

       if (!singerProfile) {
         return reply.code(404).send({
           type: 'resource_not_found',
           title: 'Singer Profile Not Found',
           detail: 'No singer profile found for this user',
         });
       }

       const favoriteVenuesService = new FavoriteVenuesService(server.prisma);

       try {
         const favorite = await favoriteVenuesService.getFavoriteVenue(
           singerProfile.id,
           venueId
         );
         return reply.send(favorite);
       } catch (error) {
         if (error instanceof Error && error.message.includes('not found')) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Favorite Not Found',
             detail: 'Favorite venue not found or access denied',
           });
         }
         throw error;
       }
     }
   );

   // Check if venue is favorite
   server.get(
     '/favorites/venues/:venueId/check',
     {
       schema: {
         tags: ['singer'],
         summary: 'Check if venue is favorite',
         description: 'Check if a venue is in favorites',
         security: [{ bearerAuth: [] }],
         params: {
           type: 'object',
           properties: {
             venueId: { type: 'string', format: 'uuid' },
           },
         },
         response: {
           200: {
             description: 'Favorite status',
             type: 'object',
             properties: {
               isFavorite: { type: 'boolean' },
             },
           },
         },
       },
       preHandler: [
         server.authenticate,
         validateParams(z.object({ venueId: z.string().uuid() })),
       ],
     },
     async (request, reply) => {
       const { venueId } = request.params as { venueId: string };
       const userId = request.user.sub;

       const singerProfile = await server.prisma.singerProfile.findUnique({
         where: { userId },
       });

       if (!singerProfile) {
         return reply.send({ isFavorite: false });
       }

       const favoriteVenuesService = new FavoriteVenuesService(server.prisma);
       const isFavorite = await favoriteVenuesService.isFavorite(
         singerProfile.id,
         venueId
       );

       return reply.send({ isFavorite });
     }
   );

   // Remove favorite venue
   server.delete(
     '/favorites/venues/:venueId',
     {
       schema: {
         tags: ['singer'],
         summary: 'Remove favorite venue',
         description: 'Remove a venue from favorites',
         security: [{ bearerAuth: [] }],
         params: {
           type: 'object',
           properties: {
             venueId: { type: 'string', format: 'uuid' },
           },
         },
         response: {
           204: {
             description: 'Favorite venue removed',
           },
           404: {
             description: 'Favorite venue not found',
           },
         },
       },
       preHandler: [
         server.authenticate,
         validateParams(z.object({ venueId: z.string().uuid() })),
       ],
     },
     async (request, reply) => {
       const { venueId } = request.params as { venueId: string };
       const userId = request.user.sub;

       const singerProfile = await server.prisma.singerProfile.findUnique({
         where: { userId },
       });

       if (!singerProfile) {
         return reply.code(404).send({
           type: 'resource_not_found',
           title: 'Singer Profile Not Found',
           detail: 'No singer profile found for this user',
         });
       }

       const favoriteVenuesService = new FavoriteVenuesService(server.prisma);

       try {
         await favoriteVenuesService.removeFavoriteVenue(
           singerProfile.id,
           venueId
         );
         return reply.code(204).send();
       } catch (error) {
         if (error instanceof Error && error.message.includes('not found')) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Favorite Not Found',
             detail: 'Favorite venue not found or access denied',
           });
         }
         throw error;
       }
     }
   );
   ```

4. **Update singer routes index to include favorites and history:**
   ```typescript
   // Update apps/api/src/routes/singer/index.ts
   import { FastifyPluginAsync } from 'fastify';
   import { profileRoute } from './profile';
   import { requestsRoute } from './requests';
   import { accountRoute } from './account';
   import { historyRoute } from './history';
   import { favoritesRoute } from './favorites';

   export const singerRoutes: FastifyPluginAsync = async (server) => {
     await server.register(profileRoute);
     await server.register(requestsRoute);
     await server.register(accountRoute);
     await server.register(historyRoute);
     await server.register(favoritesRoute);
   };
   ```

**Deliverables:**
- ✅ `GET /v1/singer/favorites/venues` - List favorite venues with filters
- ✅ `POST /v1/singer/favorites/venues` - Add venue to favorites
- ✅ `GET /v1/singer/favorites/venues/:venueId` - Get favorite venue details
- ✅ `GET /v1/singer/favorites/venues/:venueId/check` - Check if venue is favorite
- ✅ `DELETE /v1/singer/favorites/venues/:venueId` - Remove from favorites
- ✅ Filter by city, state, or name
- ✅ Duplicate detection
- ✅ Pagination support
- ✅ Validation that venue exists before adding

---

### 7.4 Singer Dashboard & Recommendations

**Objective:** Provide personalized dashboard with quick actions and recommendations.

**Duration:** 2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create dashboard schemas:**
   ```typescript
   // Add to apps/api/src/routes/singer/schemas.ts
   export const DashboardResponseSchema = z.object({
     recentRequests: z.array(
       z.object({
         id: z.number(),
         venueId: z.string().uuid(),
         venueName: z.string(),
         artist: z.string(),
         title: z.string(),
         requestedAt: z.string().datetime(),
         processed: z.boolean(),
       })
     ),
     favoriteVenues: z.array(
       z.object({
         venueId: z.string().uuid(),
         venueName: z.string(),
         city: z.string(),
         state: z.string(),
         acceptingRequests: z.boolean(),
       })
     ),
     recommendedSongs: z.array(
       z.object({
         artist: z.string(),
         title: z.string(),
         requestCount: z.number(),
         lastRequested: z.string().datetime(),
       })
     ),
     stats: z.object({
       totalRequests: z.number(),
       totalFavoriteSongs: z.number(),
       totalFavoriteVenues: z.number(),
       requestsThisMonth: z.number(),
     }),
   });
   ```

2. **Create dashboard service in `packages/shared/src/services/singer-dashboard-service.ts`:**
   ```typescript
   import { PrismaClient } from '@prisma/database';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('services:singer-dashboard');

   export class SingerDashboardService {
     constructor(private prisma: PrismaClient) {}

     async getDashboard(singerProfileId: string) {
       const now = new Date();
       const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

       // Recent requests (last 10)
       const recentRequests = await this.prisma.request.findMany({
         where: {
           singerProfileId,
         },
         take: 10,
         orderBy: { requestedAt: 'desc' },
         include: {
           venue: {
             select: {
               id: true,
               name: true,
             },
           },
         },
       });

       // Favorite venues (top 5 most recent)
       const favoriteVenues = await this.prisma.singerFavoriteVenue.findMany({
         where: { singerProfileId },
         take: 5,
         orderBy: { createdAt: 'desc' },
         include: {
           venue: {
             select: {
               id: true,
               name: true,
               city: true,
               state: true,
               acceptingRequests: true,
             },
           },
         },
       });

       // Recommended songs (based on request history - top 5)
       const recommendedSongs = await this.prisma.singerRequestHistory.groupBy({
         by: ['artist', 'title'],
         where: { singerProfileId },
         _count: { id: true },
         _max: { requestedAt: true },
         orderBy: { _count: { id: 'desc' } },
         take: 5,
       });

       // Stats
       const [
         totalRequests,
         totalFavoriteSongs,
         totalFavoriteVenues,
         requestsThisMonth,
       ] = await Promise.all([
         this.prisma.singerRequestHistory.count({
           where: { singerProfileId },
         }),
         this.prisma.singerFavoriteSong.count({
           where: { singerProfileId },
         }),
         this.prisma.singerFavoriteVenue.count({
           where: { singerProfileId },
         }),
         this.prisma.singerRequestHistory.count({
           where: {
             singerProfileId,
             requestedAt: { gte: startOfMonth },
           },
         }),
       ]);

       logger.debug({ singerProfileId }, 'Dashboard data retrieved');

       return {
         recentRequests: recentRequests.map((r) => ({
           id: Number(r.id),
           venueId: r.venueId,
           venueName: r.venue.name,
           artist: r.artist,
           title: r.title,
           requestedAt: r.requestedAt.toISOString(),
           processed: r.processed,
         })),
         favoriteVenues: favoriteVenues.map((fv) => ({
           venueId: fv.venue.id,
           venueName: fv.venue.name,
           city: fv.venue.city,
           state: fv.venue.state,
           acceptingRequests: fv.venue.acceptingRequests,
         })),
         recommendedSongs: recommendedSongs.map((rs) => ({
           artist: rs.artist,
           title: rs.title,
           requestCount: rs._count.id,
           lastRequested: rs._max.requestedAt?.toISOString() || '',
         })),
         stats: {
           totalRequests,
           totalFavoriteSongs,
           totalFavoriteVenues,
           requestsThisMonth,
         },
       };
     }

     async getQuickActions(singerProfileId: string) {
       // Get recent venues for quick request
       const recentVenues = await this.prisma.singerRequestHistory.groupBy({
         by: ['venueId'],
         where: { singerProfileId },
         _max: { requestedAt: true },
         orderBy: { _max: { requestedAt: 'desc' } },
         take: 3,
       });

       const venueIds = recentVenues.map((rv) => rv.venueId);
       const venues = await this.prisma.venue.findMany({
         where: {
           id: { in: venueIds },
           acceptingRequests: true,
         },
         select: {
           id: true,
           name: true,
           urlName: true,
           city: true,
           state: true,
         },
       });

       // Get favorite songs for quick request
       const favoriteSongs = await this.prisma.singerFavoriteSong.findMany({
         where: { singerProfileId },
         take: 5,
         orderBy: { updatedAt: 'desc' },
         select: {
           id: true,
           artist: true,
           title: true,
           keyChange: true,
         },
       });

       return {
         recentVenues: venues,
         favoriteSongs: favoriteSongs.map((fs) => ({
           id: fs.id,
           artist: fs.artist || '',
           title: fs.title || '',
           keyChange: fs.keyChange,
         })),
       };
     }
   }
   ```

3. **Implement dashboard route in `apps/api/src/routes/singer/dashboard.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { SingerDashboardService } from '@singr/shared/services/singer-dashboard-service';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:singer:dashboard');

   export const dashboardRoute: FastifyPluginAsync = async (server) => {
     const dashboardService = new SingerDashboardService(server.prisma);

     // Get dashboard data
     server.get(
       '/dashboard',
       {
         schema: {
           tags: ['singer'],
           summary: 'Get dashboard',
           description: 'Get personalized dashboard with recent activity and recommendations',
           security: [{ bearerAuth: [] }],
           response: {
             200: {
               description: 'Dashboard data',
               type: 'object',
               properties: {
                 recentRequests: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       id: { type: 'integer' },
                       venueId: { type: 'string', format: 'uuid' },
                       venueName: { type: 'string' },
                       artist: { type: 'string' },
                       title: { type: 'string' },
                       requestedAt: { type: 'string', format: 'date-time' },
                       processed: { type: 'boolean' },
                     },
                   },
                 },
                 favoriteVenues: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       venueId: { type: 'string', format: 'uuid' },
                       venueName: { type: 'string' },
                       city: { type: 'string' },
                       state: { type: 'string' },
                       acceptingRequests: { type: 'boolean' },
                     },
                   },
                 },
                 recommendedSongs: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       artist: { type: 'string' },
                       title: { type: 'string' },
                       requestCount: { type: 'integer' },
                       lastRequested: { type: 'string', format: 'date-time' },
                     },
                   },
                 },
                 stats: {
                   type: 'object',
                   properties: {
                     totalRequests: { type: 'integer' },
                     totalFavoriteSongs: { type: 'integer' },
                     totalFavoriteVenues: { type: 'integer' },
                     requestsThisMonth: { type: 'integer' },
                   },
                 },
               },
             },
           },
         },
         preHandler: [server.authenticate],
       },
       async (request, reply) => {
         const userId = request.user.sub;

         const singerProfile = await server.prisma.singerProfile.findUnique({
           where: { userId },
         });

         if (!singerProfile) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Singer Profile Not Found',
             detail: 'No singer profile found for this user',
           });
         }

         const dashboard = await dashboardService.getDashboard(singerProfile.id);

         return reply.send(dashboard);
       }
     );

     // Get quick actions
     server.get(
       '/dashboard/quick-actions',
       {
         schema: {
           tags: ['singer'],
           summary: 'Get quick actions',
           description: 'Get recent venues and favorite songs for quick request submission',
           security: [{ bearerAuth: [] }],
           response: {
             200: {
               description: 'Quick actions data',
               type: 'object',
               properties: {
                 recentVenues: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       id: { type: 'string', format: 'uuid' },
                       name: { type: 'string' },
                       urlName: { type: 'string' },
                       city: { type: 'string' },
                       state: { type: 'string' },
                     },
                   },
                 },
                 favoriteSongs: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       id: { type: 'string', format: 'uuid' },
                       artist: { type: 'string' },
                       title: { type: 'string' },
                       keyChange: { type: 'integer' },
                     },
                   },
                 },
               },
             },
           },
         },
         preHandler: [server.authenticate],
       },
       async (request, reply) => {
         const userId = request.user.sub;

         const singerProfile = await server.prisma.singerProfile.findUnique({
           where: { userId },
         });

         if (!singerProfile) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Singer Profile Not Found',
             detail: 'No singer profile found for this user',
           });
         }

         const quickActions = await dashboardService.getQuickActions(
           singerProfile.id
         );

         return reply.send(quickActions);
       }
     );
   };
   ```

4. **Update singer routes to include dashboard:**
   ```typescript
   // Update apps/api/src/routes/singer/index.ts
   import { FastifyPluginAsync } from 'fastify';
   import { profileRoute } from './profile';
   import { requestsRoute } from './requests';
   import { accountRoute } from './account';
   import { historyRoute } from './history';
   import { favoritesRoute } from './favorites';
   import { dashboardRoute } from './dashboard';

   export const singerRoutes: FastifyPluginAsync = async (server) => {
     await server.register(profileRoute);
     await server.register(requestsRoute);
     await server.register(accountRoute);
     await server.register(historyRoute);
     await server.register(favoritesRoute);
     await server.register(dashboardRoute);
   };
   ```

**Deliverables:**
- ✅ `GET /v1/singer/dashboard` - Get personalized dashboard
- ✅ `GET /v1/singer/dashboard/quick-actions` - Get quick action data
- ✅ Recent requests (last 10)
- ✅ Favorite venues (top 5)
- ✅ Recommended songs based on history (top 5)
- ✅ Statistics (total requests, favorites, monthly requests)
- ✅ Recent venues for quick requests
- ✅ Favorite songs for quick requests

---

**End of Phase 7. Complete deliverables:**

### Phase 7 Summary

**Singer Personalization Features:**
- ✅ Request history with filters (venue, date, artist, title)
- ✅ Request statistics (total, unique songs/venues, most requested, favorite venue)
- ✅ Delete individual history items
- ✅ Clear all or partial history
- ✅ Favorite songs management (add, update, delete, list)
- ✅ Favorite venues management (add, remove, check, list)
- ✅ Personalized dashboard with recommendations
- ✅ Quick actions for fast request submission
- ✅ Search and filter capabilities
- ✅ Pagination on all list endpoints
- ✅ Duplicate detection for favorites
- ✅ Metadata support for custom fields on favorite songs

---

## Phase 8: Customer Venue Management

### 8.1 Venue CRUD Operations

**Objective:** Allow customers to create, view, update, and delete their venues.

**Duration:** 3 days  
**Team Size:** 1-2 developers

**Tasks:**

1. **Create venue schemas in `apps/api/src/routes/customer/schemas.ts`:**
   ```typescript
   import { z } from 'zod';
   import { PaginationSchema, AddressSchema, PhoneNumberSchema, WebsiteSchema } from '@singr/shared/validation';

   export const VenueListQuerySchema = PaginationSchema.extend({
     search: z.string().max(100).optional(),
     acceptingRequests: z.coerce.boolean().optional(),
   });

   export const CreateVenueSchema = AddressSchema.extend({
     name: z.string().min(1).max(255),
     phoneNumber: PhoneNumberSchema,
     website: WebsiteSchema,
     acceptingRequests: z.boolean().default(true),
   });

   export const UpdateVenueSchema = z.object({
     name: z.string().min(1).max(255).optional(),
     address: z.string().min(1).max(255).optional(),
     city: z.string().min(1).max(100).optional(),
     state: z.string().min(2).max(50).optional(),
     postalCode: z.string().min(1).max(20).optional(),
     country: z.string().max(50).optional(),
     phoneNumber: PhoneNumberSchema.optional(),
     website: WebsiteSchema.optional(),
     acceptingRequests: z.boolean().optional(),
   });

   export const VenueParamsSchema = z.object({
     id: z.string().uuid(),
   });

   export const VenueResponseSchema = z.object({
     id: z.string().uuid(),
     openkjVenueId: z.number(),
     urlName: z.string(),
     name: z.string(),
     address: z.string(),
     city: z.string(),
     state: z.string(),
     postalCode: z.string(),
     country: z.string().nullable(),
     phoneNumber: z.string().nullable(),
     website: z.string().nullable(),
     acceptingRequests: z.boolean(),
     createdAt: z.string().datetime(),
     updatedAt: z.string().datetime(),
   });
   ```

2. **Create venue service in `packages/shared/src/services/customer-venue-service.ts`:**
   ```typescript
   import { PrismaClient } from '@prisma/database';
   import { createLogger } from '@singr/observability';
   import axios from 'axios';

   const logger = createLogger('services:customer-venue');

   export interface VenueFilters {
     search?: string;
     acceptingRequests?: boolean;
   }

   export interface CreateVenueInput {
     customerProfileId: string;
     name: string;
     address: string;
     city: string;
     state: string;
     postalCode: string;
     country?: string;
     phoneNumber?: string;
     website?: string;
     acceptingRequests?: boolean;
   }

   export interface UpdateVenueInput {
     name?: string;
     address?: string;
     city?: string;
     state?: string;
     postalCode?: string;
     country?: string;
     phoneNumber?: string;
     website?: string;
     acceptingRequests?: boolean;
   }

   export class CustomerVenueService {
     constructor(private prisma: PrismaClient) {}

     async listVenues(
       customerProfileId: string,
       filters: VenueFilters,
       pagination: { page: number; limit: number }
     ) {
       const where: any = { customerProfileId };

       if (filters.search) {
         where.name = { contains: filters.search, mode: 'insensitive' };
       }

       if (filters.acceptingRequests !== undefined) {
         where.acceptingRequests = filters.acceptingRequests;
       }

       const [venues, total] = await Promise.all([
         this.prisma.venue.findMany({
           where,
           skip: (pagination.page - 1) * pagination.limit,
           take: pagination.limit,
           orderBy: { name: 'asc' },
         }),
         this.prisma.venue.count({ where }),
       ]);

       return {
         data: venues.map(this.formatVenue),
         pagination: {
           page: pagination.page,
           limit: pagination.limit,
           total,
           totalPages: Math.ceil(total / pagination.limit),
         },
       };
     }

     async getVenue(venueId: string, customerProfileId: string) {
       const venue = await this.prisma.venue.findFirst({
         where: {
           id: venueId,
           customerProfileId,
         },
       });

       if (!venue) {
         throw new Error('Venue not found');
       }

       return this.formatVenue(venue);
     }

     async createVenue(input: CreateVenueInput) {
       // Get next openkjVenueId from state table
       const state = await this.prisma.state.upsert({
         where: { customerProfileId: input.customerProfileId },
         create: {
           customerProfileId: input.customerProfileId,
           serial: BigInt(1001),
         },
         update: {
           serial: { increment: BigInt(1) },
         },
       });

       const openkjVenueId = Number(state.serial);

       // Generate URL-friendly name
       const urlName = this.generateUrlName(input.name);

       // Geocode address to get coordinates
       const location = await this.geocodeAddress(
         `${input.address}, ${input.city}, ${input.state} ${input.postalCode}`
       );

       // Create venue with raw SQL for PostGIS geography type
       const venue = await this.prisma.$queryRaw<any[]>`
         INSERT INTO venues (
           venues_id,
           customer_profiles_id,
           openkj_venue_id,
           url_name,
           accepting_requests,
           name,
           address,
           city,
           state,
           postal_code,
           country,
           phone_number,
           website,
           location,
           created_at,
           updated_at
         ) VALUES (
           gen_random_uuid(),
           ${input.customerProfileId}::uuid,
           ${openkjVenueId},
           ${urlName},
           ${input.acceptingRequests !== false},
           ${input.name},
           ${input.address},
           ${input.city},
           ${input.state},
           ${input.postalCode},
           ${input.country || 'USA'},
           ${input.phoneNumber || null},
           ${input.website || null},
           ${location ? `ST_SetSRID(ST_MakePoint(${location.lng}, ${location.lat}), 4326)::geography` : null},
           NOW(),
           NOW()
         )
         RETURNING *
       `;

       logger.info(
         {
           venueId: venue[0].venues_id,
           customerProfileId: input.customerProfileId,
           openkjVenueId,
           name: input.name,
         },
         'Venue created'
       );

       return this.formatVenue(venue[0]);
     }

     async updateVenue(
       venueId: string,
       customerProfileId: string,
       input: UpdateVenueInput
     ) {
       const venue = await this.prisma.venue.findFirst({
         where: {
           id: venueId,
           customerProfileId,
         },
       });

       if (!venue) {
         throw new Error('Venue not found');
       }

       const updateData: any = {};

       if (input.name !== undefined) updateData.name = input.name;
       if (input.address !== undefined) updateData.address = input.address;
       if (input.city !== undefined) updateData.city = input.city;
       if (input.state !== undefined) updateData.state = input.state;
       if (input.postalCode !== undefined) updateData.postalCode = input.postalCode;
       if (input.country !== undefined) updateData.country = input.country;
       if (input.phoneNumber !== undefined) updateData.phoneNumber = input.phoneNumber;
       if (input.website !== undefined) updateData.website = input.website;
       if (input.acceptingRequests !== undefined) {
         updateData.acceptingRequests = input.acceptingRequests;
       }

       // If address changed, update location
       if (input.address || input.city || input.state || input.postalCode) {
         const fullAddress = `${input.address || venue.address}, ${
           input.city || venue.city
         }, ${input.state || venue.state} ${input.postalCode || venue.postalCode}`;

         const location = await this.geocodeAddress(fullAddress);

         if (location) {
           await this.prisma.$executeRaw`
             UPDATE venues
             SET location = ST_SetSRID(ST_MakePoint(${location.lng}, ${location.lat}), 4326)::geography
             WHERE venues_id = ${venueId}::uuid
           `;
         }
       }

       const updated = await this.prisma.venue.update({
         where: { id: venueId },
         data: updateData,
       });

       logger.info(
         {
           venueId,
           customerProfileId,
         },
         'Venue updated'
       );

       return this.formatVenue(updated);
     }

     async deleteVenue(venueId: string, customerProfileId: string) {
       const venue = await this.prisma.venue.findFirst({
         where: {
           id: venueId,
           customerProfileId,
         },
       });

       if (!venue) {
         throw new Error('Venue not found');
       }

       await this.prisma.venue.delete({
         where: { id: venueId },
       });

       logger.info(
         {
           venueId,
           customerProfileId,
           name: venue.name,
         },
         'Venue deleted'
       );
     }

     private generateUrlName(name: string): string {
       return name
         .toLowerCase()
         .replace(/[^a-z0-9]+/g, '-')
         .replace(/^-+|-+$/g, '')
         .substring(0, 100);
     }

     private async geocodeAddress(
       address: string
     ): Promise<{ lat: number; lng: number } | null> {
       try {
         // Using a free geocoding service (nominatim)
         const response = await axios.get(
           'https://nominatim.openstreetmap.org/search',
           {
             params: {
               q: address,
               format: 'json',
               limit: 1,
             },
             headers: {
               'User-Agent': 'Singr-API/1.0',
             },
           }
         );

         if (response.data && response.data.length > 0) {
           return {
             lat: parseFloat(response.data[0].lat),
             lng: parseFloat(response.data[0].lon),
           };
         }

         logger.warn({ address }, 'Geocoding failed - no results');
         return null;
       } catch (error) {
         logger.error({ error, address }, 'Geocoding error');
         return null;
       }
     }

     private formatVenue(venue: any) {
       return {
         id: venue.id || venue.venues_id,
         openkjVenueId: Number(venue.openkjVenueId || venue.openkj_venue_id),
         urlName: venue.urlName || venue.url_name,
         name: venue.name,
         address: venue.address,
         city: venue.city,
         state: venue.state,
         postalCode: venue.postalCode || venue.postal_code,
         country: venue.country,
         phoneNumber: venue.phoneNumber || venue.phone_number,
         website: venue.website,
         acceptingRequests: venue.acceptingRequests ?? venue.accepting_requests,
         createdAt: (venue.createdAt || venue.created_at).toISOString
           ? (venue.createdAt || venue.created_at).toISOString()
           : new Date(venue.createdAt || venue.created_at).toISOString(),
         updatedAt: (venue.updatedAt || venue.updated_at).toISOString
           ? (venue.updatedAt || venue.updated_at).toISOString()
           : new Date(venue.updatedAt || venue.updated_at).toISOString(),
       };
     }
   }
   ```

3. **Implement venue routes in `apps/api/src/routes/customer/venues.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateQuery, validateParams, validateBody } from '@singr/shared/validation';
   import { requirePermission } from '@singr/auth';
   import {
     VenueListQuerySchema,
     CreateVenueSchema,
     UpdateVenueSchema,
     VenueParamsSchema,
   } from './schemas';
   import { CustomerVenueService } from '@singr/shared/services/customer-venue-service';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:customer:venues');

   export const venuesRoute: FastifyPluginAsync = async (server) => {
     const venueService = new CustomerVenueService(server.prisma);

     // List venues
     server.get(
       '/venues',
       {
         schema: {
           tags: ['customer'],
           summary: 'List venues',
           description: 'Get all venues for the customer',
           security: [{ bearerAuth: [] }],
           querystring: {
             type: 'object',
             properties: {
               page: { type: 'integer', minimum: 1, default: 1 },
               limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
               search: { type: 'string' },
               acceptingRequests: { type: 'boolean' },
             },
           },
           response: {
             200: {
               description: 'List of venues',
               type: 'object',
               properties: {
                 data: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       id: { type: 'string', format: 'uuid' },
                       name: { type: 'string' },
                       city: { type: 'string' },
                       state: { type: 'string' },
                       acceptingRequests: { type: 'boolean' },
                     },
                   },
                 },
                 pagination: {
                   type: 'object',
                   properties: {
                     page: { type: 'integer' },
                     limit: { type: 'integer' },
                     total: { type: 'integer' },
                     totalPages: { type: 'integer' },
                   },
                 },
               },
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('venues:read'),
           validateQuery(VenueListQuerySchema),
         ],
       },
       async (request, reply) => {
         const query = request.query as z.infer<typeof VenueListQuerySchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to access this resource',
           });
         }

         const { page, limit, ...filters } = query;

         const result = await venueService.listVenues(
           customerProfileId,
           filters,
           { page, limit }
         );

         return reply.send(result);
       }
     );

     // Get venue details
     server.get(
       '/venues/:id',
       {
         schema: {
           tags: ['customer'],
           summary: 'Get venue',
           description: 'Get details of a specific venue',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'Venue details',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 openkjVenueId: { type: 'integer' },
                 urlName: { type: 'string' },
                 name: { type: 'string' },
                 address: { type: 'string' },
                 city: { type: 'string' },
                 state: { type: 'string' },
                 acceptingRequests: { type: 'boolean' },
               },
             },
             404: {
               description: 'Venue not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('venues:read'),
           validateParams(VenueParamsSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof VenueParamsSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to access this resource',
           });
         }

         try {
           const venue = await venueService.getVenue(id, customerProfileId);
           return reply.send(venue);
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'Venue Not Found',
               detail: 'Venue not found or access denied',
             });
           }
           throw error;
         }
       }
     );

     // Create venue
     server.post(
       '/venues',
       {
         schema: {
           tags: ['customer'],
           summary: 'Create venue',
           description: 'Create a new venue',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['name', 'address', 'city', 'state', 'postalCode'],
             properties: {
               name: { type: 'string', minLength: 1, maxLength: 255 },
               address: { type: 'string', minLength: 1, maxLength: 255 },
               city: { type: 'string', minLength: 1, maxLength: 100 },
               state: { type: 'string', minLength: 2, maxLength: 50 },
               postalCode: { type: 'string', minLength: 1, maxLength: 20 },
               country: { type: 'string', maxLength: 50 },
               phoneNumber: { type: 'string' },
               website: { type: 'string', format: 'uri' },
               acceptingRequests: { type: 'boolean', default: true },
             },
           },
           response: {
             201: {
               description: 'Venue created',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 openkjVenueId: { type: 'integer' },
                 name: { type: 'string' },
                 urlName: { type: 'string' },
               },
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('venues:write'),
           validateBody(CreateVenueSchema),
         ],
       },
       async (request, reply) => {
         const body = request.body as z.infer<typeof CreateVenueSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to create venues',
           });
         }

         const venue = await venueService.createVenue({
           customerProfileId,
           ...body,
         });

         return reply.code(201).send(venue);
       }
     );

     // Update venue
     server.patch(
       '/venues/:id',
       {
         schema: {
           tags: ['customer'],
           summary: 'Update venue',
           description: 'Update venue information',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           body: {
             type: 'object',
             properties: {
               name: { type: 'string', minLength: 1, maxLength: 255 },
               address: { type: 'string', minLength: 1, maxLength: 255 },
               city: { type: 'string', minLength: 1, maxLength: 100 },
               state: { type: 'string', minLength: 2, maxLength: 50 },
               postalCode: { type: 'string', minLength: 1, maxLength: 20 },
               country: { type: 'string', maxLength: 50 },
               phoneNumber: { type: 'string' },
               website: { type: 'string', format: 'uri' },
               acceptingRequests: { type: 'boolean' },
             },
           },
           response: {
             200: {
               description: 'Venue updated',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 name: { type: 'string' },
                 acceptingRequests: { type: 'boolean' },
               },
             },
             404: {
               description: 'Venue not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('venues:write'),
           validateParams(VenueParamsSchema),
           validateBody(UpdateVenueSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof VenueParamsSchema>;
         const body = request.body as z.infer<typeof UpdateVenueSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to update venues',
           });
         }

         try {
           const venue = await venueService.updateVenue(id, customerProfileId, body);
           return reply.send(venue);
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'Venue Not Found',
               detail: 'Venue not found or access denied',
             });
           }
           throw error;
         }
       }
     );

     // Delete venue
     server.delete(
       '/venues/:id',
       {
         schema: {
           tags: ['customer'],
           summary: 'Delete venue',
           description: 'Delete a venue (also deletes associated requests)',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             204: {
               description: 'Venue deleted',
             },
             404: {
               description: 'Venue not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('venues:delete'),
           validateParams(VenueParamsSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof VenueParamsSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to delete venues',
           });
         }

         try {
           await venueService.deleteVenue(id, customerProfileId);
           return reply.code(204).send();
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'Venue Not Found',
               detail: 'Venue not found or access denied',
             });
           }
           throw error;
         }
       }
     );
   };
   ```

4. **Register customer routes in `apps/api/src/routes/customer/index.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { venuesRoute } from './venues';

   export const customerRoutes: FastifyPluginAsync = async (server) => {
     await server.register(venuesRoute);
   };
   ```

**Deliverables:**
- ✅ `GET /v1/customer/venues` - List all customer venues
- ✅ `POST /v1/customer/venues` - Create new venue
- ✅ `GET /v1/customer/venues/:id` - Get venue details
- ✅ `PATCH /v1/customer/venues/:id` - Update venue
- ✅ `DELETE /v1/customer/venues/:id` - Delete venue
- ✅ Auto-increment openkjVenueId via state table
- ✅ URL-friendly name generation
- ✅ Geocoding integration (OpenStreetMap Nominatim)
- ✅ PostGIS geography storage for location
- ✅ RBAC permission checks (venues:read, venues:write, venues:delete)
- ✅ Customer context validation
- ✅ Search and filter capabilities
- ✅ Pagination support

---

### 8.2 Venue Statistics & Analytics

**Objective:** Provide customers with insights and analytics for their venues.

**Duration:** 2-3 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create venue analytics schemas:**
   ```typescript
   // Add to apps/api/src/routes/customer/schemas.ts
   export const VenueStatsQuerySchema = z.object({
     startDate: z.string().datetime().optional(),
     endDate: z.string().datetime().optional(),
   });

   export const VenueStatsResponseSchema = z.object({
     venueId: z.string().uuid(),
     venueName: z.string(),
     stats: z.object({
       totalRequests: z.number(),
       pendingRequests: z.number(),
       processedRequests: z.number(),
       uniqueSingers: z.number(),
       averageRequestsPerDay: z.number(),
     }),
     topSongs: z.array(
       z.object({
         artist: z.string(),
         title: z.string(),
         requestCount: z.number(),
       })
     ),
     topSingers: z.array(
       z.object({
         singerId: z.string().uuid().nullable(),
         singerName: z.string().nullable(),
         requestCount: z.number(),
       })
     ),
     requestsByDay: z.array(
       z.object({
         date: z.string().date(),
         count: z.number(),
       })
     ),
     requestsByHour: z.array(
       z.object({
         hour: z.number(),
         count: z.number(),
       })
     ),
   });

   export const AllVenuesStatsResponseSchema = z.object({
     totalVenues: z.number(),
     totalRequests: z.number(),
     pendingRequests: z.number(),
     processedRequests: z.number(),
     venuesAcceptingRequests: z.number(),
     totalSongs: z.number(),
     topPerformingVenue: z
       .object({
         venueId: z.string().uuid(),
         venueName: z.string(),
         requestCount: z.number(),
       })
       .nullable(),
   });
   ```

2. **Create venue analytics service in `packages/shared/src/services/venue-analytics-service.ts`:**
   ```typescript
   import { PrismaClient } from '@prisma/database';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('services:venue-analytics');

   export interface AnalyticsDateRange {
     startDate?: Date;
     endDate?: Date;
   }

   export class VenueAnalyticsService {
     constructor(private prisma: PrismaClient) {}

     async getVenueStats(
       venueId: string,
       customerProfileId: string,
       dateRange?: AnalyticsDateRange
     ) {
       // Verify venue ownership
       const venue = await this.prisma.venue.findFirst({
         where: {
           id: venueId,
           customerProfileId,
         },
       });

       if (!venue) {
         throw new Error('Venue not found');
       }

       const where: any = { venueId };

       if (dateRange?.startDate) {
         where.requestedAt = { gte: dateRange.startDate };
       }

       if (dateRange?.endDate) {
         where.requestedAt = {
           ...where.requestedAt,
           lte: dateRange.endDate,
         };
       }

       // Basic stats
       const [totalRequests, pendingRequests, processedRequests, uniqueSingers] =
         await Promise.all([
           this.prisma.request.count({ where }),
           this.prisma.request.count({
             where: { ...where, processed: false },
           }),
           this.prisma.request.count({
             where: { ...where, processed: true },
           }),
           this.prisma.request
             .groupBy({
               by: ['singerProfileId'],
               where: {
                 ...where,
                 singerProfileId: { not: null },
               },
             })
             .then((groups) => groups.length),
         ]);

       // Calculate average requests per day
       const dateRangeDays = dateRange?.startDate && dateRange?.endDate
         ? Math.ceil(
             (dateRange.endDate.getTime() - dateRange.startDate.getTime()) /
               (1000 * 60 * 60 * 24)
           )
         : 30; // Default to 30 days

       const averageRequestsPerDay =
         dateRangeDays > 0 ? totalRequests / dateRangeDays : 0;

       // Top songs
       const topSongs = await this.prisma.request.groupBy({
         by: ['artist', 'title'],
         where,
         _count: { id: true },
         orderBy: { _count: { id: 'desc' } },
         take: 10,
       });

       // Top singers
       const topSingersData = await this.prisma.request.groupBy({
         by: ['singerProfileId', 'submittedByUserId'],
         where: {
           ...where,
           singerProfileId: { not: null },
         },
         _count: { id: true },
         orderBy: { _count: { id: 'desc' } },
         take: 10,
       });

       const singerIds = topSingersData
         .map((s) => s.singerProfileId)
         .filter((id): id is string => id !== null);

       const singerProfiles = await this.prisma.singerProfile.findMany({
         where: { id: { in: singerIds } },
         select: {
           id: true,
           nickname: true,
           user: {
             select: { name: true },
           },
         },
       });

       const singerMap = new Map(
         singerProfiles.map((sp) => [
           sp.id,
           sp.nickname || sp.user.name || 'Unknown',
         ])
       );

       const topSingers = topSingersData.map((s) => ({
         singerId: s.singerProfileId,
         singerName: s.singerProfileId ? singerMap.get(s.singerProfileId) || 'Unknown' : 'Guest',
         requestCount: s._count.id,
       }));

       // Requests by day
       const requestsByDayData = await this.prisma.$queryRaw<
         Array<{ date: Date; count: bigint }>
       >`
         SELECT 
           DATE(requested_at) as date,
           COUNT(*)::bigint as count
         FROM requests
         WHERE venues_id = ${venueId}::uuid
           ${dateRange?.startDate ? this.prisma.$queryRawUnsafe`AND requested_at >= '${dateRange.startDate.toISOString()}'` : this.prisma.$queryRawUnsafe``}
           ${dateRange?.endDate ? this.prisma.$queryRawUnsafe`AND requested_at <= '${dateRange.endDate.toISOString()}'` : this.prisma.$queryRawUnsafe``}
         GROUP BY DATE(requested_at)
         ORDER BY date DESC
         LIMIT 30
       `;

       const requestsByDay = requestsByDayData.map((r) => ({
         date: r.date.toISOString().split('T')[0],
         count: Number(r.count),
       }));

       // Requests by hour of day
       const requestsByHourData = await this.prisma.$queryRaw<
         Array<{ hour: number; count: bigint }>
       >`
         SELECT 
           EXTRACT(HOUR FROM requested_at)::integer as hour,
           COUNT(*)::bigint as count
         FROM requests
         WHERE venues_id = ${venueId}::uuid
           ${dateRange?.startDate ? this.prisma.$queryRawUnsafe`AND requested_at >= '${dateRange.startDate.toISOString()}'` : this.prisma.$queryRawUnsafe``}
           ${dateRange?.endDate ? this.prisma.$queryRawUnsafe`AND requested_at <= '${dateRange.endDate.toISOString()}'` : this.prisma.$queryRawUnsafe``}
         GROUP BY EXTRACT(HOUR FROM requested_at)
         ORDER BY hour
       `;

       const requestsByHour = requestsByHourData.map((r) => ({
         hour: r.hour,
         count: Number(r.count),
       }));

       logger.debug(
         {
           venueId,
           totalRequests,
           dateRange,
         },
         'Venue stats calculated'
       );

       return {
         venueId: venue.id,
         venueName: venue.name,
         stats: {
           totalRequests,
           pendingRequests,
           processedRequests,
           uniqueSingers,
           averageRequestsPerDay: parseFloat(averageRequestsPerDay.toFixed(2)),
         },
         topSongs: topSongs.map((s) => ({
           artist: s.artist,
           title: s.title,
           requestCount: s._count.id,
         })),
         topSingers,
         requestsByDay,
         requestsByHour,
       };
     }

     async getAllVenuesStats(customerProfileId: string) {
       const [
         venues,
         totalRequests,
         pendingRequests,
         processedRequests,
         venuesAcceptingRequests,
         totalSongs,
       ] = await Promise.all([
         this.prisma.venue.findMany({
           where: { customerProfileId },
           select: { id: true, name: true },
         }),
         this.prisma.request.count({
           where: {
             venue: { customerProfileId },
           },
         }),
         this.prisma.request.count({
           where: {
             venue: { customerProfileId },
             processed: false,
           },
         }),
         this.prisma.request.count({
           where: {
             venue: { customerProfileId },
             processed: true,
           },
         }),
         this.prisma.venue.count({
           where: {
             customerProfileId,
             acceptingRequests: true,
           },
         }),
         this.prisma.songDb.count({
           where: { customerProfileId },
         }),
       ]);

       // Top performing venue
       const venueRequestCounts = await this.prisma.request.groupBy({
         by: ['venueId'],
         where: {
           venue: { customerProfileId },
         },
         _count: { id: true },
         orderBy: { _count: { id: 'desc' } },
         take: 1,
       });

       let topPerformingVenue = null;
       if (venueRequestCounts.length > 0) {
         const topVenue = venues.find(
           (v) => v.id === venueRequestCounts[0].venueId
         );

         if (topVenue) {
           topPerformingVenue = {
             venueId: topVenue.id,
             venueName: topVenue.name,
             requestCount: venueRequestCounts[0]._count.id,
           };
         }
       }

       logger.debug(
         {
           customerProfileId,
           totalVenues: venues.length,
           totalRequests,
         },
         'All venues stats calculated'
       );

       return {
         totalVenues: venues.length,
         totalRequests,
         pendingRequests,
         processedRequests,
         venuesAcceptingRequests,
         totalSongs,
         topPerformingVenue,
       };
     }

     async exportVenueData(
       venueId: string,
       customerProfileId: string,
       dateRange?: AnalyticsDateRange
     ) {
       // Verify venue ownership
       const venue = await this.prisma.venue.findFirst({
         where: {
           id: venueId,
           customerProfileId,
         },
       });

       if (!venue) {
         throw new Error('Venue not found');
       }

       const where: any = { venueId };

       if (dateRange?.startDate) {
         where.requestedAt = { gte: dateRange.startDate };
       }

       if (dateRange?.endDate) {
         where.requestedAt = {
           ...where.requestedAt,
           lte: dateRange.endDate,
         };
       }

       const requests = await this.prisma.request.findMany({
         where,
         orderBy: { requestedAt: 'desc' },
         include: {
           singerProfile: {
             select: {
               nickname: true,
               user: {
                 select: { name: true, email: true },
               },
             },
           },
         },
       });

       logger.info(
         {
           venueId,
           customerProfileId,
           count: requests.length,
         },
         'Venue data exported'
       );

       return requests.map((r) => ({
         id: Number(r.id),
         artist: r.artist,
         title: r.title,
         keyChange: r.keyChange,
         notes: r.notes,
         singerName: r.singerProfile
           ? r.singerProfile.nickname || r.singerProfile.user.name
           : 'Guest',
         requestedAt: r.requestedAt.toISOString(),
         processed: r.processed,
         processedAt: r.processedAt?.toISOString() || null,
       }));
     }
   }
   ```

3. **Implement venue analytics routes in `apps/api/src/routes/customer/venues.ts`:**
   ```typescript
   // Add to existing venuesRoute

   import { VenueAnalyticsService } from '@singr/shared/services/venue-analytics-service';

   const analyticsService = new VenueAnalyticsService(server.prisma);

   // Get venue statistics
   server.get(
     '/venues/:id/stats',
     {
       schema: {
         tags: ['customer'],
         summary: 'Get venue statistics',
         description: 'Get analytics and statistics for a specific venue',
         security: [{ bearerAuth: [] }],
         params: {
           type: 'object',
           properties: {
             id: { type: 'string', format: 'uuid' },
           },
         },
         querystring: {
           type: 'object',
           properties: {
             startDate: { type: 'string', format: 'date-time' },
             endDate: { type: 'string', format: 'date-time' },
           },
         },
         response: {
           200: {
             description: 'Venue statistics',
             type: 'object',
             properties: {
               venueId: { type: 'string', format: 'uuid' },
               venueName: { type: 'string' },
               stats: {
                 type: 'object',
                 properties: {
                   totalRequests: { type: 'integer' },
                   pendingRequests: { type: 'integer' },
                   processedRequests: { type: 'integer' },
                   uniqueSingers: { type: 'integer' },
                   averageRequestsPerDay: { type: 'number' },
                 },
               },
               topSongs: {
                 type: 'array',
                 items: {
                   type: 'object',
                   properties: {
                     artist: { type: 'string' },
                     title: { type: 'string' },
                     requestCount: { type: 'integer' },
                   },
                 },
               },
               topSingers: {
                 type: 'array',
                 items: {
                   type: 'object',
                   properties: {
                     singerId: { type: 'string', format: 'uuid' },
                     singerName: { type: 'string' },
                     requestCount: { type: 'integer' },
                   },
                 },
               },
               requestsByDay: {
                 type: 'array',
                 items: {
                   type: 'object',
                   properties: {
                     date: { type: 'string', format: 'date' },
                     count: { type: 'integer' },
                   },
                 },
               },
               requestsByHour: {
                 type: 'array',
                 items: {
                   type: 'object',
                   properties: {
                     hour: { type: 'integer' },
                     count: { type: 'integer' },
                   },
                 },
               },
             },
           },
           404: {
             description: 'Venue not found',
           },
         },
       },
       preHandler: [
         server.authenticate,
         requirePermission('venues:read'),
         validateParams(VenueParamsSchema),
         validateQuery(VenueStatsQuerySchema),
       ],
     },
     async (request, reply) => {
       const { id } = request.params as z.infer<typeof VenueParamsSchema>;
       const { startDate, endDate } = request.query as z.infer<
         typeof VenueStatsQuerySchema
       >;
       const customerProfileId = request.user.activeContext?.id;

       if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
         return reply.code(403).send({
           type: 'authorization_denied',
           title: 'Customer Context Required',
           detail: 'You must be in a customer context to access venue statistics',
         });
       }

       try {
         const stats = await analyticsService.getVenueStats(
           id,
           customerProfileId,
           {
             startDate: startDate ? new Date(startDate) : undefined,
             endDate: endDate ? new Date(endDate) : undefined,
           }
         );

         return reply.send(stats);
       } catch (error) {
         if (error instanceof Error && error.message.includes('not found')) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Venue Not Found',
             detail: 'Venue not found or access denied',
           });
         }
         throw error;
       }
     }
   );

   // Get all venues statistics
   server.get(
     '/venues/stats/overview',
     {
       schema: {
         tags: ['customer'],
         summary: 'Get overview statistics',
         description: 'Get aggregate statistics for all venues',
         security: [{ bearerAuth: [] }],
         response: {
           200: {
             description: 'Overview statistics',
             type: 'object',
             properties: {
               totalVenues: { type: 'integer' },
               totalRequests: { type: 'integer' },
               pendingRequests: { type: 'integer' },
               processedRequests: { type: 'integer' },
               venuesAcceptingRequests: { type: 'integer' },
               totalSongs: { type: 'integer' },
               topPerformingVenue: {
                 type: 'object',
                 properties: {
                   venueId: { type: 'string', format: 'uuid' },
                   venueName: { type: 'string' },
                   requestCount: { type: 'integer' },
                 },
               },
             },
           },
         },
       },
       preHandler: [server.authenticate, requirePermission('venues:read')],
     },
     async (request, reply) => {
       const customerProfileId = request.user.activeContext?.id;

       if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
         return reply.code(403).send({
           type: 'authorization_denied',
           title: 'Customer Context Required',
           detail: 'You must be in a customer context to access statistics',
         });
       }

       const stats = await analyticsService.getAllVenuesStats(customerProfileId);

       return reply.send(stats);
     }
   );

   // Export venue data
   server.get(
     '/venues/:id/export',
     {
       schema: {
         tags: ['customer'],
         summary: 'Export venue data',
         description: 'Export all request data for a venue as JSON',
         security: [{ bearerAuth: [] }],
         params: {
           type: 'object',
           properties: {
             id: { type: 'string', format: 'uuid' },
           },
         },
         querystring: {
           type: 'object',
           properties: {
             startDate: { type: 'string', format: 'date-time' },
             endDate: { type: 'string', format: 'date-time' },
           },
         },
         response: {
           200: {
             description: 'Exported venue data',
             type: 'array',
             items: {
               type: 'object',
               properties: {
                 id: { type: 'integer' },
                 artist: { type: 'string' },
                 title: { type: 'string' },
                 keyChange: { type: 'integer' },
                 notes: { type: 'string' },
                 singerName: { type: 'string' },
                 requestedAt: { type: 'string', format: 'date-time' },
                 processed: { type: 'boolean' },
                 processedAt: { type: 'string', format: 'date-time' },
               },
             },
           },
           404: {
             description: 'Venue not found',
           },
         },
       },
       preHandler: [
         server.authenticate,
         requirePermission('venues:read'),
         validateParams(VenueParamsSchema),
         validateQuery(VenueStatsQuerySchema),
       ],
       config: {
         rateLimit: {
           max: 10,
           timeWindow: '1 hour',
         },
       },
     },
     async (request, reply) => {
       const { id } = request.params as z.infer<typeof VenueParamsSchema>;
       const { startDate, endDate } = request.query as z.infer<
         typeof VenueStatsQuerySchema
       >;
       const customerProfileId = request.user.activeContext?.id;

       if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
         return reply.code(403).send({
           type: 'authorization_denied',
           title: 'Customer Context Required',
           detail: 'You must be in a customer context to export venue data',
         });
       }

       try {
         const data = await analyticsService.exportVenueData(id, customerProfileId, {
           startDate: startDate ? new Date(startDate) : undefined,
           endDate: endDate ? new Date(endDate) : undefined,
         });

         // Set headers for download
         reply.header('Content-Type', 'application/json');
         reply.header(
           'Content-Disposition',
           `attachment; filename="venue-export-${id}-${new Date().toISOString().split('T')[0]}.json"`
         );

         return reply.send(data);
       } catch (error) {
         if (error instanceof Error && error.message.includes('not found')) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Venue Not Found',
             detail: 'Venue not found or access denied',
           });
         }
         throw error;
       }
     }
   );
   ```

**Deliverables:**
- ✅ `GET /v1/customer/venues/:id/stats` - Get detailed venue statistics
- ✅ `GET /v1/customer/venues/stats/overview` - Get aggregate statistics for all venues
- ✅ `GET /v1/customer/venues/:id/export` - Export venue request data
- ✅ Date range filtering for all analytics
- ✅ Request statistics (total, pending, processed)
- ✅ Unique singer count
- ✅ Average requests per day
- ✅ Top 10 requested songs
- ✅ Top 10 singers by request count
- ✅ Requests by day (last 30 days)
- ✅ Requests by hour of day
- ✅ Top performing venue across all venues
- ✅ Total song count in database
- ✅ JSON export with rate limiting
- ✅ Download headers for exported data

---

## Phase 9: Customer Systems & Songdb Management

### 9.1 System Management

**Objective:** Allow customers to manage their karaoke systems.

**Duration:** 2 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create system schemas in `apps/api/src/routes/customer/schemas.ts`:**
   ```typescript
   // Add to existing schemas
   export const SystemListQuerySchema = PaginationSchema.extend({
     search: z.string().max(100).optional(),
   });

   export const CreateSystemSchema = z.object({
     name: z.string().min(1).max(255),
     configuration: z.record(z.any()).optional(),
   });

   export const UpdateSystemSchema = z.object({
     name: z.string().min(1).max(255).optional(),
     configuration: z.record(z.any()).optional(),
   });

   export const SystemParamsSchema = z.object({
     id: z.string().uuid(),
   });

   export const SystemResponseSchema = z.object({
     id: z.string().uuid(),
     openkjSystemId: z.number(),
     name: z.string(),
     configuration: z.record(z.any()),
     songCount: z.number(),
     createdAt: z.string().datetime(),
     updatedAt: z.string().datetime(),
   });
   ```

2. **Create system service in `packages/shared/src/services/customer-system-service.ts`:**
   ```typescript
   import { PrismaClient } from '@prisma/database';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('services:customer-system');

   export interface SystemFilters {
     search?: string;
   }

   export interface CreateSystemInput {
     customerProfileId: string;
     name: string;
     configuration?: Record<string, any>;
   }

   export interface UpdateSystemInput {
     name?: string;
     configuration?: Record<string, any>;
   }

   export class CustomerSystemService {
     constructor(private prisma: PrismaClient) {}

     async listSystems(
       customerProfileId: string,
       filters: SystemFilters,
       pagination: { page: number; limit: number }
     ) {
       const where: any = { customerProfileId };

       if (filters.search) {
         where.name = { contains: filters.search, mode: 'insensitive' };
       }

       const [systems, total] = await Promise.all([
         this.prisma.system.findMany({
           where,
           skip: (pagination.page - 1) * pagination.limit,
           take: pagination.limit,
           orderBy: { name: 'asc' },
         }),
         this.prisma.system.count({ where }),
       ]);

       // Get song counts for each system
       const systemIds = systems.map((s) => s.openkjSystemId);
       const songCounts = await this.prisma.songDb.groupBy({
         by: ['openkjSystemId'],
         where: {
           customerProfileId,
           openkjSystemId: { in: systemIds },
         },
         _count: { id: true },
       });

       const songCountMap = new Map(
         songCounts.map((sc) => [sc.openkjSystemId, sc._count.id])
       );

       return {
         data: systems.map((s) => ({
           id: s.id,
           openkjSystemId: s.openkjSystemId,
           name: s.name,
           configuration: s.configuration || {},
           songCount: songCountMap.get(s.openkjSystemId) || 0,
           createdAt: s.createdAt.toISOString(),
           updatedAt: s.updatedAt.toISOString(),
         })),
         pagination: {
           page: pagination.page,
           limit: pagination.limit,
           total,
           totalPages: Math.ceil(total / pagination.limit),
         },
       };
     }

     async getSystem(systemId: string, customerProfileId: string) {
       const system = await this.prisma.system.findFirst({
         where: {
           id: systemId,
           customerProfileId,
         },
       });

       if (!system) {
         throw new Error('System not found');
       }

       // Get song count
       const songCount = await this.prisma.songDb.count({
         where: {
           customerProfileId,
           openkjSystemId: system.openkjSystemId,
         },
       });

       return {
         id: system.id,
         openkjSystemId: system.openkjSystemId,
         name: system.name,
         configuration: system.configuration || {},
         songCount,
         createdAt: system.createdAt.toISOString(),
         updatedAt: system.updatedAt.toISOString(),
       };
     }

     async createSystem(input: CreateSystemInput) {
       // Get next openkjSystemId from state table
       const state = await this.prisma.state.upsert({
         where: { customerProfileId: input.customerProfileId },
         create: {
           customerProfileId: input.customerProfileId,
           serial: BigInt(1001),
         },
         update: {
           serial: { increment: BigInt(1) },
         },
       });

       const openkjSystemId = Number(state.serial);

       const system = await this.prisma.system.create({
         data: {
           customerProfileId: input.customerProfileId,
           openkjSystemId,
           name: input.name,
           configuration: input.configuration || {},
         },
       });

       logger.info(
         {
           systemId: system.id,
           customerProfileId: input.customerProfileId,
           openkjSystemId,
           name: input.name,
         },
         'System created'
       );

       return {
         id: system.id,
         openkjSystemId: system.openkjSystemId,
         name: system.name,
         configuration: system.configuration || {},
         songCount: 0,
         createdAt: system.createdAt.toISOString(),
         updatedAt: system.updatedAt.toISOString(),
       };
     }

     async updateSystem(
       systemId: string,
       customerProfileId: string,
       input: UpdateSystemInput
     ) {
       const system = await this.prisma.system.findFirst({
         where: {
           id: systemId,
           customerProfileId,
         },
       });

       if (!system) {
         throw new Error('System not found');
       }

       const updateData: any = {};

       if (input.name !== undefined) updateData.name = input.name;
       if (input.configuration !== undefined) {
         updateData.configuration = {
           ...system.configuration,
           ...input.configuration,
         };
       }

       const updated = await this.prisma.system.update({
         where: { id: systemId },
         data: updateData,
       });

       // Get song count
       const songCount = await this.prisma.songDb.count({
         where: {
           customerProfileId,
           openkjSystemId: updated.openkjSystemId,
         },
       });

       logger.info(
         {
           systemId,
           customerProfileId,
         },
         'System updated'
       );

       return {
         id: updated.id,
         openkjSystemId: updated.openkjSystemId,
         name: updated.name,
         configuration: updated.configuration || {},
         songCount,
         createdAt: updated.createdAt.toISOString(),
         updatedAt: updated.updatedAt.toISOString(),
       };
     }

     async deleteSystem(systemId: string, customerProfileId: string) {
       const system = await this.prisma.system.findFirst({
         where: {
           id: systemId,
           customerProfileId,
         },
       });

       if (!system) {
         throw new Error('System not found');
       }

       // Check if system has songs
       const songCount = await this.prisma.songDb.count({
         where: {
           customerProfileId,
           openkjSystemId: system.openkjSystemId,
         },
       });

       if (songCount > 0) {
         throw new Error(
           `Cannot delete system with ${songCount} songs. Please delete all songs first.`
         );
       }

       await this.prisma.system.delete({
         where: { id: systemId },
       });

       logger.info(
         {
           systemId,
           customerProfileId,
           name: system.name,
         },
         'System deleted'
       );
     }
   }
   ```

3. **Implement system routes in `apps/api/src/routes/customer/systems.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateQuery, validateParams, validateBody } from '@singr/shared/validation';
   import { requirePermission } from '@singr/auth';
   import {
     SystemListQuerySchema,
     CreateSystemSchema,
     UpdateSystemSchema,
     SystemParamsSchema,
   } from './schemas';
   import { CustomerSystemService } from '@singr/shared/services/customer-system-service';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:customer:systems');

   export const systemsRoute: FastifyPluginAsync = async (server) => {
     const systemService = new CustomerSystemService(server.prisma);

     // List systems
     server.get(
       '/systems',
       {
         schema: {
           tags: ['customer'],
           summary: 'List systems',
           description: 'Get all karaoke systems for the customer',
           security: [{ bearerAuth: [] }],
           querystring: {
             type: 'object',
             properties: {
               page: { type: 'integer', minimum: 1, default: 1 },
               limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
               search: { type: 'string' },
             },
           },
           response: {
             200: {
               description: 'List of systems',
               type: 'object',
               properties: {
                 data: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       id: { type: 'string', format: 'uuid' },
                       openkjSystemId: { type: 'integer' },
                       name: { type: 'string' },
                       songCount: { type: 'integer' },
                       createdAt: { type: 'string', format: 'date-time' },
                     },
                   },
                 },
                 pagination: {
                   type: 'object',
                   properties: {
                     page: { type: 'integer' },
                     limit: { type: 'integer' },
                     total: { type: 'integer' },
                     totalPages: { type: 'integer' },
                   },
                 },
               },
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('systems:read'),
           validateQuery(SystemListQuerySchema),
         ],
       },
       async (request, reply) => {
         const query = request.query as z.infer<typeof SystemListQuerySchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to access this resource',
           });
         }

         const { page, limit, ...filters } = query;

         const result = await systemService.listSystems(
           customerProfileId,
           filters,
           { page, limit }
         );

         return reply.send(result);
       }
     );

     // Get system details
     server.get(
       '/systems/:id',
       {
         schema: {
           tags: ['customer'],
           summary: 'Get system',
           description: 'Get details of a specific system',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'System details',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 openkjSystemId: { type: 'integer' },
                 name: { type: 'string' },
                 configuration: { type: 'object' },
                 songCount: { type: 'integer' },
                 createdAt: { type: 'string', format: 'date-time' },
               },
             },
             404: {
               description: 'System not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('systems:read'),
           validateParams(SystemParamsSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof SystemParamsSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to access this resource',
           });
         }

         try {
           const system = await systemService.getSystem(id, customerProfileId);
           return reply.send(system);
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'System Not Found',
               detail: 'System not found or access denied',
             });
           }
           throw error;
         }
       }
     );

     // Create system
     server.post(
       '/systems',
       {
         schema: {
           tags: ['customer'],
           summary: 'Create system',
           description: 'Create a new karaoke system',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['name'],
             properties: {
               name: { type: 'string', minLength: 1, maxLength: 255 },
               configuration: { type: 'object' },
             },
           },
           response: {
             201: {
               description: 'System created',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 openkjSystemId: { type: 'integer' },
                 name: { type: 'string' },
                 songCount: { type: 'integer' },
               },
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('systems:write'),
           validateBody(CreateSystemSchema),
         ],
       },
       async (request, reply) => {
         const body = request.body as z.infer<typeof CreateSystemSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to create systems',
           });
         }

         const system = await systemService.createSystem({
           customerProfileId,
           ...body,
         });

         return reply.code(201).send(system);
       }
     );

     // Update system
     server.patch(
       '/systems/:id',
       {
         schema: {
           tags: ['customer'],
           summary: 'Update system',
           description: 'Update system information',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           body: {
             type: 'object',
             properties: {
               name: { type: 'string', minLength: 1, maxLength: 255 },
               configuration: { type: 'object' },
             },
           },
           response: {
             200: {
               description: 'System updated',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 name: { type: 'string' },
                 configuration: { type: 'object' },
               },
             },
             404: {
               description: 'System not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('systems:write'),
           validateParams(SystemParamsSchema),
           validateBody(UpdateSystemSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof SystemParamsSchema>;
         const body = request.body as z.infer<typeof UpdateSystemSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to update systems',
           });
         }

         try {
           const system = await systemService.updateSystem(id, customerProfileId, body);
           return reply.send(system);
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'System Not Found',
               detail: 'System not found or access denied',
             });
           }
           throw error;
         }
       }
     );

     // Delete system
     server.delete(
       '/systems/:id',
       {
         schema: {
           tags: ['customer'],
           summary: 'Delete system',
           description: 'Delete a system (must have no songs)',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             204: {
               description: 'System deleted',
             },
             404: {
               description: 'System not found',
             },
             409: {
               description: 'System has songs and cannot be deleted',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('systems:write'),
           validateParams(SystemParamsSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof SystemParamsSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to delete systems',
           });
         }

         try {
           await systemService.deleteSystem(id, customerProfileId);
           return reply.code(204).send();
         } catch (error) {
           if (error instanceof Error) {
             if (error.message.includes('not found')) {
               return reply.code(404).send({
                 type: 'resource_not_found',
                 title: 'System Not Found',
                 detail: 'System not found or access denied',
               });
             }
             if (error.message.includes('Cannot delete')) {
               return reply.code(409).send({
                 type: 'conflict',
                 title: 'System Has Songs',
                 detail: error.message,
               });
             }
           }
           throw error;
         }
       }
     );
   };
   ```

4. **Register systems route in `apps/api/src/routes/customer/index.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { venuesRoute } from './venues';
   import { systemsRoute } from './systems';

   export const customerRoutes: FastifyPluginAsync = async (server) => {
     await server.register(venuesRoute);
     await server.register(systemsRoute);
   };
   ```

**Deliverables:**
- ✅ `GET /v1/customer/systems` - List all systems
- ✅ `POST /v1/customer/systems` - Create new system
- ✅ `GET /v1/customer/systems/:id` - Get system details
- ✅ `PATCH /v1/customer/systems/:id` - Update system
- ✅ `DELETE /v1/customer/systems/:id` - Delete system (if no songs)
- ✅ Auto-increment openkjSystemId via state table
- ✅ Song count included in responses
- ✅ Configuration JSON storage
- ✅ Delete protection when songs exist
- ✅ RBAC permission checks (systems:read, systems:write)
- ✅ Customer context validation
- ✅ Search functionality
- ✅ Pagination support

---

### 9.2 Song Database Management

**Objective:** Allow customers to manage their song databases with bulk import/export capabilities.

**Duration:** 3-4 days  
**Team Size:** 1-2 developers

**Tasks:**

1. **Create songdb schemas in `apps/api/src/routes/customer/schemas.ts`:**
   ```typescript
   // Add to existing schemas
   export const SongDbQuerySchema = PaginationSchema.extend({
     systemId: z.string().uuid().optional(),
     search: z.string().max(200).optional(),
     artist: z.string().max(100).optional(),
     title: z.string().max(100).optional(),
     letter: z.string().length(1).optional(),
   });

   export const AddSongSchema = z.object({
     systemId: z.string().uuid(),
     artist: z.string().min(1).max(255),
     title: z.string().min(1).max(255),
   });

   export const BulkAddSongsSchema = z.object({
     systemId: z.string().uuid(),
     songs: z
       .array(
         z.object({
           artist: z.string().min(1).max(255),
           title: z.string().min(1).max(255),
         })
       )
       .min(1)
       .max(10000),
   });

   export const UpdateSongSchema = z.object({
     artist: z.string().min(1).max(255).optional(),
     title: z.string().min(1).max(255).optional(),
   });

   export const SongParamsSchema = z.object({
     id: z.coerce.number().int().positive(),
   });

   export const SongResponseSchema = z.object({
     id: z.number(),
     systemId: z.string().uuid(),
     systemName: z.string(),
     artist: z.string(),
     title: z.string(),
     combined: z.string(),
     createdAt: z.string().datetime(),
     updatedAt: z.string().datetime(),
   });

   export const ImportSongsSchema = z.object({
     systemId: z.string().uuid(),
     format: z.enum(['csv', 'json', 'txt']),
     data: z.string(),
   });
   ```

2. **Create song database service in `packages/shared/src/services/songdb-service.ts`:**
   ```typescript
   import { PrismaClient } from '@prisma/database';
   import { createLogger } from '@singr/observability';
   import Papa from 'papaparse';

   const logger = createLogger('services:songdb');

   export interface SongDbFilters {
     systemId?: string;
     search?: string;
     artist?: string;
     title?: string;
     letter?: string;
   }

   export interface AddSongInput {
     customerProfileId: string;
     systemId: string;
     artist: string;
     title: string;
   }

   export interface BulkAddSongsInput {
     customerProfileId: string;
     systemId: string;
     songs: Array<{ artist: string; title: string }>;
   }

   export class SongDbService {
     constructor(private prisma: PrismaClient) {}

     async listSongs(
       customerProfileId: string,
       filters: SongDbFilters,
       pagination: { page: number; limit: number }
     ) {
       const where: any = { customerProfileId };

       if (filters.systemId) {
         const system = await this.prisma.system.findFirst({
           where: {
             id: filters.systemId,
             customerProfileId,
           },
         });

         if (system) {
           where.openkjSystemId = system.openkjSystemId;
         }
       }

       if (filters.search) {
         where.normalizedCombined = {
           contains: filters.search.toLowerCase(),
           mode: 'insensitive' as const,
         };
       }

       if (filters.artist) {
         where.artist = { contains: filters.artist, mode: 'insensitive' as const };
       }

       if (filters.title) {
         where.title = { contains: filters.title, mode: 'insensitive' as const };
       }

       if (filters.letter) {
         where.artist = {
           ...where.artist,
           startsWith: filters.letter.toUpperCase(),
         };
       }

       const [songs, total] = await Promise.all([
         this.prisma.songDb.findMany({
           where,
           skip: (pagination.page - 1) * pagination.limit,
           take: pagination.limit,
           orderBy: [{ artist: 'asc' }, { title: 'asc' }],
         }),
         this.prisma.songDb.count({ where }),
       ]);

       // Get system names
       const systemIds = [...new Set(songs.map((s) => s.openkjSystemId))];
       const systems = await this.prisma.system.findMany({
         where: {
           customerProfileId,
           openkjSystemId: { in: systemIds },
         },
         select: {
           id: true,
           openkjSystemId: true,
           name: true,
         },
       });

       const systemMap = new Map(
         systems.map((s) => [s.openkjSystemId, { id: s.id, name: s.name }])
       );

       return {
         data: songs.map((s) => {
           const system = systemMap.get(s.openkjSystemId);
           return {
             id: Number(s.id),
             systemId: system?.id || '',
             systemName: system?.name || 'Unknown',
             artist: s.artist,
             title: s.title,
             combined: s.combined,
             createdAt: s.createdAt.toISOString(),
             updatedAt: s.updatedAt.toISOString(),
           };
         }),
         pagination: {
           page: pagination.page,
           limit: pagination.limit,
           total,
           totalPages: Math.ceil(total / pagination.limit),
         },
       };
     }

     async getSong(songId: number, customerProfileId: string) {
       const song = await this.prisma.songDb.findFirst({
         where: {
           id: BigInt(songId),
           customerProfileId,
         },
       });

       if (!song) {
         throw new Error('Song not found');
       }

       const system = await this.prisma.system.findFirst({
         where: {
           customerProfileId,
           openkjSystemId: song.openkjSystemId,
         },
       });

       return {
         id: Number(song.id),
         systemId: system?.id || '',
         systemName: system?.name || 'Unknown',
         artist: song.artist,
         title: song.title,
         combined: song.combined,
         createdAt: song.createdAt.toISOString(),
         updatedAt: song.updatedAt.toISOString(),
       };
     }

     async addSong(input: AddSongInput) {
       // Get system
       const system = await this.prisma.system.findFirst({
         where: {
           id: input.systemId,
           customerProfileId: input.customerProfileId,
         },
       });

       if (!system) {
         throw new Error('System not found');
       }

       const combined = `${input.artist} - ${input.title}`;
       const normalizedCombined = combined.toLowerCase();

       // Check for duplicates
       const existing = await this.prisma.songDb.findFirst({
         where: {
           customerProfileId: input.customerProfileId,
           openkjSystemId: system.openkjSystemId,
           normalizedCombined,
         },
       });

       if (existing) {
         throw new Error('Song already exists in this system');
       }

       const song = await this.prisma.songDb.create({
         data: {
           customerProfileId: input.customerProfileId,
           openkjSystemId: system.openkjSystemId,
           artist: input.artist,
           title: input.title,
           combined,
           normalizedCombined,
         },
       });

       logger.info(
         {
           songId: song.id,
           customerProfileId: input.customerProfileId,
           systemId: input.systemId,
           artist: input.artist,
           title: input.title,
         },
         'Song added'
       );

       return {
         id: Number(song.id),
         systemId: system.id,
         systemName: system.name,
         artist: song.artist,
         title: song.title,
         combined: song.combined,
         createdAt: song.createdAt.toISOString(),
         updatedAt: song.updatedAt.toISOString(),
       };
     }

     async bulkAddSongs(input: BulkAddSongsInput) {
       // Get system
       const system = await this.prisma.system.findFirst({
         where: {
           id: input.systemId,
           customerProfileId: input.customerProfileId,
         },
       });

       if (!system) {
         throw new Error('System not found');
       }

       // Prepare songs for insertion
       const songsToInsert = input.songs.map((s) => {
         const combined = `${s.artist} - ${s.title}`;
         return {
           customerProfileId: input.customerProfileId,
           openkjSystemId: system.openkjSystemId,
           artist: s.artist,
           title: s.title,
           combined,
           normalizedCombined: combined.toLowerCase(),
         };
       });

       // Use createMany with skipDuplicates
       const result = await this.prisma.songDb.createMany({
         data: songsToInsert,
         skipDuplicates: true,
       });

       logger.info(
         {
           customerProfileId: input.customerProfileId,
           systemId: input.systemId,
           requested: input.songs.length,
           inserted: result.count,
         },
         'Bulk songs added'
       );

       return {
         inserted: result.count,
         skipped: input.songs.length - result.count,
         total: input.songs.length,
       };
     }

     async updateSong(
       songId: number,
       customerProfileId: string,
       input: { artist?: string; title?: string }
     ) {
       const song = await this.prisma.songDb.findFirst({
         where: {
           id: BigInt(songId),
           customerProfileId,
         },
       });

       if (!song) {
         throw new Error('Song not found');
       }

       const artist = input.artist || song.artist;
       const title = input.title || song.title;
       const combined = `${artist} - ${title}`;
       const normalizedCombined = combined.toLowerCase();

       const updated = await this.prisma.songDb.update({
         where: { id: BigInt(songId) },
         data: {
           artist,
           title,
           combined,
           normalizedCombined,
         },
       });

       const system = await this.prisma.system.findFirst({
         where: {
           customerProfileId,
           openkjSystemId: updated.openkjSystemId,
         },
       });

       logger.info(
         {
           songId,
           customerProfileId,
         },
         'Song updated'
       );

       return {
         id: Number(updated.id),
         systemId: system?.id || '',
         systemName: system?.name || 'Unknown',
         artist: updated.artist,
         title: updated.title,
         combined: updated.combined,
         createdAt: updated.createdAt.toISOString(),
         updatedAt: updated.updatedAt.toISOString(),
       };
     }

     async deleteSong(songId: number, customerProfileId: string) {
       const song = await this.prisma.songDb.findFirst({
         where: {
           id: BigInt(songId),
           customerProfileId,
         },
       });

       if (!song) {
         throw new Error('Song not found');
       }

       await this.prisma.songDb.delete({
         where: { id: BigInt(songId) },
       });

       logger.info(
         {
           songId,
           customerProfileId,
           artist: song.artist,
           title: song.title,
         },
         'Song deleted'
       );
     }

     async bulkDeleteSongs(customerProfileId: string, systemId?: string) {
       const where: any = { customerProfileId };

       if (systemId) {
         const system = await this.prisma.system.findFirst({
           where: {
             id: systemId,
             customerProfileId,
           },
         });

         if (system) {
           where.openkjSystemId = system.openkjSystemId;
         }
       }

       const result = await this.prisma.songDb.deleteMany({ where });

       logger.info(
         {
           customerProfileId,
           systemId,
           count: result.count,
         },
         'Bulk songs deleted'
       );

       return result.count;
     }

     async importSongs(
       customerProfileId: string,
       systemId: string,
       format: 'csv' | 'json' | 'txt',
       data: string
     ) {
       // Get system
       const system = await this.prisma.system.findFirst({
         where: {
           id: systemId,
           customerProfileId,
         },
       });

       if (!system) {
         throw new Error('System not found');
       }

       let songs: Array<{ artist: string; title: string }> = [];

       if (format === 'csv') {
         // Parse CSV
         const parsed = Papa.parse<string[]>(data, {
           skipEmptyLines: true,
         });

         songs = parsed.data
           .filter((row) => row.length >= 2)
           .map((row) => ({
             artist: row[0].trim(),
             title: row[1].trim(),
           }))
           .filter((s) => s.artist && s.title);
       } else if (format === 'json') {
         // Parse JSON
         const parsed = JSON.parse(data);
         if (Array.isArray(parsed)) {
           songs = parsed
             .filter((s) => s.artist && s.title)
             .map((s) => ({
               artist: String(s.artist).trim(),
               title: String(s.title).trim(),
             }));
         }
       } else if (format === 'txt') {
         // Parse text (one song per line, format: "Artist - Title")
         const lines = data.split('\n');
         songs = lines
           .map((line) => {
             const parts = line.split('-').map((p) => p.trim());
             if (parts.length >= 2) {
               return {
                 artist: parts[0],
                 title: parts.slice(1).join('-').trim(),
               };
             }
             return null;
           })
           .filter((s): s is { artist: string; title: string } => s !== null);
       }

       if (songs.length === 0) {
         throw new Error('No valid songs found in import data');
       }

       // Bulk add songs
       const result = await this.bulkAddSongs({
         customerProfileId,
         systemId,
         songs,
       });

       logger.info(
         {
           customerProfileId,
           systemId,
           format,
           parsed: songs.length,
           inserted: result.inserted,
         },
         'Songs imported'
       );

       return result;
     }

     async exportSongs(
       customerProfileId: string,
       format: 'csv' | 'json' | 'txt',
       systemId?: string
     ) {
       const where: any = { customerProfileId };

       if (systemId) {
         const system = await this.prisma.system.findFirst({
           where: {
             id: systemId,
             customerProfileId,
           },
         });

         if (system) {
           where.openkjSystemId = system.openkjSystemId;
         }
       }

       const songs = await this.prisma.songDb.findMany({
         where,
         orderBy: [{ artist: 'asc' }, { title: 'asc' }],
       });

       let output = '';

       if (format === 'csv') {
         output = Papa.unparse(
           songs.map((s) => ({
             artist: s.artist,
             title: s.title,
           }))
         );
       } else if (format === 'json') {
         output = JSON.stringify(
           songs.map((s) => ({
             artist: s.artist,
             title: s.title,
           })),
           null,
           2
         );
       } else if (format === 'txt') {
         output = songs.map((s) => `${s.artist} - ${s.title}`).join('\n');
       }

       logger.info(
         {
           customerProfileId,
           systemId,
           format,
           count: songs.length,
         },
         'Songs exported'
       );

       return {
         data: output,
         count: songs.length,
       };
     }

     async getAvailableLetters(
       customerProfileId: string,
       systemId?: string
     ): Promise<string[]> {
       const where: any = { customerProfileId };

       if (systemId) {
         const system = await this.prisma.system.findFirst({
           where: {
             id: systemId,
             customerProfileId,
           },
         });

         if (system) {
           where.openkjSystemId = system.openkjSystemId;
         }
       }

       const letters = await this.prisma.$queryRaw<Array<{ letter: string }>>`
         SELECT DISTINCT UPPER(LEFT(artist, 1)) as letter
         FROM songdb
         WHERE customer_profiles_id = ${customerProfileId}::uuid
           ${systemId ? this.prisma.$queryRawUnsafe`AND openkj_system_id IN (
             SELECT openkj_system_id FROM systems WHERE systems_id = '${systemId}'::uuid
           )` : this.prisma.$queryRawUnsafe``}
         ORDER BY letter
       `;

       return letters.map((l) => l.letter);
     }
   }
   ```

3. **Install CSV parser dependency:**
   ```bash
   pnpm add papaparse
   pnpm add -D @types/papaparse
   ```

4. **Implement songdb routes in `apps/api/src/routes/customer/songdb.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateQuery, validateParams, validateBody } from '@singr/shared/validation';
   import { requirePermission } from '@singr/auth';
   import {
     SongDbQuerySchema,
     AddSongSchema,
     BulkAddSongsSchema,
     UpdateSongSchema,
     SongParamsSchema,
     ImportSongsSchema,
   } from './schemas';
   import { SongDbService } from '@singr/shared/services/songdb-service';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:customer:songdb');

   export const songdbRoute: FastifyPluginAsync = async (server) => {
     const songdbService = new SongDbService(server.prisma);

     // List songs
     server.get(
       '/songdb',
       {
         schema: {
           tags: ['customer'],
           summary: 'List songs',
           description: 'Get all songs in the song database',
           security: [{ bearerAuth: [] }],
           querystring: {
             type: 'object',
             properties: {
               page: { type: 'integer', minimum: 1, default: 1 },
               limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
               systemId: { type: 'string', format: 'uuid' },
               search: { type: 'string' },
               artist: { type: 'string' },
               title: { type: 'string' },
               letter: { type: 'string', minLength: 1, maxLength: 1 },
             },
           },
           response: {
             200: {
               description: 'List of songs',
               type: 'object',
               properties: {
                 data: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       id: { type: 'integer' },
                       systemId: { type: 'string', format: 'uuid' },
                       systemName: { type: 'string' },
                       artist: { type: 'string' },
                       title: { type: 'string' },
                       combined: { type: 'string' },
                     },
                   },
                 },
                 pagination: {
                   type: 'object',
                   properties: {
                     page: { type: 'integer' },
                     limit: { type: 'integer' },
                     total: { type: 'integer' },
                     totalPages: { type: 'integer' },
                   },
                 },
               },
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('songdb:read'),
           validateQuery(SongDbQuerySchema),
         ],
       },
       async (request, reply) => {
         const query = request.query as z.infer<typeof SongDbQuerySchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to access this resource',
           });
         }

         const { page, limit, ...filters } = query;

         const result = await songdbService.listSongs(
           customerProfileId,
           filters,
           { page, limit }
         );

         return reply.send(result);
       }
     );

     // Get available letters
     server.get(
       '/songdb/letters',
       {
         schema: {
           tags: ['customer'],
           summary: 'Get available letters',
           description: 'Get list of first letters that have songs',
           security: [{ bearerAuth: [] }],
           querystring: {
             type: 'object',
             properties: {
               systemId: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'Available letters',
               type: 'object',
               properties: {
                 letters: {
                   type: 'array',
                   items: { type: 'string' },
                 },
               },
             },
           },
         },
         preHandler: [server.authenticate, requirePermission('songdb:read')],
       },
       async (request, reply) => {
         const { systemId } = request.query as { systemId?: string };
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to access this resource',
           });
         }

         const letters = await songdbService.getAvailableLetters(
           customerProfileId,
           systemId
         );

         return reply.send({ letters });
       }
     );

     // Get song details
     server.get(
       '/songdb/:id',
       {
         schema: {
           tags: ['customer'],
           summary: 'Get song',
           description: 'Get details of a specific song',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'integer' },
             },
           },
           response: {
             200: {
               description: 'Song details',
               type: 'object',
               properties: {
                 id: { type: 'integer' },
                 systemId: { type: 'string', format: 'uuid' },
                 systemName: { type: 'string' },
                 artist: { type: 'string' },
                 title: { type: 'string' },
                 combined: { type: 'string' },
               },
             },
             404: {
               description: 'Song not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('songdb:read'),
           validateParams(SongParamsSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof SongParamsSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to access this resource',
           });
         }

         try {
           const song = await songdbService.getSong(id, customerProfileId);
           return reply.send(song);
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'Song Not Found',
               detail: 'Song not found or access denied',
             });
           }
           throw error;
         }
       }
     );

     // Add single song
     server.post(
       '/songdb',
       {
         schema: {
           tags: ['customer'],
           summary: 'Add song',
           description: 'Add a single song to the database',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['systemId', 'artist', 'title'],
             properties: {
               systemId: { type: 'string', format: 'uuid' },
               artist: { type: 'string', minLength: 1, maxLength: 255 },
               title: { type: 'string', minLength: 1, maxLength: 255 },
             },
           },
           response: {
             201: {
               description: 'Song added',
               type: 'object',
               properties: {
                 id: { type: 'integer' },
                 systemId: { type: 'string', format: 'uuid' },
                 artist: { type: 'string' },
                 title: { type: 'string' },
               },
             },
             404: {
               description: 'System not found',
             },
             409: {
               description: 'Song already exists',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('songdb:write'),
           validateBody(AddSongSchema),
         ],
       },
       async (request, reply) => {
         const body = request.body as z.infer<typeof AddSongSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to add songs',
           });
         }

         try {
           const song = await songdbService.addSong({
             customerProfileId,
             ...body,
           });

           return reply.code(201).send(song);
         } catch (error) {
           if (error instanceof Error) {
             if (error.message.includes('not found')) {
               return reply.code(404).send({
                 type: 'resource_not_found',
                 title: 'System Not Found',
                 detail: error.message,
               });
             }
             if (error.message.includes('already exists')) {
               return reply.code(409).send({
                 type: 'conflict',
                 title: 'Song Already Exists',
                 detail: error.message,
               });
             }
           }
           throw error;
         }
       }
     );

     // Bulk add songs
     server.post(
       '/songdb/bulk',
       {
         schema: {
           tags: ['customer'],
           summary: 'Bulk add songs',
           description: 'Add multiple songs at once (max 10,000)',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['systemId', 'songs'],
             properties: {
               systemId: { type: 'string', format: 'uuid' },
               songs: {
                 type: 'array',
                 minItems: 1,
                 maxItems: 10000,
                 items: {
                   type: 'object',
                   required: ['artist', 'title'],
                   properties: {
                     artist: { type: 'string', minLength: 1, maxLength: 255 },
                     title: { type: 'string', minLength: 1, maxLength: 255 },
                   },
                 },
               },
             },
           },
           response: {
             201: {
               description: 'Songs added',
               type: 'object',
               properties: {
                 inserted: { type: 'integer' },
                 skipped: { type: 'integer' },
                 total: { type: 'integer' },
               },
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('songdb:write'),
           validateBody(BulkAddSongsSchema),
         ],
         config: {
           rateLimit: {
             max: 10,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const body = request.body as z.infer<typeof BulkAddSongsSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to add songs',
           });
         }

         try {
           const result = await songdbService.bulkAddSongs({
             customerProfileId,
             ...body,
           });

           return reply.code(201).send(result);
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'System Not Found',
               detail: error.message,
             });
           }
           throw error;
         }
       }
     );

   };
   
     // Import songs
     server.post(
       '/songdb/import',
       {
         schema: {
           tags: ['customer'],
           summary: 'Import songs',
           description: 'Import songs from CSV, JSON, or TXT format',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['systemId', 'format', 'data'],
             properties: {
               systemId: { type: 'string', format: 'uuid' },
               format: { type: 'string', enum: ['csv', 'json', 'txt'] },
               data: { type: 'string' },
             },
           },
           response: {
             201: {
               description: 'Songs imported',
               type: 'object',
               properties: {
                 inserted: { type: 'integer' },
                 skipped: { type: 'integer' },
                 total: { type: 'integer' },
               },
             },
             400: {
               description: 'Invalid import data',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('songdb:write'),
           validateBody(ImportSongsSchema),
         ],
         config: {
           rateLimit: {
             max: 10,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const body = request.body as z.infer<typeof ImportSongsSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to import songs',
           });
         }

         try {
           const result = await songdbService.importSongs(
             customerProfileId,
             body.systemId,
             body.format,
             body.data
           );

           return reply.code(201).send(result);
         } catch (error) {
           if (error instanceof Error) {
             if (error.message.includes('not found')) {
               return reply.code(404).send({
                 type: 'resource_not_found',
                 title: 'System Not Found',
                 detail: error.message,
               });
             }
             if (error.message.includes('No valid songs')) {
               return reply.code(400).send({
                 type: 'validation_error',
                 title: 'Invalid Import Data',
                 detail: error.message,
               });
             }
           }
           throw error;
         }
       }
     );

     // Export songs
     server.get(
       '/songdb/export',
       {
         schema: {
           tags: ['customer'],
           summary: 'Export songs',
           description: 'Export all songs in CSV, JSON, or TXT format',
           security: [{ bearerAuth: [] }],
           querystring: {
             type: 'object',
             required: ['format'],
             properties: {
               format: { type: 'string', enum: ['csv', 'json', 'txt'] },
               systemId: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'Songs exported',
               type: 'string',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('songdb:read'),
           validateQuery(
             z.object({
               format: z.enum(['csv', 'json', 'txt']),
               systemId: z.string().uuid().optional(),
             })
           ),
         ],
         config: {
           rateLimit: {
             max: 20,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const { format, systemId } = request.query as {
           format: 'csv' | 'json' | 'txt';
           systemId?: string;
         };
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to export songs',
           });
         }

         const result = await songdbService.exportSongs(
           customerProfileId,
           format,
           systemId
         );

         // Set content type based on format
         const contentTypes = {
           csv: 'text/csv',
           json: 'application/json',
           txt: 'text/plain',
         };

         const extensions = {
           csv: 'csv',
           json: 'json',
           txt: 'txt',
         };

         reply.header('Content-Type', contentTypes[format]);
         reply.header(
           'Content-Disposition',
           `attachment; filename="songdb-export-${new Date().toISOString().split('T')[0]}.${extensions[format]}"`
         );

         return reply.send(result.data);
       }
     );

     // Update song
     server.patch(
       '/songdb/:id',
       {
         schema: {
           tags: ['customer'],
           summary: 'Update song',
           description: 'Update song information',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'integer' },
             },
           },
           body: {
             type: 'object',
             properties: {
               artist: { type: 'string', minLength: 1, maxLength: 255 },
               title: { type: 'string', minLength: 1, maxLength: 255 },
             },
           },
           response: {
             200: {
               description: 'Song updated',
               type: 'object',
               properties: {
                 id: { type: 'integer' },
                 artist: { type: 'string' },
                 title: { type: 'string' },
               },
             },
             404: {
               description: 'Song not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('songdb:write'),
           validateParams(SongParamsSchema),
           validateBody(UpdateSongSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof SongParamsSchema>;
         const body = request.body as z.infer<typeof UpdateSongSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to update songs',
           });
         }

         try {
           const song = await songdbService.updateSong(id, customerProfileId, body);
           return reply.send(song);
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'Song Not Found',
               detail: 'Song not found or access denied',
             });
           }
           throw error;
         }
       }
     );

     // Delete single song
     server.delete(
       '/songdb/:id',
       {
         schema: {
           tags: ['customer'],
           summary: 'Delete song',
           description: 'Delete a single song',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'integer' },
             },
           },
           response: {
             204: {
               description: 'Song deleted',
             },
             404: {
               description: 'Song not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('songdb:write'),
           validateParams(SongParamsSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof SongParamsSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to delete songs',
           });
         }

         try {
           await songdbService.deleteSong(id, customerProfileId);
           return reply.code(204).send();
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'Song Not Found',
               detail: 'Song not found or access denied',
             });
           }
           throw error;
         }
       }
     );

     // Bulk delete songs
     server.delete(
       '/songdb',
       {
         schema: {
           tags: ['customer'],
           summary: 'Bulk delete songs',
           description: 'Delete all songs or all songs for a specific system',
           security: [{ bearerAuth: [] }],
           querystring: {
             type: 'object',
             properties: {
               systemId: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'Songs deleted',
               type: 'object',
               properties: {
                 deletedCount: { type: 'integer' },
               },
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('songdb:write'),
           validateQuery(
             z.object({
               systemId: z.string().uuid().optional(),
             })
           ),
         ],
         config: {
           rateLimit: {
             max: 5,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const { systemId } = request.query as { systemId?: string };
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to delete songs',
           });
         }

         const deletedCount = await songdbService.bulkDeleteSongs(
           customerProfileId,
           systemId
         );

         return reply.send({ deletedCount });
       }
     );
   };
   ```

5. **Register songdb route in `apps/api/src/routes/customer/index.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { venuesRoute } from './venues';
   import { systemsRoute } from './systems';
   import { songdbRoute } from './songdb';

   export const customerRoutes: FastifyPluginAsync = async (server) => {
     await server.register(venuesRoute);
     await server.register(systemsRoute);
     await server.register(songdbRoute);
   };
   ```

6. **Create import format documentation in `docs/SONGDB_IMPORT_FORMATS.md`:**
   ````markdown
   # Song Database Import Formats

   ## CSV Format

   Two columns: Artist, Title

   ```csv
   Queen,Bohemian Rhapsody
   The Beatles,Hey Jude
   Journey,Don't Stop Believin'
   ```

   ## JSON Format

   Array of objects with `artist` and `title` properties:

   ```json
   [
     {
       "artist": "Queen",
       "title": "Bohemian Rhapsody"
     },
     {
       "artist": "The Beatles",
       "title": "Hey Jude"
     }
   ]
   ```

   ## TXT Format

   One song per line, format: "Artist - Title"

   ```txt
   Queen - Bohemian Rhapsody
   The Beatles - Hey Jude
   Journey - Don't Stop Believin'
   ```

   ## Import Limits

   - Maximum 10,000 songs per import
   - Duplicates are automatically skipped
   - Rate limit: 10 imports per hour

   ## Export Formats

   All three formats (CSV, JSON, TXT) are supported for export.
   Downloads are automatically triggered with appropriate file extensions.

   ## Example API Usage

   ### Import CSV
   ```bash
   curl -X POST https://api.singrkaraoke.com/v1/customer/songdb/import \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "systemId": "uuid-here",
       "format": "csv",
       "data": "Queen,Bohemian Rhapsody\nThe Beatles,Hey Jude"
     }'
   ```

   ### Export JSON
   ```bash
   curl https://api.singrkaraoke.com/v1/customer/songdb/export?format=json \
     -H "Authorization: Bearer $TOKEN" \
     -o songdb-export.json
   ```
   ````

**Deliverables:**
- ✅ `GET /v1/customer/songdb` - List all songs with filters
- ✅ `GET /v1/customer/songdb/letters` - Get available alphabet letters
- ✅ `GET /v1/customer/songdb/:id` - Get song details
- ✅ `POST /v1/customer/songdb` - Add single song
- ✅ `POST /v1/customer/songdb/bulk` - Bulk add songs (max 10,000)
- ✅ `POST /v1/customer/songdb/import` - Import from CSV/JSON/TXT
- ✅ `GET /v1/customer/songdb/export` - Export to CSV/JSON/TXT
- ✅ `PATCH /v1/customer/songdb/:id` - Update song
- ✅ `DELETE /v1/customer/songdb/:id` - Delete single song
- ✅ `DELETE /v1/customer/songdb` - Bulk delete songs
- ✅ Duplicate detection (skip duplicates in bulk operations)
- ✅ Search by artist, title, or combined
- ✅ Filter by system
- ✅ Alphabet navigation
- ✅ CSV parsing with Papa Parse
- ✅ JSON parsing
- ✅ TXT format support (Artist - Title)
- ✅ Download headers for exports
- ✅ Rate limiting on bulk operations
- ✅ RBAC permission checks (songdb:read, songdb:write)
- ✅ Customer context validation
- ✅ Pagination support
- ✅ System association tracking

---

**End of Phase 9. Complete deliverables:**

### Phase 9 Summary

**Customer System & Songdb Management:**
- ✅ Full CRUD operations for karaoke systems
- ✅ Auto-increment openkjSystemId tracking
- ✅ System configuration JSON storage
- ✅ Song count tracking per system
- ✅ Delete protection (cannot delete system with songs)
- ✅ Full CRUD operations for song database
- ✅ Bulk operations (add up to 10,000 songs at once)
- ✅ Import from CSV, JSON, and TXT formats
- ✅ Export to CSV, JSON, and TXT formats
- ✅ Duplicate detection and skip logic
- ✅ Normalized search indexing
- ✅ Alphabet navigation support
- ✅ Multi-system song management
- ✅ Rate limiting on bulk operations
- ✅ Comprehensive filtering and search
- ✅ File download support with proper headers

---

## Phase 10: Customer Request Management

### 10.1 Request Queue Management

**Objective:** Allow customers to view and manage incoming song requests in real-time.

**Duration:** 3 days  
**Team Size:** 1-2 developers

**Tasks:**

1. **Create request management schemas in `apps/api/src/routes/customer/schemas.ts`:**
   ```typescript
   // Add to existing schemas
   export const RequestQueueQuerySchema = PaginationSchema.extend({
     venueId: z.string().uuid().optional(),
     processed: z.coerce.boolean().optional(),
     startDate: z.string().datetime().optional(),
     endDate: z.string().datetime().optional(),
     search: z.string().max(200).optional(),
   });

   export const RequestParamsSchema = z.object({
     id: z.coerce.number().int().positive(),
   });

   export const UpdateRequestSchema = z.object({
     processed: z.boolean().optional(),
     notes: z.string().max(500).optional(),
   });

   export const ProcessRequestSchema = z.object({
     processed: z.boolean(),
   });

   export const BulkProcessRequestsSchema = z.object({
     requestIds: z.array(z.number().int().positive()).min(1).max(100),
     processed: z.boolean(),
   });

   export const RequestResponseSchema = z.object({
     id: z.number(),
     venueId: z.string().uuid(),
     venueName: z.string(),
     artist: z.string(),
     title: z.string(),
     keyChange: z.number(),
     notes: z.string().nullable(),
     singerProfileId: z.string().uuid().nullable(),
     singerName: z.string().nullable(),
     submittedByUserId: z.string().uuid().nullable(),
     requestedAt: z.string().datetime(),
     processed: z.boolean(),
     processedAt: z.string().datetime().nullable(),
   });
   ```

2. **Create request management service in `packages/shared/src/services/customer-request-service.ts`:**
   ```typescript
   import { PrismaClient } from '@prisma/database';
   import { createLogger } from '@singr/observability';
   import { createCommunicationQueue } from '../queues/communication-queue';
   import { Redis } from 'ioredis';

   const logger = createLogger('services:customer-request');

   export interface RequestFilters {
     venueId?: string;
     processed?: boolean;
     startDate?: Date;
     endDate?: Date;
     search?: string;
   }

   export class CustomerRequestService {
     constructor(
       private prisma: PrismaClient,
       private redis: Redis
     ) {}

     async listRequests(
       customerProfileId: string,
       filters: RequestFilters,
       pagination: { page: number; limit: number }
     ) {
       const where: any = {
         venue: { customerProfileId },
       };

       if (filters.venueId) {
         where.venueId = filters.venueId;
       }

       if (filters.processed !== undefined) {
         where.processed = filters.processed;
       }

       if (filters.startDate) {
         where.requestedAt = { gte: filters.startDate };
       }

       if (filters.endDate) {
         where.requestedAt = {
           ...where.requestedAt,
           lte: filters.endDate,
         };
       }

       if (filters.search) {
         where.OR = [
           { artist: { contains: filters.search, mode: 'insensitive' } },
           { title: { contains: filters.search, mode: 'insensitive' } },
         ];
       }

       const [requests, total] = await Promise.all([
         this.prisma.request.findMany({
           where,
           skip: (pagination.page - 1) * pagination.limit,
           take: pagination.limit,
           orderBy: { requestedAt: 'desc' },
           include: {
             venue: {
               select: {
                 id: true,
                 name: true,
               },
             },
             singerProfile: {
               select: {
                 id: true,
                 nickname: true,
                 user: {
                   select: { name: true },
                 },
               },
             },
           },
         }),
         this.prisma.request.count({ where }),
       ]);

       return {
         data: requests.map((r) => ({
           id: Number(r.id),
           venueId: r.venueId,
           venueName: r.venue.name,
           artist: r.artist,
           title: r.title,
           keyChange: r.keyChange,
           notes: r.notes,
           singerProfileId: r.singerProfileId,
           singerName: r.singerProfile
             ? r.singerProfile.nickname || r.singerProfile.user.name
             : null,
           submittedByUserId: r.submittedByUserId,
           requestedAt: r.requestedAt.toISOString(),
           processed: r.processed,
           processedAt: r.processedAt?.toISOString() || null,
         })),
         pagination: {
           page: pagination.page,
           limit: pagination.limit,
           total,
           totalPages: Math.ceil(total / pagination.limit),
         },
       };
     }

     async getRequest(requestId: number, customerProfileId: string) {
       const request = await this.prisma.request.findFirst({
         where: {
           id: BigInt(requestId),
           venue: { customerProfileId },
         },
         include: {
           venue: {
             select: {
               id: true,
               name: true,
             },
           },
           singerProfile: {
             select: {
               id: true,
               nickname: true,
               user: {
                 select: { name: true, email: true },
               },
             },
           },
         },
       });

       if (!request) {
         throw new Error('Request not found');
       }

       return {
         id: Number(request.id),
         venueId: request.venueId,
         venueName: request.venue.name,
         artist: request.artist,
         title: request.title,
         keyChange: request.keyChange,
         notes: request.notes,
         singerProfileId: request.singerProfileId,
         singerName: request.singerProfile
           ? request.singerProfile.nickname || request.singerProfile.user.name
           : null,
         singerEmail: request.singerProfile?.user.email || null,
         submittedByUserId: request.submittedByUserId,
         requestedAt: request.requestedAt.toISOString(),
         processed: request.processed,
         processedAt: request.processedAt?.toISOString() || null,
       };
     }

     async processRequest(
       requestId: number,
       customerProfileId: string,
       processed: boolean
     ) {
       const request = await this.prisma.request.findFirst({
         where: {
           id: BigInt(requestId),
           venue: { customerProfileId },
         },
       });

       if (!request) {
         throw new Error('Request not found');
       }

       const updated = await this.prisma.request.update({
         where: { id: BigInt(requestId) },
         data: {
           processed,
           processedAt: processed ? new Date() : null,
         },
         include: {
           venue: {
             select: {
               id: true,
               name: true,
             },
           },
           singerProfile: {
             select: {
               id: true,
               nickname: true,
               user: {
                 select: { name: true },
               },
             },
           },
         },
       });

       logger.info(
         {
           requestId,
           customerProfileId,
           processed,
         },
         'Request processed'
       );

       return {
         id: Number(updated.id),
         venueId: updated.venueId,
         venueName: updated.venue.name,
         artist: updated.artist,
         title: updated.title,
         keyChange: updated.keyChange,
         notes: updated.notes,
         singerProfileId: updated.singerProfileId,
         singerName: updated.singerProfile
           ? updated.singerProfile.nickname || updated.singerProfile.user.name
           : null,
         submittedByUserId: updated.submittedByUserId,
         requestedAt: updated.requestedAt.toISOString(),
         processed: updated.processed,
         processedAt: updated.processedAt?.toISOString() || null,
       };
     }

     async bulkProcessRequests(
       requestIds: number[],
       customerProfileId: string,
       processed: boolean
     ) {
       // Verify all requests belong to customer
       const requests = await this.prisma.request.findMany({
         where: {
           id: { in: requestIds.map((id) => BigInt(id)) },
           venue: { customerProfileId },
         },
       });

       if (requests.length !== requestIds.length) {
         throw new Error('Some requests not found or access denied');
       }

       const result = await this.prisma.request.updateMany({
         where: {
           id: { in: requestIds.map((id) => BigInt(id)) },
         },
         data: {
           processed,
           processedAt: processed ? new Date() : null,
         },
       });

       logger.info(
         {
           customerProfileId,
           count: result.count,
           processed,
         },
         'Bulk requests processed'
       );

       return result.count;
     }

     async deleteRequest(requestId: number, customerProfileId: string) {
       const request = await this.prisma.request.findFirst({
         where: {
           id: BigInt(requestId),
           venue: { customerProfileId },
         },
       });

       if (!request) {
         throw new Error('Request not found');
       }

       await this.prisma.request.delete({
         where: { id: BigInt(requestId) },
       });

       logger.info(
         {
           requestId,
           customerProfileId,
         },
         'Request deleted'
       );
     }

     async bulkDeleteRequests(
       customerProfileId: string,
       venueId?: string,
       processed?: boolean
     ) {
       const where: any = {
         venue: { customerProfileId },
       };

       if (venueId) {
         where.venueId = venueId;
       }

       if (processed !== undefined) {
         where.processed = processed;
       }

       const result = await this.prisma.request.deleteMany({ where });

       logger.info(
         {
           customerProfileId,
           venueId,
           processed,
           count: result.count,
         },
         'Bulk requests deleted'
       );

       return result.count;
     }

     async getRequestStats(customerProfileId: string, venueId?: string) {
       const where: any = {
         venue: { customerProfileId },
       };

       if (venueId) {
         where.venueId = venueId;
       }

       const now = new Date();
       const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());

       const [total, pending, processed, todayCount] = await Promise.all([
         this.prisma.request.count({ where }),
         this.prisma.request.count({
           where: { ...where, processed: false },
         }),
         this.prisma.request.count({
           where: { ...where, processed: true },
         }),
         this.prisma.request.count({
           where: {
             ...where,
             requestedAt: { gte: startOfToday },
           },
         }),
       ]);

       return {
         total,
         pending,
         processed,
         todayCount,
       };
     }

     async getRecentRequests(
       customerProfileId: string,
       venueId?: string,
       limit: number = 10
     ) {
       const where: any = {
         venue: { customerProfileId },
         processed: false,
       };

       if (venueId) {
         where.venueId = venueId;
       }

       const requests = await this.prisma.request.findMany({
         where,
         take: limit,
         orderBy: { requestedAt: 'desc' },
         include: {
           venue: {
             select: {
               id: true,
               name: true,
             },
           },
           singerProfile: {
             select: {
               id: true,
               nickname: true,
               user: {
                 select: { name: true },
               },
             },
           },
         },
       });

       return requests.map((r) => ({
         id: Number(r.id),
         venueId: r.venueId,
         venueName: r.venue.name,
         artist: r.artist,
         title: r.title,
         keyChange: r.keyChange,
         singerName: r.singerProfile
           ? r.singerProfile.nickname || r.singerProfile.user.name
           : 'Guest',
         requestedAt: r.requestedAt.toISOString(),
       }));
     }
   }
   ```

3. **Implement request management routes in `apps/api/src/routes/customer/requests.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateQuery, validateParams, validateBody } from '@singr/shared/validation';
   import { requirePermission } from '@singr/auth';
   import {
     RequestQueueQuerySchema,
     RequestParamsSchema,
     ProcessRequestSchema,
     BulkProcessRequestsSchema,
   } from './schemas';
   import { CustomerRequestService } from '@singr/shared/services/customer-request-service';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:customer:requests');

   export const requestsRoute: FastifyPluginAsync = async (server) => {
     const requestService = new CustomerRequestService(server.prisma, server.redis);

     // List requests
     server.get(
       '/requests',
       {
         schema: {
           tags: ['customer'],
           summary: 'List requests',
           description: 'Get all song requests for customer venues',
           security: [{ bearerAuth: [] }],
           querystring: {
             type: 'object',
             properties: {
               page: { type: 'integer', minimum: 1, default: 1 },
               limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
               venueId: { type: 'string', format: 'uuid' },
               processed: { type: 'boolean' },
               startDate: { type: 'string', format: 'date-time' },
               endDate: { type: 'string', format: 'date-time' },
               search: { type: 'string' },
             },
           },
           response: {
             200: {
               description: 'List of requests',
               type: 'object',
               properties: {
                 data: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       id: { type: 'integer' },
                       venueId: { type: 'string', format: 'uuid' },
                       venueName: { type: 'string' },
                       artist: { type: 'string' },
                       title: { type: 'string' },
                       keyChange: { type: 'integer' },
                       singerName: { type: 'string' },
                       requestedAt: { type: 'string', format: 'date-time' },
                       processed: { type: 'boolean' },
                     },
                   },
                 },
                 pagination: {
                   type: 'object',
                   properties: {
                     page: { type: 'integer' },
                     limit: { type: 'integer' },
                     total: { type: 'integer' },
                     totalPages: { type: 'integer' },
                   },
                 },
               },
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('requests:read'),
           validateQuery(RequestQueueQuerySchema),
         ],
       },
       async (request, reply) => {
         const query = request.query as z.infer<typeof RequestQueueQuerySchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to access this resource',
           });
         }

         const { page, limit, startDate, endDate, ...filters } = query;

         const result = await requestService.listRequests(
           customerProfileId,
           {
             ...filters,
             startDate: startDate ? new Date(startDate) : undefined,
             endDate: endDate ? new Date(endDate) : undefined,
           },
           { page, limit }
         );

         return reply.send(result);
       }
     );

     // Get request stats
     server.get(
       '/requests/stats',
       {
         schema: {
           tags: ['customer'],
           summary: 'Get request statistics',
           description: 'Get aggregate request statistics',
           security: [{ bearerAuth: [] }],
           querystring: {
             type: 'object',
             properties: {
               venueId: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'Request statistics',
               type: 'object',
               properties: {
                 total: { type: 'integer' },
                 pending: { type: 'integer' },
                 processed: { type: 'integer' },
                 todayCount: { type: 'integer' },
               },
             },
           },
         },
         preHandler: [server.authenticate, requirePermission('requests:read')],
       },
       async (request, reply) => {
         const { venueId } = request.query as { venueId?: string };
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to access this resource',
           });
         }

         const stats = await requestService.getRequestStats(customerProfileId, venueId);

         return reply.send(stats);
       }
     );

     // Get recent requests
     server.get(
       '/requests/recent',
       {
         schema: {
           tags: ['customer'],
           summary: 'Get recent requests',
           description: 'Get most recent pending requests',
           security: [{ bearerAuth: [] }],
           querystring: {
             type: 'object',
             properties: {
               venueId: { type: 'string', format: 'uuid' },
               limit: { type: 'integer', minimum: 1, maximum: 50, default: 10 },
             },
           },
           response: {
             200: {
               description: 'Recent requests',
               type: 'array',
               items: {
                 type: 'object',
                 properties: {
                   id: { type: 'integer' },
                   venueId: { type: 'string', format: 'uuid' },
                   venueName: { type: 'string' },
                   artist: { type: 'string' },
                   title: { type: 'string' },
                   singerName: { type: 'string' },
                   requestedAt: { type: 'string', format: 'date-time' },
                 },
               },
             },
           },
         },
         preHandler: [server.authenticate, requirePermission('requests:read')],
       },
       async (request, reply) => {
         const { venueId, limit = 10 } = request.query as {
           venueId?: string;
           limit?: number;
         };
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to access this resource',
           });
         }

         const requests = await requestService.getRecentRequests(
           customerProfileId,
           venueId,
           limit
         );

         return reply.send(requests);
       }
     );

     // Get request details
     server.get(
       '/requests/:id',
       {
         schema: {
           tags: ['customer'],
           summary: 'Get request',
           description: 'Get details of a specific request',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'integer' },
             },
           },
           response: {
             200: {
               description: 'Request details',
               type: 'object',
               properties: {
                 id: { type: 'integer' },
                 venueId: { type: 'string', format: 'uuid' },
                 venueName: { type: 'string' },
                 artist: { type: 'string' },
                 title: { type: 'string' },
                 keyChange: { type: 'integer' },
                 notes: { type: 'string' },
                 singerName: { type: 'string' },
                 singerEmail: { type: 'string' },
                 requestedAt: { type: 'string', format: 'date-time' },
                 processed: { type: 'boolean' },
                 processedAt: { type: 'string', format: 'date-time' },
               },
             },
             404: {
               description: 'Request not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('requests:read'),
           validateParams(RequestParamsSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof RequestParamsSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to access this resource',
           });
         }

         try {
           const requestData = await requestService.getRequest(id, customerProfileId);
           return reply.send(requestData);
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'Request Not Found',
               detail: 'Request not found or access denied',
             });
           }
           throw error;
         }
       }
     );

   };

     // Process/unprocess single request
     server.patch(
       '/requests/:id/process',
       {
         schema: {
           tags: ['customer'],
           summary: 'Process request',
           description: 'Mark request as processed or unprocessed',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'integer' },
             },
           },
           body: {
             type: 'object',
             required: ['processed'],
             properties: {
               processed: { type: 'boolean' },
             },
           },
           response: {
             200: {
               description: 'Request processed',
               type: 'object',
               properties: {
                 id: { type: 'integer' },
                 processed: { type: 'boolean' },
                 processedAt: { type: 'string', format: 'date-time' },
               },
             },
             404: {
               description: 'Request not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('requests:process'),
           validateParams(RequestParamsSchema),
           validateBody(ProcessRequestSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof RequestParamsSchema>;
         const { processed } = request.body as z.infer<typeof ProcessRequestSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to process requests',
           });
         }

         try {
           const result = await requestService.processRequest(
             id,
             customerProfileId,
             processed
           );
           return reply.send(result);
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'Request Not Found',
               detail: 'Request not found or access denied',
             });
           }
           throw error;
         }
       }
     );

     // Bulk process requests
     server.post(
       '/requests/bulk/process',
       {
         schema: {
           tags: ['customer'],
           summary: 'Bulk process requests',
           description: 'Mark multiple requests as processed or unprocessed',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['requestIds', 'processed'],
             properties: {
               requestIds: {
                 type: 'array',
                 minItems: 1,
                 maxItems: 100,
                 items: { type: 'integer' },
               },
               processed: { type: 'boolean' },
             },
           },
           response: {
             200: {
               description: 'Requests processed',
               type: 'object',
               properties: {
                 updatedCount: { type: 'integer' },
               },
             },
             400: {
               description: 'Some requests not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('requests:process'),
           validateBody(BulkProcessRequestsSchema),
         ],
       },
       async (request, reply) => {
         const { requestIds, processed } = request.body as z.infer<
           typeof BulkProcessRequestsSchema
         >;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to process requests',
           });
         }

         try {
           const count = await requestService.bulkProcessRequests(
             requestIds,
             customerProfileId,
             processed
           );

           return reply.send({ updatedCount: count });
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(400).send({
               type: 'invalid_request',
               title: 'Invalid Request',
               detail: error.message,
             });
           }
           throw error;
         }
       }
     );

     // Delete single request
     server.delete(
       '/requests/:id',
       {
         schema: {
           tags: ['customer'],
           summary: 'Delete request',
           description: 'Delete a specific request',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'integer' },
             },
           },
           response: {
             204: {
               description: 'Request deleted',
             },
             404: {
               description: 'Request not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('requests:process'),
           validateParams(RequestParamsSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof RequestParamsSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to delete requests',
           });
         }

         try {
           await requestService.deleteRequest(id, customerProfileId);
           return reply.code(204).send();
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'Request Not Found',
               detail: 'Request not found or access denied',
             });
           }
           throw error;
         }
       }
     );

     // Bulk delete requests
     server.delete(
       '/requests',
       {
         schema: {
           tags: ['customer'],
           summary: 'Bulk delete requests',
           description: 'Delete all requests or filtered set',
           security: [{ bearerAuth: [] }],
           querystring: {
             type: 'object',
             properties: {
               venueId: { type: 'string', format: 'uuid' },
               processed: { type: 'boolean' },
             },
           },
           response: {
             200: {
               description: 'Requests deleted',
               type: 'object',
               properties: {
                 deletedCount: { type: 'integer' },
               },
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('requests:process'),
           validateQuery(
             z.object({
               venueId: z.string().uuid().optional(),
               processed: z.coerce.boolean().optional(),
             })
           ),
         ],
         config: {
           rateLimit: {
             max: 5,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const { venueId, processed } = request.query as {
           venueId?: string;
           processed?: boolean;
         };
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to delete requests',
           });
         }

         const deletedCount = await requestService.bulkDeleteRequests(
           customerProfileId,
           venueId,
           processed
         );

         return reply.send({ deletedCount });
       }
     );
   };
   ```

4. **Register requests route in `apps/api/src/routes/customer/index.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { venuesRoute } from './venues';
   import { systemsRoute } from './systems';
   import { songdbRoute } from './songdb';
   import { requestsRoute } from './requests';

   export const customerRoutes: FastifyPluginAsync = async (server) => {
     await server.register(venuesRoute);
     await server.register(systemsRoute);
     await server.register(songdbRoute);
     await server.register(requestsRoute);
   };
   ```

**Deliverables:**
- ✅ `GET /v1/customer/requests` - List all requests with filters
- ✅ `GET /v1/customer/requests/stats` - Get request statistics
- ✅ `GET /v1/customer/requests/recent` - Get recent pending requests
- ✅ `GET /v1/customer/requests/:id` - Get request details
- ✅ `PATCH /v1/customer/requests/:id/process` - Mark as processed/unprocessed
- ✅ `POST /v1/customer/requests/bulk/process` - Bulk process (max 100)
- ✅ `DELETE /v1/customer/requests/:id` - Delete single request
- ✅ `DELETE /v1/customer/requests` - Bulk delete by filters
- ✅ Filter by venue, processed status, date range, search
- ✅ Singer information included
- ✅ Request statistics (total, pending, processed, today)
- ✅ RBAC permission checks (requests:read, requests:process)
- ✅ Customer context validation
- ✅ Pagination support
- ✅ Rate limiting on bulk operations

---

### 10.2 Real-Time Request Notifications

**Objective:** Implement WebSocket connections for real-time request updates.

**Duration:** 2-3 days  
**Team Size:** 1 developer

**Tasks:**

1. **Install WebSocket dependencies:**
   ```bash
   pnpm add @fastify/websocket ws
   pnpm add -D @types/ws
   ```

2. **Create WebSocket authentication middleware in `packages/auth/src/websocket-auth.ts`:**
   ```typescript
   import { FastifyRequest } from 'fastify';
   import { verifyToken } from './jwt';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('auth:websocket');

   export interface WebSocketUser {
     sub: string;
     email: string;
     roles: string[];
     activeContext?: {
       type: 'customer' | 'singer';
       id: string;
     };
   }

   export async function authenticateWebSocket(
     request: FastifyRequest
   ): Promise<WebSocketUser | null> {
     try {
       // Get token from query parameter
       const token = request.query?.token as string;

       if (!token) {
         logger.warn('WebSocket connection attempted without token');
         return null;
       }

       // Verify JWT
       const payload = await verifyToken(token);

       if (!payload) {
         logger.warn('WebSocket connection attempted with invalid token');
         return null;
       }

       return {
         sub: payload.sub,
         email: payload.email,
         roles: payload.roles || [],
         activeContext: payload.activeContext,
       };
     } catch (error) {
       logger.error({ error }, 'WebSocket authentication error');
       return null;
     }
   }
   ```

3. **Create WebSocket manager in `packages/shared/src/services/websocket-manager.ts`:**
   ```typescript
   import { WebSocket } from 'ws';
   import { createLogger } from '@singr/observability';
   import { Redis } from 'ioredis';

   const logger = createLogger('services:websocket-manager');

   export interface WebSocketClient {
     id: string;
     socket: WebSocket;
     userId: string;
     customerProfileId?: string;
     venueIds: Set<string>;
   }

   export class WebSocketManager {
     private clients: Map<string, WebSocketClient> = new Map();
     private customerClients: Map<string, Set<string>> = new Map();
     private venueClients: Map<string, Set<string>> = new Map();

     constructor(private redis: Redis) {
       this.setupRedisSubscription();
     }

     private setupRedisSubscription() {
       const subscriber = this.redis.duplicate();

       subscriber.subscribe('requests:new', 'requests:update', (err) => {
         if (err) {
           logger.error({ error: err }, 'Redis subscription error');
         } else {
           logger.info('Subscribed to Redis request channels');
         }
       });

       subscriber.on('message', (channel, message) => {
         try {
           const data = JSON.parse(message);

           if (channel === 'requests:new') {
             this.broadcastNewRequest(data);
           } else if (channel === 'requests:update') {
             this.broadcastRequestUpdate(data);
           }
         } catch (error) {
           logger.error({ error, channel }, 'Error processing Redis message');
         }
       });
     }

     addClient(
       clientId: string,
       socket: WebSocket,
       userId: string,
       customerProfileId?: string,
       venueIds?: string[]
     ) {
       const client: WebSocketClient = {
         id: clientId,
         socket,
         userId,
         customerProfileId,
         venueIds: new Set(venueIds || []),
       };

       this.clients.set(clientId, client);

       if (customerProfileId) {
         if (!this.customerClients.has(customerProfileId)) {
           this.customerClients.set(customerProfileId, new Set());
         }
         this.customerClients.get(customerProfileId)!.add(clientId);
       }

       if (venueIds) {
         venueIds.forEach((venueId) => {
           if (!this.venueClients.has(venueId)) {
             this.venueClients.set(venueId, new Set());
           }
           this.venueClients.get(venueId)!.add(clientId);
         });
       }

       logger.info(
         {
           clientId,
           userId,
           customerProfileId,
           venueCount: venueIds?.length || 0,
         },
         'WebSocket client connected'
       );
     }

     removeClient(clientId: string) {
       const client = this.clients.get(clientId);

       if (client) {
         if (client.customerProfileId) {
           this.customerClients.get(client.customerProfileId)?.delete(clientId);
         }

         client.venueIds.forEach((venueId) => {
           this.venueClients.get(venueId)?.delete(clientId);
         });

         this.clients.delete(clientId);

         logger.info({ clientId, userId: client.userId }, 'WebSocket client disconnected');
       }
     }

     private broadcastNewRequest(data: {
       requestId: number;
       venueId: string;
       customerProfileId: string;
       artist: string;
       title: string;
       singerName?: string;
       requestedAt: string;
     }) {
       const message = JSON.stringify({
         type: 'request:new',
         data,
       });

       // Send to all clients for this venue
       const venueClients = this.venueClients.get(data.venueId);
       if (venueClients) {
         venueClients.forEach((clientId) => {
           const client = this.clients.get(clientId);
           if (client && client.socket.readyState === WebSocket.OPEN) {
             client.socket.send(message);
           }
         });
       }

       // Send to all clients for this customer profile
       const customerClients = this.customerClients.get(data.customerProfileId);
       if (customerClients) {
         customerClients.forEach((clientId) => {
           const client = this.clients.get(clientId);
           if (client && client.socket.readyState === WebSocket.OPEN) {
             client.socket.send(message);
           }
         });
       }

       logger.debug(
         {
           requestId: data.requestId,
           venueId: data.venueId,
           clientCount: (venueClients?.size || 0) + (customerClients?.size || 0),
         },
         'Broadcasted new request'
       );
     }

     private broadcastRequestUpdate(data: {
       requestId: number;
       venueId: string;
       customerProfileId: string;
       processed: boolean;
       processedAt?: string;
     }) {
       const message = JSON.stringify({
         type: 'request:update',
         data,
       });

       // Send to venue and customer clients
       const venueClients = this.venueClients.get(data.venueId);
       const customerClients = this.customerClients.get(data.customerProfileId);

       const allClients = new Set([
         ...(venueClients || []),
         ...(customerClients || []),
       ]);

       allClients.forEach((clientId) => {
         const client = this.clients.get(clientId);
         if (client && client.socket.readyState === WebSocket.OPEN) {
           client.socket.send(message);
         }
       });

       logger.debug(
         {
           requestId: data.requestId,
           processed: data.processed,
           clientCount: allClients.size,
         },
         'Broadcasted request update'
       );
     }

     sendToClient(clientId: string, message: any) {
       const client = this.clients.get(clientId);
       if (client && client.socket.readyState === WebSocket.OPEN) {
         client.socket.send(JSON.stringify(message));
       }
     }

     getClientCount(): number {
       return this.clients.size;
     }

     getCustomerClientCount(customerProfileId: string): number {
       return this.customerClients.get(customerProfileId)?.size || 0;
     }
   }
   ```

4. **Update request service to publish events:**
   ```typescript
   // Add to packages/shared/src/services/customer-request-service.ts
   // In createRequest method (or wherever requests are created):

   async notifyNewRequest(request: {
     id: number;
     venueId: string;
     customerProfileId: string;
     artist: string;
     title: string;
     singerName?: string;
     requestedAt: string;
   }) {
     await this.redis.publish(
       'requests:new',
       JSON.stringify({
         requestId: request.id,
         venueId: request.venueId,
         customerProfileId: request.customerProfileId,
         artist: request.artist,
         title: request.title,
         singerName: request.singerName || 'Guest',
         requestedAt: request.requestedAt,
       })
     );
   }

   // In processRequest method:
   async notifyRequestUpdate(request: {
     id: number;
     venueId: string;
     customerProfileId: string;
     processed: boolean;
     processedAt?: string;
   }) {
     await this.redis.publish(
       'requests:update',
       JSON.stringify({
         requestId: request.id,
         venueId: request.venueId,
         customerProfileId: request.customerProfileId,
         processed: request.processed,
         processedAt: request.processedAt,
       })
     );
   }
   ```

5. **Update RequestService to trigger notifications:**
   ```typescript
   // Update packages/shared/src/services/request-service.ts
   // In createRequest method after creating request:

   // Notify via Redis for WebSocket broadcast
   const venue = await this.prisma.venue.findUnique({
     where: { id: input.venueId },
     select: { customerProfileId: true },
   });

   if (venue) {
     await this.redis.publish(
       'requests:new',
       JSON.stringify({
         requestId: Number(request.id),
         venueId: request.venueId,
         customerProfileId: venue.customerProfileId,
         artist: request.artist,
         title: request.title,
         singerName: input.singerProfileId ? 'Singer' : 'Guest',
         requestedAt: request.requestedAt.toISOString(),
       })
     );
   }
   ```

6. **Implement WebSocket route in `apps/api/src/routes/customer/websocket.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { authenticateWebSocket } from '@singr/auth/websocket-auth';
   import { WebSocketManager } from '@singr/shared/services/websocket-manager';
   import { randomUUID } from 'crypto';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:customer:websocket');

   export const websocketRoute: FastifyPluginAsync = async (server) => {
     const wsManager = new WebSocketManager(server.redis);

     server.get(
       '/ws',
       {
         websocket: true,
         schema: {
           tags: ['customer'],
           summary: 'WebSocket connection',
           description: 'Real-time updates for song requests',
           querystring: {
             type: 'object',
             required: ['token'],
             properties: {
               token: { type: 'string', description: 'JWT access token' },
             },
           },
         },
       },
       async (connection, request) => {
         const user = await authenticateWebSocket(request);

         if (!user) {
           connection.socket.close(1008, 'Unauthorized');
           return;
         }

         if (user.activeContext?.type !== 'customer') {
           connection.socket.close(1008, 'Customer context required');
           return;
         }

         const clientId = randomUUID();

         // Get venue IDs for this customer
         const venues = await server.prisma.venue.findMany({
           where: { customerProfileId: user.activeContext.id },
           select: { id: true },
         });

         const venueIds = venues.map((v) => v.id);

         wsManager.addClient(
           clientId,
           connection.socket,
           user.sub,
           user.activeContext.id,
           venueIds
         );

         // Send welcome message
         connection.socket.send(
           JSON.stringify({
             type: 'connected',
             data: {
               clientId,
               venueCount: venueIds.length,
             },
           })
         );

         // Handle ping/pong for keep-alive
         const pingInterval = setInterval(() => {
           if (connection.socket.readyState === 1) {
             connection.socket.ping();
           }
         }, 30000);

         connection.socket.on('pong', () => {
           logger.debug({ clientId }, 'Pong received');
         });

         connection.socket.on('message', (message) => {
           try {
             const data = JSON.parse(message.toString());

             if (data.type === 'ping') {
               connection.socket.send(
                 JSON.stringify({
                   type: 'pong',
                   timestamp: new Date().toISOString(),
                 })
               );
             }
           } catch (error) {
             logger.error({ error, clientId }, 'Error processing WebSocket message');
           }
         });

         connection.socket.on('close', () => {
           clearInterval(pingInterval);
           wsManager.removeClient(clientId);
         });

         connection.socket.on('error', (error) => {
           logger.error({ error, clientId }, 'WebSocket error');
           clearInterval(pingInterval);
           wsManager.removeClient(clientId);
         });
       }
     );

     // Health check endpoint
     server.get(
       '/ws/stats',
       {
         schema: {
           tags: ['customer'],
           summary: 'WebSocket statistics',
           description: 'Get WebSocket connection statistics',
           security: [{ bearerAuth: [] }],
           response: {
             200: {
               description: 'WebSocket stats',
               type: 'object',
               properties: {
                 totalConnections: { type: 'integer' },
                 customerConnections: { type: 'integer' },
               },
             },
           },
         },
         preHandler: [server.authenticate],
       },
       async (request, reply) => {
         const customerProfileId = request.user.activeContext?.id;

         return reply.send({
           totalConnections: wsManager.getClientCount(),
           customerConnections: customerProfileId
             ? wsManager.getCustomerClientCount(customerProfileId)
             : 0,
         });
       }
     );
   };
   ```

7. **Register WebSocket in server setup:**
   ```typescript
   // Update apps/api/src/server.ts
   import websocket from '@fastify/websocket';

   export async function buildServer(): Promise<FastifyInstance> {
     const server = Fastify({
       // ... existing config
     });

     // ... existing plugins

     // Register WebSocket support
     await server.register(websocket);

     // ... rest of server setup

     return server;
   }
   ```

8. **Update customer routes to include WebSocket:**
   ```typescript
   // Update apps/api/src/routes/customer/index.ts
   import { FastifyPluginAsync } from 'fastify';
   import { venuesRoute } from './venues';
   import { systemsRoute } from './systems';
   import { songdbRoute } from './songdb';
   import { requestsRoute } from './requests';
   import { websocketRoute } from './websocket';

   export const customerRoutes: FastifyPluginAsync = async (server) => {
     await server.register(venuesRoute);
     await server.register(systemsRoute);
     await server.register(songdbRoute);
     await server.register(requestsRoute);
     await server.register(websocketRoute);
   };
   ```

**Deliverables:**
- ✅ WebSocket connection endpoint at `/v1/customer/ws`
- ✅ JWT authentication via query parameter
- ✅ Real-time new request notifications
- ✅ Real-time request update notifications
- ✅ Redis pub/sub for message distribution
- ✅ Connection management (add/remove clients)
- ✅ Automatic venue subscription based on customer profile
- ✅ Ping/pong keep-alive mechanism
- ✅ WebSocket statistics endpoint
- ✅ Customer context validation
- ✅ Graceful connection cleanup
- ✅ Error handling and logging

---

## Phase 11: API Key Management & OpenKJ Integration

### 11.1 API Key Generation & Management

**Objective:** Allow customers to generate and manage API keys for third-party integrations.

**Duration:** 2-3 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create API key schemas in `apps/api/src/routes/customer/schemas.ts`:**
   ```typescript
   // Add to existing schemas
   export const ApiKeyListQuerySchema = PaginationSchema.extend({
     active: z.coerce.boolean().optional(),
   });

   export const CreateApiKeySchema = z.object({
     name: z.string().min(1).max(100),
     description: z.string().max(500).optional(),
     expiresAt: z.string().datetime().optional(),
     scopes: z.array(z.string()).min(1).max(20),
   });

   export const UpdateApiKeySchema = z.object({
     name: z.string().min(1).max(100).optional(),
     description: z.string().max(500).optional(),
     active: z.boolean().optional(),
   });

   export const ApiKeyParamsSchema = z.object({
     id: z.string().uuid(),
   });

   export const ApiKeyResponseSchema = z.object({
     id: z.string().uuid(),
     name: z.string(),
     description: z.string().nullable(),
     prefix: z.string(),
     scopes: z.array(z.string()),
     active: z.boolean(),
     lastUsedAt: z.string().datetime().nullable(),
     expiresAt: z.string().datetime().nullable(),
     createdAt: z.string().datetime(),
   });

   export const ApiKeyWithSecretResponseSchema = ApiKeyResponseSchema.extend({
     key: z.string(),
   });
   ```

2. **Create API key service in `packages/shared/src/services/api-key-service.ts`:**
   ```typescript
   import { PrismaClient } from '@prisma/database';
   import { createLogger } from '@singr/observability';
   import { randomBytes, createHash } from 'crypto';
   import { API_KEY_PREFIX } from '@singr/config';

   const logger = createLogger('services:api-key');

   export interface ApiKeyFilters {
     active?: boolean;
   }

   export interface CreateApiKeyInput {
     customerProfileId: string;
     name: string;
     description?: string;
     expiresAt?: Date;
     scopes: string[];
     createdBy: string;
   }

   export class ApiKeyService {
     constructor(private prisma: PrismaClient) {}

     generateApiKey(): { key: string; hash: string; prefix: string } {
       // Generate random 32-byte key
       const randomKey = randomBytes(32).toString('base64url');
       
       // Create prefix (first 7 chars after the API_KEY_PREFIX)
       const prefix = randomKey.substring(0, 7);
       
       // Full key with prefix
       const key = `${API_KEY_PREFIX}${randomKey}`;
       
       // Hash for storage
       const hash = createHash('sha256').update(key).digest('hex');

       return { key, hash, prefix };
     }

     async listApiKeys(
       customerProfileId: string,
       filters: ApiKeyFilters,
       pagination: { page: number; limit: number }
     ) {
       const where: any = { customerProfileId };

       if (filters.active !== undefined) {
         where.active = filters.active;
       }

       const [apiKeys, total] = await Promise.all([
         this.prisma.apiKey.findMany({
           where,
           skip: (pagination.page - 1) * pagination.limit,
           take: pagination.limit,
           orderBy: { createdAt: 'desc' },
         }),
         this.prisma.apiKey.count({ where }),
       ]);

       return {
         data: apiKeys.map((k) => ({
           id: k.id,
           name: k.name,
           description: k.description,
           prefix: k.prefix,
           scopes: k.scopes as string[],
           active: k.active,
           lastUsedAt: k.lastUsedAt?.toISOString() || null,
           expiresAt: k.expiresAt?.toISOString() || null,
           createdAt: k.createdAt.toISOString(),
         })),
         pagination: {
           page: pagination.page,
           limit: pagination.limit,
           total,
           totalPages: Math.ceil(total / pagination.limit),
         },
       };
     }

     async getApiKey(apiKeyId: string, customerProfileId: string) {
       const apiKey = await this.prisma.apiKey.findFirst({
         where: {
           id: apiKeyId,
           customerProfileId,
         },
       });

       if (!apiKey) {
         throw new Error('API key not found');
       }

       return {
         id: apiKey.id,
         name: apiKey.name,
         description: apiKey.description,
         prefix: apiKey.prefix,
         scopes: apiKey.scopes as string[],
         active: apiKey.active,
         lastUsedAt: apiKey.lastUsedAt?.toISOString() || null,
         expiresAt: apiKey.expiresAt?.toISOString() || null,
         createdAt: apiKey.createdAt.toISOString(),
       };
     }

     async createApiKey(input: CreateApiKeyInput) {
       const { key, hash, prefix } = this.generateApiKey();

       const apiKey = await this.prisma.apiKey.create({
         data: {
           customerProfileId: input.customerProfileId,
           name: input.name,
           description: input.description,
           keyHash: hash,
           prefix,
           scopes: input.scopes,
           expiresAt: input.expiresAt,
           createdBy: input.createdBy,
         },
       });

       logger.info(
         {
           apiKeyId: apiKey.id,
           customerProfileId: input.customerProfileId,
           name: input.name,
           scopes: input.scopes,
         },
         'API key created'
       );

       return {
         id: apiKey.id,
         name: apiKey.name,
         description: apiKey.description,
         key, // Only returned on creation
         prefix: apiKey.prefix,
         scopes: apiKey.scopes as string[],
         active: apiKey.active,
         lastUsedAt: null,
         expiresAt: apiKey.expiresAt?.toISOString() || null,
         createdAt: apiKey.createdAt.toISOString(),
       };
     }

     async updateApiKey(
       apiKeyId: string,
       customerProfileId: string,
       input: { name?: string; description?: string; active?: boolean }
     ) {
       const apiKey = await this.prisma.apiKey.findFirst({
         where: {
           id: apiKeyId,
           customerProfileId,
         },
       });

       if (!apiKey) {
         throw new Error('API key not found');
       }

       const updated = await this.prisma.apiKey.update({
         where: { id: apiKeyId },
         data: {
           name: input.name,
           description: input.description,
           active: input.active,
         },
       });

       logger.info(
         {
           apiKeyId,
           customerProfileId,
         },
         'API key updated'
       );

       return {
         id: updated.id,
         name: updated.name,
         description: updated.description,
         prefix: updated.prefix,
         scopes: updated.scopes as string[],
         active: updated.active,
         lastUsedAt: updated.lastUsedAt?.toISOString() || null,
         expiresAt: updated.expiresAt?.toISOString() || null,
         createdAt: updated.createdAt.toISOString(),
       };
     }

     async revokeApiKey(apiKeyId: string, customerProfileId: string) {
       const apiKey = await this.prisma.apiKey.findFirst({
         where: {
           id: apiKeyId,
           customerProfileId,
         },
       });

       if (!apiKey) {
         throw new Error('API key not found');
       }

       await this.prisma.apiKey.update({
         where: { id: apiKeyId },
         data: { active: false },
       });

       logger.info(
         {
           apiKeyId,
           customerProfileId,
           name: apiKey.name,
         },
         'API key revoked'
       );
     }

     async deleteApiKey(apiKeyId: string, customerProfileId: string) {
       const apiKey = await this.prisma.apiKey.findFirst({
         where: {
           id: apiKeyId,
           customerProfileId,
         },
       });

       if (!apiKey) {
         throw new Error('API key not found');
       }

       await this.prisma.apiKey.delete({
         where: { id: apiKeyId },
       });

       logger.info(
         {
           apiKeyId,
           customerProfileId,
           name: apiKey.name,
         },
         'API key deleted'
       );
     }

     async verifyApiKey(key: string): Promise<{
       valid: boolean;
       customerProfileId?: string;
       scopes?: string[];
     }> {
       // Hash the provided key
       const hash = createHash('sha256').update(key).digest('hex');

       // Find API key
       const apiKey = await this.prisma.apiKey.findUnique({
         where: { keyHash: hash },
       });

       if (!apiKey) {
         return { valid: false };
       }

       // Check if active
       if (!apiKey.active) {
         logger.warn({ apiKeyId: apiKey.id }, 'Attempt to use inactive API key');
         return { valid: false };
       }

       // Check if expired
       if (apiKey.expiresAt && apiKey.expiresAt < new Date()) {
         logger.warn({ apiKeyId: apiKey.id }, 'Attempt to use expired API key');
         return { valid: false };
       }

       // Update last used timestamp (fire and forget)
       this.prisma.apiKey
         .update({
           where: { id: apiKey.id },
           data: { lastUsedAt: new Date() },
         })
         .catch((error) => {
           logger.error({ error, apiKeyId: apiKey.id }, 'Failed to update lastUsedAt');
         });

       return {
         valid: true,
         customerProfileId: apiKey.customerProfileId,
         scopes: apiKey.scopes as string[],
       };
     }

     async rotateApiKey(apiKeyId: string, customerProfileId: string) {
       const apiKey = await this.prisma.apiKey.findFirst({
         where: {
           id: apiKeyId,
           customerProfileId,
         },
       });

       if (!apiKey) {
         throw new Error('API key not found');
       }

       const { key, hash, prefix } = this.generateApiKey();

       const updated = await this.prisma.apiKey.update({
         where: { id: apiKeyId },
         data: {
           keyHash: hash,
           prefix,
         },
       });

       logger.info(
         {
           apiKeyId,
           customerProfileId,
           name: apiKey.name,
         },
         'API key rotated'
       );

       return {
         id: updated.id,
         name: updated.name,
         description: updated.description,
         key, // New key returned
         prefix: updated.prefix,
         scopes: updated.scopes as string[],
         active: updated.active,
         lastUsedAt: updated.lastUsedAt?.toISOString() || null,
         expiresAt: updated.expiresAt?.toISOString() || null,
         createdAt: updated.createdAt.toISOString(),
       };
     }
   }
   ```

3. **Create API key authentication hook in `packages/auth/src/api-key-auth.ts`:**
   ```typescript
   import { FastifyRequest, FastifyReply } from 'fastify';
   import { ApiKeyService } from '@singr/shared/services/api-key-service';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('auth:api-key');

   export async function authenticateApiKey(
     request: FastifyRequest,
     reply: FastifyReply
   ) {
     const apiKey = request.headers['x-api-key'] as string;

     if (!apiKey) {
       return reply.code(401).send({
         type: 'authentication_failed',
         title: 'API Key Required',
         detail: 'X-API-Key header is required',
       });
     }

     const apiKeyService = new ApiKeyService(request.server.prisma);
     const result = await apiKeyService.verifyApiKey(apiKey);

     if (!result.valid) {
       return reply.code(401).send({
         type: 'authentication_failed',
         title: 'Invalid API Key',
         detail: 'API key is invalid, expired, or revoked',
       });
     }

     // Attach to request for use in handlers
     (request as any).apiKeyAuth = {
       customerProfileId: result.customerProfileId,
       scopes: result.scopes,
     };
   }

   export function requireApiKeyScope(scope: string) {
     return async (request: FastifyRequest, reply: FastifyReply) => {
       const apiKeyAuth = (request as any).apiKeyAuth;

       if (!apiKeyAuth) {
         return reply.code(401).send({
           type: 'authentication_failed',
           title: 'Not Authenticated',
           detail: 'API key authentication required',
         });
       }

       if (!apiKeyAuth.scopes.includes(scope)) {
         logger.warn(
           {
             customerProfileId: apiKeyAuth.customerProfileId,
             requiredScope: scope,
             providedScopes: apiKeyAuth.scopes,
           },
           'API key missing required scope'
         );

         return reply.code(403).send({
           type: 'authorization_denied',
           title: 'Insufficient Scope',
           detail: `API key does not have required scope: ${scope}`,
         });
       }
     };
   }
   ```

4. **Implement API key routes in `apps/api/src/routes/customer/api-keys.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateQuery, validateParams, validateBody } from '@singr/shared/validation';
   import { requirePermission } from '@singr/auth';
   import {
     ApiKeyListQuerySchema,
     CreateApiKeySchema,
     UpdateApiKeySchema,
     ApiKeyParamsSchema,
   } from './schemas';
   import { ApiKeyService } from '@singr/shared/services/api-key-service';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:customer:api-keys');

   export const apiKeysRoute: FastifyPluginAsync = async (server) => {
     const apiKeyService = new ApiKeyService(server.prisma);

     // Available scopes
     const AVAILABLE_SCOPES = [
       'requests:read',
       'requests:write',
       'songdb:read',
       'songdb:write',
       'venues:read',
       'systems:read',
     ];

     // List API keys
     server.get(
       '/api-keys',
       {
         schema: {
           tags: ['customer'],
           summary: 'List API keys',
           description: 'Get all API keys for the customer',
           security: [{ bearerAuth: [] }],
           querystring: {
             type: 'object',
             properties: {
               page: { type: 'integer', minimum: 1, default: 1 },
               limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
               active: { type: 'boolean' },
             },
           },
           response: {
             200: {
               description: 'List of API keys',
               type: 'object',
               properties: {
                 data: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       id: { type: 'string', format: 'uuid' },
                       name: { type: 'string' },
                       prefix: { type: 'string' },
                       scopes: { type: 'array', items: { type: 'string' } },
                       active: { type: 'boolean' },
                       lastUsedAt: { type: 'string', format: 'date-time' },
                       expiresAt: { type: 'string', format: 'date-time' },
                       createdAt: { type: 'string', format: 'date-time' },
                     },
                   },
                 },
                 pagination: {
                   type: 'object',
                   properties: {
                     page: { type: 'integer' },
                     limit: { type: 'integer' },
                     total: { type: 'integer' },
                     totalPages: { type: 'integer' },
                   },
                 },
               },
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('api_keys:read'),
           validateQuery(ApiKeyListQuerySchema),
         ],
       },
       async (request, reply) => {
         const query = request.query as z.infer<typeof ApiKeyListQuerySchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to access this resource',
           });
         }

         const { page, limit, ...filters } = query;

         const result = await apiKeyService.listApiKeys(
           customerProfileId,
           filters,
           { page, limit }
         );

         return reply.send(result);
       }
     );

     // Get available scopes
     server.get(
       '/api-keys/scopes',
       {
         schema: {
           tags: ['customer'],
           summary: 'Get available scopes',
           description: 'Get list of available API key scopes',
           security: [{ bearerAuth: [] }],
           response: {
             200: {
               description: 'Available scopes',
               type: 'object',
               properties: {
                 scopes: {
                   type: 'array',
                   items: { type: 'string' },
                 },
               },
             },
           },
         },
         preHandler: [server.authenticate, requirePermission('api_keys:read')],
       },
       async (request, reply) => {
         return reply.send({ scopes: AVAILABLE_SCOPES });
       }
     );

     // Get API key details
     server.get(
       '/api-keys/:id',
       {
         schema: {
           tags: ['customer'],
           summary: 'Get API key',
           description: 'Get details of a specific API key',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'API key details',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 name: { type: 'string' },
                 description: { type: 'string' },
                 prefix: { type: 'string' },
                 scopes: { type: 'array', items: { type: 'string' } },
                 active: { type: 'boolean' },
                 lastUsedAt: { type: 'string', format: 'date-time' },
                 expiresAt: { type: 'string', format: 'date-time' },
                 createdAt: { type: 'string', format: 'date-time' },
               },
             },
             404: {
               description: 'API key not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('api_keys:read'),
           validateParams(ApiKeyParamsSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof ApiKeyParamsSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to access this resource',
           });
         }

         try {
           const apiKey = await apiKeyService.getApiKey(id, customerProfileId);
           return reply.send(apiKey);
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'API Key Not Found',
               detail: 'API key not found or access denied',
             });
           }
           throw error;
         }
       }
     );
   };
   
   // Create API key
     server.post(
       '/api-keys',
       {
         schema: {
           tags: ['customer'],
           summary: 'Create API key',
           description: 'Generate a new API key (key is only shown once)',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['name', 'scopes'],
             properties: {
               name: { type: 'string', minLength: 1, maxLength: 100 },
               description: { type: 'string', maxLength: 500 },
               expiresAt: { type: 'string', format: 'date-time' },
               scopes: {
                 type: 'array',
                 minItems: 1,
                 maxItems: 20,
                 items: { type: 'string' },
               },
             },
           },
           response: {
             201: {
               description: 'API key created (key only shown once)',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 name: { type: 'string' },
                 description: { type: 'string' },
                 key: { type: 'string', description: 'Full API key - save this now!' },
                 prefix: { type: 'string' },
                 scopes: { type: 'array', items: { type: 'string' } },
                 active: { type: 'boolean' },
                 expiresAt: { type: 'string', format: 'date-time' },
                 createdAt: { type: 'string', format: 'date-time' },
               },
             },
             400: {
               description: 'Invalid scopes provided',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('api_keys:write'),
           validateBody(CreateApiKeySchema),
         ],
       },
       async (request, reply) => {
         const body = request.body as z.infer<typeof CreateApiKeySchema>;
         const customerProfileId = request.user.activeContext?.id;
         const userId = request.user.sub;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to create API keys',
           });
         }

         // Validate scopes
         const invalidScopes = body.scopes.filter(
           (scope) => !AVAILABLE_SCOPES.includes(scope)
         );

         if (invalidScopes.length > 0) {
           return reply.code(400).send({
             type: 'validation_error',
             title: 'Invalid Scopes',
             detail: `Invalid scopes: ${invalidScopes.join(', ')}`,
           });
         }

         const apiKey = await apiKeyService.createApiKey({
           customerProfileId,
           name: body.name,
           description: body.description,
           expiresAt: body.expiresAt ? new Date(body.expiresAt) : undefined,
           scopes: body.scopes,
           createdBy: userId,
         });

         return reply.code(201).send(apiKey);
       }
     );

     // Update API key
     server.patch(
       '/api-keys/:id',
       {
         schema: {
           tags: ['customer'],
           summary: 'Update API key',
           description: 'Update API key name, description, or active status',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           body: {
             type: 'object',
             properties: {
               name: { type: 'string', minLength: 1, maxLength: 100 },
               description: { type: 'string', maxLength: 500 },
               active: { type: 'boolean' },
             },
           },
           response: {
             200: {
               description: 'API key updated',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 name: { type: 'string' },
                 description: { type: 'string' },
                 active: { type: 'boolean' },
               },
             },
             404: {
               description: 'API key not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('api_keys:write'),
           validateParams(ApiKeyParamsSchema),
           validateBody(UpdateApiKeySchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof ApiKeyParamsSchema>;
         const body = request.body as z.infer<typeof UpdateApiKeySchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to update API keys',
           });
         }

         try {
           const apiKey = await apiKeyService.updateApiKey(id, customerProfileId, body);
           return reply.send(apiKey);
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'API Key Not Found',
               detail: 'API key not found or access denied',
             });
           }
           throw error;
         }
       }
     );

     // Revoke API key
     server.post(
       '/api-keys/:id/revoke',
       {
         schema: {
           tags: ['customer'],
           summary: 'Revoke API key',
           description: 'Revoke an API key (marks as inactive)',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'API key revoked',
               type: 'object',
               properties: {
                 message: { type: 'string' },
               },
             },
             404: {
               description: 'API key not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('api_keys:revoke'),
           validateParams(ApiKeyParamsSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof ApiKeyParamsSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to revoke API keys',
           });
         }

         try {
           await apiKeyService.revokeApiKey(id, customerProfileId);
           return reply.send({
             message: 'API key revoked successfully',
           });
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'API Key Not Found',
               detail: 'API key not found or access denied',
             });
           }
           throw error;
         }
       }
     );

     // Rotate API key
     server.post(
       '/api-keys/:id/rotate',
       {
         schema: {
           tags: ['customer'],
           summary: 'Rotate API key',
           description: 'Generate a new key value (old key becomes invalid)',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'API key rotated (new key only shown once)',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 name: { type: 'string' },
                 key: { type: 'string', description: 'New API key - save this now!' },
                 prefix: { type: 'string' },
                 scopes: { type: 'array', items: { type: 'string' } },
               },
             },
             404: {
               description: 'API key not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('api_keys:write'),
           validateParams(ApiKeyParamsSchema),
         ],
         config: {
           rateLimit: {
             max: 5,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof ApiKeyParamsSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to rotate API keys',
           });
         }

         try {
           const apiKey = await apiKeyService.rotateApiKey(id, customerProfileId);
           return reply.send(apiKey);
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'API Key Not Found',
               detail: 'API key not found or access denied',
             });
           }
           throw error;
         }
       }
     );

     // Delete API key
     server.delete(
       '/api-keys/:id',
       {
         schema: {
           tags: ['customer'],
           summary: 'Delete API key',
           description: 'Permanently delete an API key',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             204: {
               description: 'API key deleted',
             },
             404: {
               description: 'API key not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('api_keys:write'),
           validateParams(ApiKeyParamsSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof ApiKeyParamsSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to delete API keys',
           });
         }

         try {
           await apiKeyService.deleteApiKey(id, customerProfileId);
           return reply.code(204).send();
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'API Key Not Found',
               detail: 'API key not found or access denied',
             });
           }
           throw error;
         }
       }
     );
   };
Register API keys route in apps/api/src/routes/customer/index.ts:
TypeScript
import { FastifyPluginAsync } from 'fastify';
import { venuesRoute } from './venues';
import { systemsRoute } from './systems';
import { songdbRoute } from './songdb';
import { requestsRoute } from './requests';
import { websocketRoute } from './websocket';
import { apiKeysRoute } from './api-keys';

export const customerRoutes: FastifyPluginAsync = async (server) => {
  await server.register(venuesRoute);
  await server.register(systemsRoute);
  await server.register(songdbRoute);
  await server.register(requestsRoute);
  await server.register(websocketRoute);
  await server.register(apiKeysRoute);
};
Deliverables:

✅ GET /v1/customer/api-keys - List all API keys
✅ GET /v1/customer/api-keys/scopes - Get available scopes
✅ GET /v1/customer/api-keys/:id - Get API key details
✅ POST /v1/customer/api-keys - Create new API key
✅ PATCH /v1/customer/api-keys/:id - Update API key
✅ POST /v1/customer/api-keys/:id/revoke - Revoke API key
✅ POST /v1/customer/api-keys/:id/rotate - Rotate API key secret
✅ DELETE /v1/customer/api-keys/:id - Delete API key
✅ SHA-256 hash storage for keys
✅ Prefix display for identification
✅ Scope-based authorization
✅ Expiration date support
✅ Last used timestamp tracking
✅ Key only shown once on creation/rotation
✅ Rate limiting on rotation
✅ RBAC permission checks (api_keys:read, api_keys:write, api_keys:revoke)

---

### 11.2 OpenKJ Integration Endpoints

**Objective:** Provide OpenKJ-compatible API endpoint matching the existing implementation.

**Duration:** 2-3 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create OpenKJ schemas in `apps/api/src/routes/openkj/schemas.ts`:**
   ```typescript
   import { z } from 'zod';

   // Base OpenKJ request schema
   export const OpenKJBaseSchema = z.object({
     api_key: z.string().min(1),
     command: z.string().min(1),
   });

   // Command-specific schemas
   export const OpenKJGetVenuesSchema = OpenKJBaseSchema.extend({
     command: z.literal('getVenues'),
   });

   export const OpenKJGetSongsSchema = OpenKJBaseSchema.extend({
     command: z.literal('getSongs'),
     system_id: z.coerce.number().optional(),
   });

   export const OpenKJAddRequestSchema = OpenKJBaseSchema.extend({
     command: z.literal('addRequest'),
     venue_id: z.coerce.number().int().positive(),
     singer: z.string().optional(),
     artist: z.string().min(1),
     title: z.string().min(1),
     key_change: z.coerce.number().int().min(-12).max(12).default(0),
   });

   export const OpenKJGetRequestsSchema = OpenKJBaseSchema.extend({
     command: z.literal('getRequests'),
     venue_id: z.coerce.number().int().positive(),
   });

   export const OpenKJClearRequestsSchema = OpenKJBaseSchema.extend({
     command: z.literal('clearRequests'),
     venue_id: z.coerce.number().int().positive(),
   });

   export const OpenKJDeleteRequestSchema = OpenKJBaseSchema.extend({
     command: z.literal('deleteRequest'),
     request_id: z.coerce.number().int().positive(),
   });

   // Union type for all commands
   export const OpenKJRequestSchema = z.discriminatedUnion('command', [
     OpenKJGetVenuesSchema,
     OpenKJGetSongsSchema,
     OpenKJAddRequestSchema,
     OpenKJGetRequestsSchema,
     OpenKJClearRequestsSchema,
     OpenKJDeleteRequestSchema,
   ]);
   ```

2. **Create OpenKJ service in `packages/shared/src/services/openkj-service.ts`:**
   ```typescript
   import { PrismaClient } from '@prisma/database';
   import { createLogger } from '@singr/observability';
   import { createHash } from 'crypto';

   const logger = createLogger('services:openkj');

   export class OpenKJService {
     constructor(private prisma: PrismaClient) {}

     async verifyApiKey(apiKey: string): Promise<string | null> {
       // Hash the API key
       const hash = createHash('sha256').update(apiKey).digest('hex');

       // Find API key
       const key = await this.prisma.apiKey.findUnique({
         where: { keyHash: hash },
       });

       if (!key || !key.active) {
         return null;
       }

       // Check expiration
       if (key.expiresAt && key.expiresAt < new Date()) {
         return null;
       }

       // Check scopes - OpenKJ needs at minimum requests:write and songdb:read
       const scopes = key.scopes as string[];
       if (!scopes.includes('requests:write') || !scopes.includes('songdb:read')) {
         logger.warn(
           { apiKeyId: key.id, scopes },
           'OpenKJ API key missing required scopes'
         );
         return null;
       }

       // Update last used (fire and forget)
       this.prisma.apiKey
         .update({
           where: { id: key.id },
           data: { lastUsedAt: new Date() },
         })
         .catch((err) => {
           logger.error({ error: err, apiKeyId: key.id }, 'Failed to update lastUsedAt');
         });

       return key.customerProfileId;
     }

     async getVenues(customerProfileId: string): Promise<
       Array<{
         venue_id: number;
         name: string;
         url_name: string;
         accepting: number;
       }>
     > {
       const venues = await this.prisma.venue.findMany({
         where: { customerProfileId },
         orderBy: { name: 'asc' },
       });

       return venues.map((v) => ({
         venue_id: v.openkjVenueId,
         name: v.name,
         url_name: v.urlName,
         accepting: v.acceptingRequests ? 1 : 0,
       }));
     }

     async getSongs(
       customerProfileId: string,
       systemId?: number
     ): Promise<
       Array<{
         song_id: number;
         artist: string;
         title: string;
         songid: string;
       }>
     > {
       const where: any = { customerProfileId };

       if (systemId) {
         where.openkjSystemId = systemId;
       }

       const songs = await this.prisma.songDb.findMany({
         where,
         orderBy: [{ artist: 'asc' }, { title: 'asc' }],
       });

       return songs.map((s) => ({
         song_id: Number(s.id),
         artist: s.artist,
         title: s.title,
         songid: String(s.id), // OpenKJ expects string
       }));
     }

     async addRequest(
       customerProfileId: string,
       venueId: number,
       data: {
         singer?: string;
         artist: string;
         title: string;
         key_change: number;
       }
     ): Promise<{ request_id: number }> {
       // Find venue
       const venue = await this.prisma.venue.findFirst({
         where: {
           customerProfileId,
           openkjVenueId: venueId,
         },
       });

       if (!venue) {
         throw new Error('Venue not found');
       }

       if (!venue.acceptingRequests) {
         throw new Error('Venue not accepting requests');
       }

       // Create request
       const request = await this.prisma.request.create({
         data: {
           venueId: venue.id,
           artist: data.artist,
           title: data.title,
           keyChange: data.key_change,
           notes: data.singer ? `Singer: ${data.singer}` : null,
         },
       });

       // Add to history if we have singer info
       // Note: We don't have singerProfileId from OpenKJ, so this is a guest request
       await this.prisma.singerRequestHistory.create({
         data: {
           venueId: venue.id,
           artist: data.artist,
           title: data.title,
           keyChange: data.key_change,
           songFingerprint: `${data.artist.toLowerCase()}::${data.title.toLowerCase()}`,
         },
       });

       logger.info(
         {
           requestId: request.id,
           venueId: venue.id,
           customerProfileId,
         },
         'OpenKJ request added'
       );

       return { request_id: Number(request.id) };
     }

     async getRequests(
       customerProfileId: string,
       venueId: number
     ): Promise<
       Array<{
         request_id: number;
         singer: string;
         artist: string;
         title: string;
         key_change: number;
         request_time: string;
       }>
     > {
       // Find venue
       const venue = await this.prisma.venue.findFirst({
         where: {
           customerProfileId,
           openkjVenueId: venueId,
         },
       });

       if (!venue) {
         throw new Error('Venue not found');
       }

       // Get pending requests only
       const requests = await this.prisma.request.findMany({
         where: {
           venueId: venue.id,
           processed: false,
         },
         orderBy: { requestedAt: 'asc' },
         include: {
           singerProfile: {
             select: {
               nickname: true,
               user: {
                 select: { name: true },
               },
             },
           },
         },
       });

       return requests.map((r) => {
         // Extract singer name from notes if it exists, otherwise use profile
         let singerName = '';
         if (r.notes?.startsWith('Singer: ')) {
           singerName = r.notes.replace('Singer: ', '');
         } else if (r.singerProfile) {
           singerName =
             r.singerProfile.nickname ||
             r.singerProfile.user.name ||
             'Unknown Singer';
         }

         return {
           request_id: Number(r.id),
           singer: singerName,
           artist: r.artist,
           title: r.title,
           key_change: r.keyChange,
           request_time: Math.floor(r.requestedAt.getTime() / 1000).toString(),
         };
       });
     }

     async clearRequests(
       customerProfileId: string,
       venueId: number
     ): Promise<{ deleted: number }> {
       // Find venue
       const venue = await this.prisma.venue.findFirst({
         where: {
           customerProfileId,
           openkjVenueId: venueId,
         },
       });

       if (!venue) {
         throw new Error('Venue not found');
       }

       // Delete all pending requests for this venue
       const result = await this.prisma.request.deleteMany({
         where: {
           venueId: venue.id,
           processed: false,
         },
       });

       logger.info(
         {
           venueId: venue.id,
           customerProfileId,
           count: result.count,
         },
         'OpenKJ requests cleared'
       );

       return { deleted: result.count };
     }

     async deleteRequest(
       customerProfileId: string,
       requestId: number
     ): Promise<void> {
       // Find request and verify ownership
       const request = await this.prisma.request.findFirst({
         where: {
           id: BigInt(requestId),
           venue: { customerProfileId },
         },
       });

       if (!request) {
         throw new Error('Request not found');
       }

       await this.prisma.request.delete({
         where: { id: BigInt(requestId) },
       });

       logger.info(
         {
           requestId,
           customerProfileId,
         },
         'OpenKJ request deleted'
       );
     }
   }
   ```

3. **Implement OpenKJ route in `apps/api/src/routes/openkj/index.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { OpenKJRequestSchema } from './schemas';
   import { OpenKJService } from '@singr/shared/services/openkj-service';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:openkj');

   export const openkjRoutes: FastifyPluginAsync = async (server) => {
     const openkjService = new OpenKJService(server.prisma);

     // Single endpoint for all OpenKJ commands
     server.post(
       '/api',
       {
         schema: {
           tags: ['openkj'],
           summary: 'OpenKJ API endpoint',
           description: 'Single endpoint handling all OpenKJ commands',
           body: {
             type: 'object',
             required: ['api_key', 'command'],
             properties: {
               api_key: { type: 'string' },
               command: { type: 'string' },
               venue_id: { type: 'integer' },
               system_id: { type: 'integer' },
               singer: { type: 'string' },
               artist: { type: 'string' },
               title: { type: 'string' },
               key_change: { type: 'integer' },
               request_id: { type: 'integer' },
             },
           },
           response: {
             200: {
               description: 'Command response',
               type: 'object',
             },
             401: {
               description: 'Invalid API key',
               type: 'object',
               properties: {
                 error: { type: 'string' },
               },
             },
             400: {
               description: 'Invalid request',
               type: 'object',
               properties: {
                 error: { type: 'string' },
               },
             },
           },
         },
         config: {
           rateLimit: {
             max: 100,
             timeWindow: '1 minute',
           },
         },
       },
       async (request, reply) => {
         const body = request.body as any;

         // Validate API key first
         const customerProfileId = await openkjService.verifyApiKey(body.api_key);

         if (!customerProfileId) {
           logger.warn(
             { command: body.command, ip: request.ip },
             'OpenKJ API call with invalid key'
           );
           return reply.code(401).send({
             error: 'Invalid API key',
           });
         }

         try {
           // Validate request with Zod
           const validated = OpenKJRequestSchema.parse(body);

           // Route to appropriate handler based on command
           switch (validated.command) {
             case 'getVenues': {
               const venues = await openkjService.getVenues(customerProfileId);
               return reply.send({ venues });
             }

             case 'getSongs': {
               const songs = await openkjService.getSongs(
                 customerProfileId,
                 validated.system_id
               );
               return reply.send({ songs });
             }

             case 'addRequest': {
               const result = await openkjService.addRequest(
                 customerProfileId,
                 validated.venue_id,
                 {
                   singer: validated.singer,
                   artist: validated.artist,
                   title: validated.title,
                   key_change: validated.key_change,
                 }
               );
               return reply.send(result);
             }

             case 'getRequests': {
               const requests = await openkjService.getRequests(
                 customerProfileId,
                 validated.venue_id
               );
               return reply.send({ requests });
             }

             case 'clearRequests': {
               const result = await openkjService.clearRequests(
                 customerProfileId,
                 validated.venue_id
               );
               return reply.send(result);
             }

             case 'deleteRequest': {
               await openkjService.deleteRequest(
                 customerProfileId,
                 validated.request_id
               );
               return reply.send({ success: true });
             }

             default:
               return reply.code(400).send({
                 error: 'Unknown command',
               });
           }
         } catch (error) {
           if (error instanceof Error) {
             logger.error(
               {
                 error,
                 command: body.command,
                 customerProfileId,
               },
               'OpenKJ API error'
             );

             if (error.message.includes('not found')) {
               return reply.code(404).send({
                 error: error.message,
               });
             }

             if (error.message.includes('not accepting')) {
               return reply.code(422).send({
                 error: error.message,
               });
             }

             // Validation errors
             if (error.name === 'ZodError') {
               return reply.code(400).send({
                 error: 'Invalid request parameters',
               });
             }
           }

           return reply.code(500).send({
             error: 'Internal server error',
           });
         }
       }
     );
   };
   ```

4. **Register OpenKJ routes in main API:**
   ```typescript
   // Update apps/api/src/server.ts
   import { openkjRoutes } from './routes/openkj';

   // In the route registration section:
   await server.register(openkjRoutes, { prefix: '/openkj' });
   ```

5. **Create OpenKJ integration documentation in `docs/OPENKJ_INTEGRATION.md`:**
   ````markdown
   # OpenKJ Integration Guide

   ## Overview

   Singr provides a single API endpoint compatible with the OpenKJ karaoke hosting software.

   ## Endpoint

   ```
   POST https://api.singrkaraoke.com/openkj/api
   ```

   ## Authentication

   All requests require an `api_key` parameter in the request body. Generate an API key in your Singr customer dashboard with the following scopes:
   - `requests:write`
   - `songdb:read`
   - `venues:read`

   ## Commands

   ### Get Venues

   Retrieve all venues for your account.

   **Request:**
   ```json
   {
     "api_key": "your_api_key",
     "command": "getVenues"
   }
   ```

   **Response:**
   ```json
   {
     "venues": [
       {
         "venue_id": 1001,
         "name": "The Karaoke Bar",
         "url_name": "the-karaoke-bar",
         "accepting": 1
       }
     ]
   }
   ```

   ### Get Songs

   Retrieve song database for a specific system (optional).

   **Request:**
   ```json
   {
     "api_key": "your_api_key",
     "command": "getSongs",
     "system_id": 1001
   }
   ```

   **Response:**
   ```json
   {
     "songs": [
       {
         "song_id": 12345,
         "artist": "Queen",
         "title": "Bohemian Rhapsody",
         "songid": "12345"
       }
     ]
   }
   ```

   ### Add Request

   Submit a new song request to a venue.

   **Request:**
   ```json
   {
     "api_key": "your_api_key",
     "command": "addRequest",
     "venue_id": 1001,
     "singer": "John Doe",
     "artist": "Queen",
     "title": "Bohemian Rhapsody",
     "key_change": 0
   }
   ```

   **Response:**
   ```json
   {
     "request_id": 54321
   }
   ```

   ### Get Requests

   Retrieve all pending requests for a venue.

   **Request:**
   ```json
   {
     "api_key": "your_api_key",
     "command": "getRequests",
     "venue_id": 1001
   }
   ```

   **Response:**
   ```json
   {
     "requests": [
       {
         "request_id": 54321,
         "singer": "John Doe",
         "artist": "Queen",
         "title": "Bohemian Rhapsody",
         "key_change": 0,
         "request_time": "1699738800"
       }
     ]
   }
   ```

   ### Clear Requests

   Delete all pending requests for a venue.

   **Request:**
   ```json
   {
     "api_key": "your_api_key",
     "command": "clearRequests",
     "venue_id": 1001
   }
   ```

   **Response:**
   ```json
   {
     "deleted": 5
   }
   ```

   ### Delete Request

   Delete a specific request.

   **Request:**
   ```json
   {
     "api_key": "your_api_key",
     "command": "deleteRequest",
     "request_id": 54321
   }
   ```

   **Response:**
   ```json
   {
     "success": true
   }
   ```

   ## Error Responses

   ### 401 Unauthorized
   ```json
   {
     "error": "Invalid API key"
   }
   ```

   ### 400 Bad Request
   ```json
   {
     "error": "Invalid request parameters"
   }
   ```

   ### 404 Not Found
   ```json
   {
     "error": "Venue not found"
   }
   ```

   ### 422 Unprocessable Entity
   ```json
   {
     "error": "Venue not accepting requests"
   }
   ```

   ## Rate Limits

   - 100 requests per minute per API key

   ## OpenKJ Configuration

   In your OpenKJ application, configure:

   1. **API Endpoint:** `https://api.singrkaraoke.com/openkj/api`
   2. **API Key:** Your generated API key from Singr
   3. **Venue ID:** The `venue_id` from the `getVenues` response

   ## Notes

   - All requests must be sent as `POST` with `Content-Type: application/json`
   - The `request_time` field is a Unix timestamp (seconds since epoch)
   - The `accepting` field is `1` for true, `0` for false
   - Singer names from OpenKJ are stored in the request notes
   - Key changes range from -12 to +12 (semitones)
   ````

6. **Add test for OpenKJ endpoint:**
   ```typescript
   // Create apps/api/src/routes/openkj/__tests__/openkj.test.ts
   import { buildServer } from '../../../server';
   import { FastifyInstance } from 'fastify';

   describe('OpenKJ API', () => {
     let server: FastifyInstance;
     let apiKey: string;
     let customerProfileId: string;
     let venueId: number;

     beforeAll(async () => {
       server = await buildServer();
       await server.ready();

       // Setup test data
       // ... (create customer profile, API key, venue, etc.)
     });

     afterAll(async () => {
       await server.close();
     });

     describe('POST /openkj/api', () => {
       it('should return error for invalid API key', async () => {
         const response = await server.inject({
           method: 'POST',
           url: '/openkj/api',
           payload: {
             api_key: 'invalid_key',
             command: 'getVenues',
           },
         });

         expect(response.statusCode).toBe(401);
         expect(JSON.parse(response.payload)).toEqual({
           error: 'Invalid API key',
         });
       });

       it('should get venues', async () => {
         const response = await server.inject({
           method: 'POST',
           url: '/openkj/api',
           payload: {
             api_key: apiKey,
             command: 'getVenues',
           },
         });

         expect(response.statusCode).toBe(200);
         const data = JSON.parse(response.payload);
         expect(data.venues).toBeInstanceOf(Array);
         expect(data.venues[0]).toHaveProperty('venue_id');
         expect(data.venues[0]).toHaveProperty('name');
       });

       it('should add request', async () => {
         const response = await server.inject({
           method: 'POST',
           url: '/openkj/api',
           payload: {
             api_key: apiKey,
             command: 'addRequest',
             venue_id: venueId,
             singer: 'Test Singer',
             artist: 'Test Artist',
             title: 'Test Song',
             key_change: 0,
           },
         });

         expect(response.statusCode).toBe(200);
         const data = JSON.parse(response.payload);
         expect(data).toHaveProperty('request_id');
         expect(typeof data.request_id).toBe('number');
       });

       it('should get requests', async () => {
         const response = await server.inject({
           method: 'POST',
           url: '/openkj/api',
           payload: {
             api_key: apiKey,
             command: 'getRequests',
             venue_id: venueId,
           },
         });

         expect(response.statusCode).toBe(200);
         const data = JSON.parse(response.payload);
         expect(data.requests).toBeInstanceOf(Array);
       });

       it('should return error for unknown command', async () => {
         const response = await server.inject({
           method: 'POST',
           url: '/openkj/api',
           payload: {
             api_key: apiKey,
             command: 'unknownCommand',
           },
         });

         expect(response.statusCode).toBe(400);
         expect(JSON.parse(response.payload)).toEqual({
           error: 'Unknown command',
         });
       });
     });
   });
   ```

**Deliverables:**
- ✅ Single `POST /openkj/api` endpoint matching original implementation
- ✅ Command-based routing (getVenues, getSongs, addRequest, getRequests, clearRequests, deleteRequest)
- ✅ API key authentication via request body
- ✅ Exact response format matching original portal
- ✅ Unix timestamp format for request_time
- ✅ Singer name extraction from notes
- ✅ Request history tracking
- ✅ Venue ID mapping via openkjVenueId
- ✅ System ID filtering for songs
- ✅ Pending requests only for getRequests
- ✅ Bulk clear requests functionality
- ✅ Rate limiting (100 req/min)
- ✅ Comprehensive error handling
- ✅ Integration documentation
- ✅ Unit tests

---

## Phase 12: Customer Organization & Team Management

### 12.1 Organization User Management

**Objective:** Allow customer owners to invite and manage team members with role-based access.

**Duration:** 3 days  
**Team Size:** 1 developer

**Tasks:**

1. **Create organization schemas in `apps/api/src/routes/customer/schemas.ts`:**
   ```typescript
   // Add to existing schemas
   export const OrganizationUserQuerySchema = PaginationSchema.extend({
     role: z.string().optional(),
     search: z.string().max(100).optional(),
   });

   export const InviteUserSchema = z.object({
     email: EmailSchema,
     roleId: z.string().uuid(),
     permissions: z.array(z.string().uuid()).optional(),
   });

   export const UpdateOrganizationUserSchema = z.object({
     roleId: z.string().uuid().optional(),
     permissions: z.array(z.string().uuid()).optional(),
   });

   export const OrganizationUserParamsSchema = z.object({
     id: z.string().uuid(),
   });

   export const OrganizationUserResponseSchema = z.object({
     id: z.string().uuid(),
     userId: z.string().uuid(),
     email: z.string().email(),
     name: z.string().nullable(),
     role: z.object({
       id: z.string().uuid(),
       slug: z.string(),
       name: z.string(),
     }),
     permissions: z.array(
       z.object({
         id: z.string().uuid(),
         slug: z.string(),
         description: z.string(),
       })
     ),
     invitedAt: z.string().datetime(),
     acceptedAt: z.string().datetime().nullable(),
   });
   ```

2. **Create organization service in `packages/shared/src/services/organization-service.ts`:**
   ```typescript
   import { PrismaClient } from '@prisma/database';
   import { createLogger } from '@singr/observability';
   import { randomUUID } from 'crypto';
   import { Redis } from 'ioredis';
   import { TOKEN_EXPIRY } from '@singr/config';

   const logger = createLogger('services:organization');

   export interface OrganizationUserFilters {
     role?: string;
     search?: string;
   }

   export interface InviteUserInput {
     customerProfileId: string;
     email: string;
     roleId: string;
     permissions?: string[];
     invitedBy: string;
     inviterName: string;
     organizationName: string;
   }

   export class OrganizationService {
     constructor(
       private prisma: PrismaClient,
       private redis: Redis
     ) {}

     async listOrganizationUsers(
       customerProfileId: string,
       filters: OrganizationUserFilters,
       pagination: { page: number; limit: number }
     ) {
       const where: any = {
         customerProfileId,
       };

       if (filters.role) {
         where.role = {
           slug: filters.role,
         };
       }

       if (filters.search) {
         where.user = {
           OR: [
             { email: { contains: filters.search, mode: 'insensitive' } },
             { name: { contains: filters.search, mode: 'insensitive' } },
           ],
         };
       }

       const [orgUsers, total] = await Promise.all([
         this.prisma.organizationUser.findMany({
           where,
           skip: (pagination.page - 1) * pagination.limit,
           take: pagination.limit,
           orderBy: { invitedAt: 'desc' },
           include: {
             user: {
               select: {
                 id: true,
                 email: true,
                 name: true,
               },
             },
             role: {
               select: {
                 id: true,
                 slug: true,
                 description: true,
               },
             },
             permissions: {
               include: {
                 permission: {
                   select: {
                     id: true,
                     slug: true,
                     description: true,
                   },
                 },
               },
             },
           },
         }),
         this.prisma.organizationUser.count({ where }),
       ]);

       return {
         data: orgUsers.map((ou) => ({
           id: ou.id,
           userId: ou.userId,
           email: ou.user.email,
           name: ou.user.name,
           role: {
             id: ou.role.id,
             slug: ou.role.slug,
             name: ou.role.description,
           },
           permissions: ou.permissions.map((p) => ({
             id: p.permission.id,
             slug: p.permission.slug,
             description: p.permission.description,
           })),
           invitedAt: ou.invitedAt.toISOString(),
           acceptedAt: ou.acceptedAt?.toISOString() || null,
         })),
         pagination: {
           page: pagination.page,
           limit: pagination.limit,
           total,
           totalPages: Math.ceil(total / pagination.limit),
         },
       };
     }

     async getOrganizationUser(
       orgUserId: string,
       customerProfileId: string
     ) {
       const orgUser = await this.prisma.organizationUser.findFirst({
         where: {
           id: orgUserId,
           customerProfileId,
         },
         include: {
           user: {
             select: {
               id: true,
               email: true,
               name: true,
             },
           },
           role: {
             select: {
               id: true,
               slug: true,
               description: true,
             },
           },
           permissions: {
             include: {
               permission: {
                 select: {
                   id: true,
                   slug: true,
                   description: true,
                 },
               },
             },
           },
         },
       });

       if (!orgUser) {
         throw new Error('Organization user not found');
       }

       return {
         id: orgUser.id,
         userId: orgUser.userId,
         email: orgUser.user.email,
         name: orgUser.user.name,
         role: {
           id: orgUser.role.id,
           slug: orgUser.role.slug,
           name: orgUser.role.description,
         },
         permissions: orgUser.permissions.map((p) => ({
           id: p.permission.id,
           slug: p.permission.slug,
           description: p.permission.description,
         })),
         invitedAt: orgUser.invitedAt.toISOString(),
         acceptedAt: orgUser.acceptedAt?.toISOString() || null,
       };
     }

     async inviteUser(input: InviteUserInput, communicationQueue: any) {
       // Check if user already exists
       const existingUser = await this.prisma.user.findUnique({
         where: { email: input.email.toLowerCase() },
       });

       let user = existingUser;

       // If user doesn't exist, create a placeholder
       if (!existingUser) {
         user = await this.prisma.user.create({
           data: {
             email: input.email.toLowerCase(),
             passwordHash: '', // Will be set when they accept invitation
             passwordAlgo: 'argon2id',
             isEmailVerified: false,
           },
         });
       }

       // Check if already in organization
       const existing = await this.prisma.organizationUser.findFirst({
         where: {
           customerProfileId: input.customerProfileId,
           userId: user!.id,
         },
       });

       if (existing) {
         throw new Error('User is already a member of this organization');
       }

       // Create organization user
       const orgUser = await this.prisma.organizationUser.create({
         data: {
           customerProfileId: input.customerProfileId,
           userId: user!.id,
           roleId: input.roleId,
           invitedAt: new Date(),
         },
       });

       // Add custom permissions if provided
       if (input.permissions && input.permissions.length > 0) {
         await this.prisma.organizationUserPermission.createMany({
           data: input.permissions.map((permissionId) => ({
             organizationUserId: orgUser.id,
             permissionId,
           })),
         });
       }

       // Generate invitation token
       const invitationToken = randomUUID();
       await this.prisma.verificationToken.create({
         data: {
           identifier: input.email.toLowerCase(),
           token: invitationToken,
           expiresAt: new Date(Date.now() + TOKEN_EXPIRY.INVITATION),
         },
       });

       // Send invitation email
       await communicationQueue.add('email', {
         type: 'email',
         to: input.email,
         subject: `${input.inviterName} invited you to ${input.organizationName}`,
         templateId: parseInt(process.env.MAILJET_TEMPLATE_INVITATION || '0'),
         variables: {
           inviter_name: input.inviterName,
           organization_name: input.organizationName,
           invitation_link: `${process.env.APP_URL_CUSTOMER}/invitation?token=${invitationToken}`,
           expiry_days: Math.floor(TOKEN_EXPIRY.INVITATION / (1000 * 60 * 60 * 24)),
         },
       });

       logger.info(
         {
           orgUserId: orgUser.id,
           email: input.email,
           customerProfileId: input.customerProfileId,
           invitedBy: input.invitedBy,
         },
         'User invited to organization'
       );

       return {
         id: orgUser.id,
         email: input.email,
         invitationToken,
       };
     }

     async acceptInvitation(token: string, userId: string) {
       // Find and verify token
       const verificationToken = await this.prisma.verificationToken.findFirst({
         where: {
           token,
           expiresAt: { gt: new Date() },
         },
       });

       if (!verificationToken) {
         throw new Error('Invalid or expired invitation token');
       }

       // Find the user by email
       const user = await this.prisma.user.findUnique({
         where: { email: verificationToken.identifier },
       });

       if (!user || user.id !== userId) {
         throw new Error('Invalid invitation');
       }

       // Find organization user
       const orgUser = await this.prisma.organizationUser.findFirst({
         where: {
           userId: user.id,
           acceptedAt: null,
         },
       });

       if (!orgUser) {
         throw new Error('Invitation not found');
       }

       // Mark as accepted
       await this.prisma.organizationUser.update({
         where: { id: orgUser.id },
         data: { acceptedAt: new Date() },
       });

       // Delete token
       await this.prisma.verificationToken.delete({
         where: {
           identifier_token: {
             identifier: verificationToken.identifier,
             token: verificationToken.token,
           },
         },
       });

       logger.info(
         {
           orgUserId: orgUser.id,
           userId,
         },
         'Organization invitation accepted'
       );

       return orgUser.customerProfileId;
     }

     async updateOrganizationUser(
       orgUserId: string,
       customerProfileId: string,
       input: {
         roleId?: string;
         permissions?: string[];
       }
     ) {
       const orgUser = await this.prisma.organizationUser.findFirst({
         where: {
           id: orgUserId,
           customerProfileId,
         },
       });

       if (!orgUser) {
         throw new Error('Organization user not found');
       }

       // Update role if provided
       if (input.roleId) {
         await this.prisma.organizationUser.update({
           where: { id: orgUserId },
           data: { roleId: input.roleId },
         });
       }

       // Update permissions if provided
       if (input.permissions !== undefined) {
         // Delete existing permissions
         await this.prisma.organizationUserPermission.deleteMany({
           where: { organizationUserId: orgUserId },
         });

         // Add new permissions
         if (input.permissions.length > 0) {
           await this.prisma.organizationUserPermission.createMany({
             data: input.permissions.map((permissionId) => ({
               organizationUserId: orgUserId,
               permissionId,
             })),
           });
         }
       }

       logger.info(
         {
           orgUserId,
           customerProfileId,
         },
         'Organization user updated'
       );

       return this.getOrganizationUser(orgUserId, customerProfileId);
     }

     async removeOrganizationUser(
       orgUserId: string,
       customerProfileId: string
     ) {
       const orgUser = await this.prisma.organizationUser.findFirst({
         where: {
           id: orgUserId,
           customerProfileId,
         },
         include: {
           role: true,
         },
       });

       if (!orgUser) {
         throw new Error('Organization user not found');
       }

       // Don't allow removing the owner
       if (orgUser.role.slug === 'customer_owner') {
         throw new Error('Cannot remove the organization owner');
       }

       await this.prisma.organizationUser.delete({
         where: { id: orgUserId },
       });

       logger.info(
         {
           orgUserId,
           customerProfileId,
         },
         'Organization user removed'
       );
     }

     async resendInvitation(
       orgUserId: string,
       customerProfileId: string,
       inviterName: string,
       organizationName: string,
       communicationQueue: any
     ) {
       const orgUser = await this.prisma.organizationUser.findFirst({
         where: {
           id: orgUserId,
           customerProfileId,
           acceptedAt: null, // Only resend for pending invitations
         },
         include: {
           user: {
             select: {
               email: true,
             },
           },
         },
       });

       if (!orgUser) {
         throw new Error('Pending invitation not found');
       }

       // Delete old token if exists
       await this.prisma.verificationToken.deleteMany({
         where: { identifier: orgUser.user.email },
       });

       // Generate new invitation token
       const invitationToken = randomUUID();
       await this.prisma.verificationToken.create({
         data: {
           identifier: orgUser.user.email,
           token: invitationToken,
           expiresAt: new Date(Date.now() + TOKEN_EXPIRY.INVITATION),
         },
       });

       // Resend invitation email
       await communicationQueue.add('email', {
         type: 'email',
         to: orgUser.user.email,
         subject: `${inviterName} invited you to ${organizationName}`,
         templateId: parseInt(process.env.MAILJET_TEMPLATE_INVITATION || '0'),
         variables: {
           inviter_name: inviterName,
           organization_name: organizationName,
           invitation_link: `${process.env.APP_URL_CUSTOMER}/invitation?token=${invitationToken}`,
           expiry_days: Math.floor(TOKEN_EXPIRY.INVITATION / (1000 * 60 * 60 * 24)),
         },
       });

       logger.info(
         {
           orgUserId,
           email: orgUser.user.email,
           customerProfileId,
         },
         'Invitation resent'
       );
     }

     async getAvailableRoles() {
       const roles = await this.prisma.role.findMany({
         where: {
           slug: {
             in: ['customer_owner', 'customer_manager', 'customer_staff'],
           },
         },
         select: {
           id: true,
           slug: true,
           description: true,
         },
       });

       return roles.map((r) => ({
         id: r.id,
         slug: r.slug,
         name: r.description,
       }));
     }

     async getAvailablePermissions() {
       const permissions = await this.prisma.permission.findMany({
         orderBy: { slug: 'asc' },
         select: {
           id: true,
           slug: true,
           description: true,
         },
       });

       return permissions;
     }
   }
   ```

3. **Implement organization routes in `apps/api/src/routes/customer/organization.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateQuery, validateParams, validateBody } from '@singr/shared/validation';
   import { requirePermission } from '@singr/auth';
   import {
     OrganizationUserQuerySchema,
     InviteUserSchema,
     UpdateOrganizationUserSchema,
     OrganizationUserParamsSchema,
   } from './schemas';
   import { OrganizationService } from '@singr/shared/services/organization-service';
   import { createCommunicationQueue } from '@singr/shared/queues/communication-queue';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:customer:organization');

   export const organizationRoute: FastifyPluginAsync = async (server) => {
     const organizationService = new OrganizationService(
       server.prisma,
       server.redis
     );
     const communicationQueue = createCommunicationQueue(server.redis);

     // List organization users
     server.get(
       '/organization/users',
       {
         schema: {
           tags: ['customer'],
           summary: 'List organization users',
           description: 'Get all users in the organization',
           security: [{ bearerAuth: [] }],
           querystring: {
             type: 'object',
             properties: {
               page: { type: 'integer', minimum: 1, default: 1 },
               limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
               role: { type: 'string' },
               search: { type: 'string' },
             },
           },
           response: {
             200: {
               description: 'List of organization users',
               type: 'object',
               properties: {
                 data: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       id: { type: 'string', format: 'uuid' },
                       userId: { type: 'string', format: 'uuid' },
                       email: { type: 'string' },
                       name: { type: 'string' },
                       role: {
                         type: 'object',
                         properties: {
                           id: { type: 'string', format: 'uuid' },
                           slug: { type: 'string' },
                           name: { type: 'string' },
                         },
                       },
                       invitedAt: { type: 'string', format: 'date-time' },
                       acceptedAt: { type: 'string', format: 'date-time' },
                     },
                   },
                 },
                 pagination: {
                   type: 'object',
                   properties: {
                     page: { type: 'integer' },
                     limit: { type: 'integer' },
                     total: { type: 'integer' },
                     totalPages: { type: 'integer' },
                   },
                 },
               },
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('organization:read'),
           validateQuery(OrganizationUserQuerySchema),
         ],
       },
       async (request, reply) => {
         const query = request.query as z.infer<typeof OrganizationUserQuerySchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to access this resource',
           });
         }

         const { page, limit, ...filters } = query;

         const result = await organizationService.listOrganizationUsers(
           customerProfileId,
           filters,
           { page, limit }
         );

         return reply.send(result);
       }
     );

   };

     // Get available roles
     server.get(
       '/organization/roles',
       {
         schema: {
           tags: ['customer'],
           summary: 'Get available roles',
           description: 'Get list of available organization roles',
           security: [{ bearerAuth: [] }],
           response: {
             200: {
               description: 'Available roles',
               type: 'array',
               items: {
                 type: 'object',
                 properties: {
                   id: { type: 'string', format: 'uuid' },
                   slug: { type: 'string' },
                   name: { type: 'string' },
                 },
               },
             },
           },
         },
         preHandler: [server.authenticate, requirePermission('organization:read')],
       },
       async (request, reply) => {
         const roles = await organizationService.getAvailableRoles();
         return reply.send(roles);
       }
     );

     // Get available permissions
     server.get(
       '/organization/permissions',
       {
         schema: {
           tags: ['customer'],
           summary: 'Get available permissions',
           description: 'Get list of available permissions for custom access',
           security: [{ bearerAuth: [] }],
           response: {
             200: {
               description: 'Available permissions',
               type: 'array',
               items: {
                 type: 'object',
                 properties: {
                   id: { type: 'string', format: 'uuid' },
                   slug: { type: 'string' },
                   description: { type: 'string' },
                 },
               },
             },
           },
         },
         preHandler: [server.authenticate, requirePermission('organization:read')],
       },
       async (request, reply) => {
         const permissions = await organizationService.getAvailablePermissions();
         return reply.send(permissions);
       }
     );

     // Get organization user details
     server.get(
       '/organization/users/:id',
       {
         schema: {
           tags: ['customer'],
           summary: 'Get organization user',
           description: 'Get details of a specific organization user',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'Organization user details',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 userId: { type: 'string', format: 'uuid' },
                 email: { type: 'string' },
                 name: { type: 'string' },
                 role: {
                   type: 'object',
                   properties: {
                     id: { type: 'string', format: 'uuid' },
                     slug: { type: 'string' },
                     name: { type: 'string' },
                   },
                 },
                 permissions: {
                   type: 'array',
                   items: {
                     type: 'object',
                     properties: {
                       id: { type: 'string', format: 'uuid' },
                       slug: { type: 'string' },
                       description: { type: 'string' },
                     },
                   },
                 },
                 invitedAt: { type: 'string', format: 'date-time' },
                 acceptedAt: { type: 'string', format: 'date-time' },
               },
             },
             404: {
               description: 'Organization user not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('organization:read'),
           validateParams(OrganizationUserParamsSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<typeof OrganizationUserParamsSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to access this resource',
           });
         }

         try {
           const orgUser = await organizationService.getOrganizationUser(
             id,
             customerProfileId
           );
           return reply.send(orgUser);
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'Organization User Not Found',
               detail: 'Organization user not found or access denied',
             });
           }
           throw error;
         }
       }
     );

     // Invite user to organization
     server.post(
       '/organization/users',
       {
         schema: {
           tags: ['customer'],
           summary: 'Invite user',
           description: 'Invite a new user to the organization',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['email', 'roleId'],
             properties: {
               email: { type: 'string', format: 'email' },
               roleId: { type: 'string', format: 'uuid' },
               permissions: {
                 type: 'array',
                 items: { type: 'string', format: 'uuid' },
               },
             },
           },
           response: {
             201: {
               description: 'User invited',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 email: { type: 'string' },
                 message: { type: 'string' },
               },
             },
             409: {
               description: 'User already in organization',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('organization:write'),
           validateBody(InviteUserSchema),
         ],
       },
       async (request, reply) => {
         const body = request.body as z.infer<typeof InviteUserSchema>;
         const customerProfileId = request.user.activeContext?.id;
         const userId = request.user.sub;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to invite users',
           });
         }

         // Get inviter info
         const inviter = await server.prisma.user.findUnique({
           where: { id: userId },
           select: { name: true, email: true },
         });

         // Get organization name
         const customerProfile = await server.prisma.customerProfile.findUnique({
           where: { id: customerProfileId },
           select: { legalBusinessName: true },
         });

         try {
           const result = await organizationService.inviteUser(
             {
               customerProfileId,
               email: body.email,
               roleId: body.roleId,
               permissions: body.permissions,
               invitedBy: userId,
               inviterName: inviter?.name || inviter?.email || 'A team member',
               organizationName:
                 customerProfile?.legalBusinessName || 'your organization',
             },
             communicationQueue
           );

           return reply.code(201).send({
             id: result.id,
             email: result.email,
             message: 'Invitation sent successfully',
           });
         } catch (error) {
           if (
             error instanceof Error &&
             error.message.includes('already a member')
           ) {
             return reply.code(409).send({
               type: 'conflict',
               title: 'User Already Member',
               detail: error.message,
             });
           }
           throw error;
         }
       }
     );

     // Update organization user
     server.patch(
       '/organization/users/:id',
       {
         schema: {
           tags: ['customer'],
           summary: 'Update organization user',
           description: 'Update role and permissions for an organization user',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           body: {
             type: 'object',
             properties: {
               roleId: { type: 'string', format: 'uuid' },
               permissions: {
                 type: 'array',
                 items: { type: 'string', format: 'uuid' },
               },
             },
           },
           response: {
             200: {
               description: 'Organization user updated',
               type: 'object',
               properties: {
                 id: { type: 'string', format: 'uuid' },
                 email: { type: 'string' },
                 role: {
                   type: 'object',
                   properties: {
                     id: { type: 'string', format: 'uuid' },
                     slug: { type: 'string' },
                     name: { type: 'string' },
                   },
                 },
               },
             },
             404: {
               description: 'Organization user not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('organization:write'),
           validateParams(OrganizationUserParamsSchema),
           validateBody(UpdateOrganizationUserSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<
           typeof OrganizationUserParamsSchema
         >;
         const body = request.body as z.infer<typeof UpdateOrganizationUserSchema>;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to update users',
           });
         }

         try {
           const orgUser = await organizationService.updateOrganizationUser(
             id,
             customerProfileId,
             body
           );

           return reply.send(orgUser);
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'Organization User Not Found',
               detail: 'Organization user not found or access denied',
             });
           }
           throw error;
         }
       }
     );

     // Remove user from organization
     server.delete(
       '/organization/users/:id',
       {
         schema: {
           tags: ['customer'],
           summary: 'Remove organization user',
           description: 'Remove a user from the organization',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             204: {
               description: 'Organization user removed',
             },
             404: {
               description: 'Organization user not found',
             },
             409: {
               description: 'Cannot remove organization owner',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('organization:write'),
           validateParams(OrganizationUserParamsSchema),
         ],
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<
           typeof OrganizationUserParamsSchema
         >;
         const customerProfileId = request.user.activeContext?.id;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to remove users',
           });
         }

         try {
           await organizationService.removeOrganizationUser(id, customerProfileId);
           return reply.code(204).send();
         } catch (error) {
           if (error instanceof Error) {
             if (error.message.includes('not found')) {
               return reply.code(404).send({
                 type: 'resource_not_found',
                 title: 'Organization User Not Found',
                 detail: 'Organization user not found or access denied',
               });
             }
             if (error.message.includes('Cannot remove')) {
               return reply.code(409).send({
                 type: 'conflict',
                 title: 'Cannot Remove Owner',
                 detail: error.message,
               });
             }
           }
           throw error;
         }
       }
     );

     // Resend invitation
     server.post(
       '/organization/users/:id/resend-invitation',
       {
         schema: {
           tags: ['customer'],
           summary: 'Resend invitation',
           description: 'Resend invitation email to a pending user',
           security: [{ bearerAuth: [] }],
           params: {
             type: 'object',
             properties: {
               id: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'Invitation resent',
               type: 'object',
               properties: {
                 message: { type: 'string' },
               },
             },
             404: {
               description: 'Pending invitation not found',
             },
           },
         },
         preHandler: [
           server.authenticate,
           requirePermission('organization:write'),
           validateParams(OrganizationUserParamsSchema),
         ],
         config: {
           rateLimit: {
             max: 5,
             timeWindow: '1 hour',
           },
         },
       },
       async (request, reply) => {
         const { id } = request.params as z.infer<
           typeof OrganizationUserParamsSchema
         >;
         const customerProfileId = request.user.activeContext?.id;
         const userId = request.user.sub;

         if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
           return reply.code(403).send({
             type: 'authorization_denied',
             title: 'Customer Context Required',
             detail: 'You must be in a customer context to resend invitations',
           });
         }

         // Get inviter info
         const inviter = await server.prisma.user.findUnique({
           where: { id: userId },
           select: { name: true, email: true },
         });

         // Get organization name
         const customerProfile = await server.prisma.customerProfile.findUnique({
           where: { id: customerProfileId },
           select: { legalBusinessName: true },
         });

         try {
           await organizationService.resendInvitation(
             id,
             customerProfileId,
             inviter?.name || inviter?.email || 'A team member',
             customerProfile?.legalBusinessName || 'your organization',
             communicationQueue
           );

           return reply.send({
             message: 'Invitation resent successfully',
           });
         } catch (error) {
           if (error instanceof Error && error.message.includes('not found')) {
             return reply.code(404).send({
               type: 'resource_not_found',
               title: 'Pending Invitation Not Found',
               detail: 'No pending invitation found for this user',
             });
           }
           throw error;
         }
       }
     );
   };
   ```

4. **Create invitation acceptance route in `apps/api/src/routes/auth/invitation.ts`:**
   ```typescript
   import { FastifyPluginAsync } from 'fastify';
   import { validateBody } from '@singr/shared/validation';
   import { OrganizationService } from '@singr/shared/services/organization-service';
   import { createLogger } from '@singr/observability';

   const logger = createLogger('routes:auth:invitation');

   export const invitationRoute: FastifyPluginAsync = async (server) => {
     const organizationService = new OrganizationService(
       server.prisma,
       server.redis
     );

     // Accept invitation
     server.post(
       '/invitation/accept',
       {
         schema: {
           tags: ['auth'],
           summary: 'Accept invitation',
           description: 'Accept organization invitation and join team',
           security: [{ bearerAuth: [] }],
           body: {
             type: 'object',
             required: ['token'],
             properties: {
               token: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'Invitation accepted',
               type: 'object',
               properties: {
                 customerProfileId: { type: 'string', format: 'uuid' },
                 message: { type: 'string' },
               },
             },
             400: {
               description: 'Invalid or expired invitation',
             },
           },
         },
         preHandler: [
           server.authenticate,
           validateBody(z.object({ token: z.string().uuid() })),
         ],
       },
       async (request, reply) => {
         const { token } = request.body as { token: string };
         const userId = request.user.sub;

         try {
           const customerProfileId = await organizationService.acceptInvitation(
             token,
             userId
           );

           return reply.send({
             customerProfileId,
             message: 'Invitation accepted successfully',
           });
         } catch (error) {
           if (error instanceof Error) {
             if (
               error.message.includes('Invalid') ||
               error.message.includes('expired')
             ) {
               return reply.code(400).send({
                 type: 'invalid_token',
                 title: 'Invalid Invitation',
                 detail: error.message,
               });
             }
           }
           throw error;
         }
       }
     );

     // Get invitation details (public endpoint)
     server.get(
       '/invitation/:token',
       {
         schema: {
           tags: ['auth'],
           summary: 'Get invitation details',
           description: 'Get details about an invitation before accepting',
           params: {
             type: 'object',
             properties: {
               token: { type: 'string', format: 'uuid' },
             },
           },
           response: {
             200: {
               description: 'Invitation details',
               type: 'object',
               properties: {
                 organizationName: { type: 'string' },
                 inviterName: { type: 'string' },
                 email: { type: 'string' },
                 expiresAt: { type: 'string', format: 'date-time' },
               },
             },
             404: {
               description: 'Invitation not found or expired',
             },
           },
         },
       },
       async (request, reply) => {
         const { token } = request.params as { token: string };

         // Find token
         const verificationToken = await server.prisma.verificationToken.findFirst({
           where: {
             token,
             expiresAt: { gt: new Date() },
           },
         });

         if (!verificationToken) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Invitation Not Found',
             detail: 'Invitation not found or has expired',
           });
         }

         // Get user and organization info
         const user = await server.prisma.user.findUnique({
           where: { email: verificationToken.identifier },
           include: {
             organizationUsers: {
               where: {
                 acceptedAt: null,
               },
               include: {
                 customerProfile: {
                   select: {
                     legalBusinessName: true,
                   },
                 },
               },
             },
           },
         });

         if (!user || user.organizationUsers.length === 0) {
           return reply.code(404).send({
             type: 'resource_not_found',
             title: 'Invitation Not Found',
             detail: 'Invitation not found',
           });
         }

         const orgUser = user.organizationUsers[0];

         return reply.send({
           organizationName:
             orgUser.customerProfile.legalBusinessName || 'this organization',
           inviterName: 'A team member',
           email: user.email,
           expiresAt: verificationToken.expiresAt.toISOString(),
         });
       }
     );
   };
   ```

5. **Register routes:**
   ```typescript
   // Update apps/api/src/routes/customer/index.ts
   import { FastifyPluginAsync } from 'fastify';
   import { venuesRoute } from './venues';
   import { systemsRoute } from './systems';
   import { songdbRoute } from './songdb';
   import { requestsRoute } from './requests';
   import { websocketRoute } from './websocket';
   import { apiKeysRoute } from './api-keys';
   import { organizationRoute } from './organization';

   export const customerRoutes: FastifyPluginAsync = async (server) => {
     await server.register(venuesRoute);
     await server.register(systemsRoute);
     await server.register(songdbRoute);
     await server.register(requestsRoute);
     await server.register(websocketRoute);
     await server.register(apiKeysRoute);
     await server.register(organizationRoute);
   };
   ```

   ```typescript
   // Update apps/api/src/routes/auth/index.ts
   import { FastifyPluginAsync } from 'fastify';
   import { signinRoute } from './signin';
   import { registerRoute } from './register';
   import { refreshRoute } from './refresh';
   import { signoutRoute } from './signout';
   import { passwordRoute } from './password';
   import { profileRoute } from './profile';
   import { contextRoute } from './context';
   import { twoFactorRoute } from './two-factor';
   import { twoFactorChallengeRoute } from './two-factor-challenge';
   import { magicLinkRoute } from './magic-link';
   import { invitationRoute } from './invitation';

   export const authRoutes: FastifyPluginAsync = async (server) => {
     await server.register(signinRoute);
     await server.register(registerRoute);
     await server.register(refreshRoute);
     await server.register(signoutRoute);
     await server.register(passwordRoute);
     await server.register(profileRoute);
     await server.register(contextRoute);
     await server.register(twoFactorRoute);
     await server.register(twoFactorChallengeRoute);
     await server.register(magicLinkRoute);
     await server.register(invitationRoute);
   };
   ```

**Deliverables:**
- ✅ `GET /v1/customer/organization/users` - List organization members
- ✅ `GET /v1/customer/organization/roles` - Get available roles
- ✅ `GET /v1/customer/organization/permissions` - Get available permissions
- ✅ `GET /v1/customer/organization/users/:id` - Get member details
- ✅ `POST /v1/customer/organization/users` - Invite new member
- ✅ `PATCH /v1/customer/organization/users/:id` - Update member role/permissions
- ✅ `DELETE /v1/customer/organization/users/:id` - Remove member
- ✅ `POST /v1/customer/organization/users/:id/resend-invitation` - Resend invitation
- ✅ `POST /v1/auth/invitation/accept` - Accept invitation
- ✅ `GET /v1/auth/invitation/:token` - View invitation details
- ✅ Email invitation via Mailjet
- ✅ 7-day invitation expiry
- ✅ Custom permission overrides
- ✅ Role-based access (owner, manager, staff)
- ✅ Owner protection (cannot be removed)
- ✅ Placeholder user creation
- ✅ RBAC permission checks (organization:read, organization:write)
- ✅ Rate limiting on resend invitation
- ✅ Pending vs accepted status tracking

---

# Singr Karaoke Connect - Centralized API Development Plan
## Part 3: Advanced Features & Production Readiness (Phases 12-17)

> **Document Status**: Part 3 of 3  
> **Continuation From**: Phase 11 (Customer API Keys Management)  
> **Date**: 2025-01-11  
> **Architecture**: Fastify + PostgreSQL + Redis + BullMQ

---

## Table of Contents - Part 3

- [Phase 12: Organization Users & Team Management](#phase-12-organization-users--team-management)
- [Phase 13: Subscription & Billing Integration](#phase-13-subscription--billing-integration)
- [Phase 14: Request Interface API](#phase-14-request-interface-api)
- [Phase 15: Admin & Support Portal Backend](#phase-15-admin--support-portal-backend)
- [Phase 16: Analytics & Reporting](#phase-16-analytics--reporting)
- [Phase 17: Testing, Documentation & Deployment](#phase-17-testing-documentation--deployment)

---

## Phase 12: Organization Users & Team Management

**Objective**: Enable customer organizations to add multiple users with role-based access to manage their venues, systems, and requests collaboratively.

### 12.1 Database Schema Extensions

```sql
-- Migration: 012_organization_users.sql

-- Organization user roles
CREATE TYPE organization_role AS ENUM (
  'owner',      -- Full access, billing, user management
  'admin',      -- Full operational access, no billing
  'manager',    -- Venue/system management, no user management
  'operator'    -- View requests, mark as processed only
);

-- Organization users table
CREATE TABLE organization_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_profile_id UUID NOT NULL REFERENCES customer_profiles(id) ON DELETE CASCADE,
  email VARCHAR(255) NOT NULL,
  role organization_role NOT NULL DEFAULT 'operator',
  invited_by_user_id UUID REFERENCES singr_users(id) ON DELETE SET NULL,
  invitation_token VARCHAR(255),
  invitation_sent_at TIMESTAMPTZ,
  invitation_accepted_at TIMESTAMPTZ,
  singr_user_id UUID UNIQUE REFERENCES singr_users(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT organization_users_email_customer_unique 
    UNIQUE (customer_profile_id, email)
);

CREATE INDEX idx_org_users_customer_profile 
  ON organization_users(customer_profile_id);
CREATE INDEX idx_org_users_singr_user 
  ON organization_users(singr_user_id);
CREATE INDEX idx_org_users_invitation_token 
  ON organization_users(invitation_token) 
  WHERE invitation_token IS NOT NULL;

-- Permissions mapping table
CREATE TABLE organization_user_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_user_id UUID NOT NULL REFERENCES organization_users(id) ON DELETE CASCADE,
  permission_key VARCHAR(100) NOT NULL,
  granted_at TIMESTAMPTZ DEFAULT NOW(),
  granted_by_user_id UUID REFERENCES singr_users(id) ON DELETE SET NULL,
  
  CONSTRAINT org_user_permissions_unique 
    UNIQUE (organization_user_id, permission_key)
);

CREATE INDEX idx_org_user_permissions_user 
  ON organization_user_permissions(organization_user_id);

-- Audit log for organization changes
CREATE TABLE organization_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_profile_id UUID NOT NULL REFERENCES customer_profiles(id) ON DELETE CASCADE,
  actor_user_id UUID REFERENCES singr_users(id) ON DELETE SET NULL,
  action VARCHAR(100) NOT NULL, -- 'user.invited', 'user.removed', 'role.changed', etc.
  target_user_id UUID REFERENCES singr_users(id) ON DELETE SET NULL,
  target_email VARCHAR(255),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_org_audit_customer 
  ON organization_audit_log(customer_profile_id, created_at DESC);
CREATE INDEX idx_org_audit_actor 
  ON organization_audit_log(actor_user_id);

-- Add trigger for updated_at
CREATE TRIGGER update_organization_users_updated_at
  BEFORE UPDATE ON organization_users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE organization_users IS 
  'Team members who can access a customer organization with specific roles';
COMMENT ON TABLE organization_user_permissions IS 
  'Granular permissions for organization users beyond their role';
COMMENT ON TABLE organization_audit_log IS 
  'Audit trail of organization membership and permission changes';
```

### 12.2 Permission System

```typescript
// src/lib/permissions/organization-permissions.ts

import { PrismaClient } from '@prisma/client';
import { logger } from '../logger';

export const ORGANIZATION_PERMISSIONS = {
  // User management
  'org:users:invite': 'Invite new users to organization',
  'org:users:remove': 'Remove users from organization',
  'org:users:update-role': 'Change user roles',
  
  // Venue management
  'venues:create': 'Create new venues',
  'venues:update': 'Update venue details',
  'venues:delete': 'Delete venues',
  'venues:view': 'View venue details',
  
  // System management
  'systems:create': 'Create new systems',
  'systems:update': 'Update systems',
  'systems:delete': 'Delete systems',
  'systems:view': 'View systems',
  
  // Request management
  'requests:view': 'View song requests',
  'requests:process': 'Mark requests as processed',
  'requests:delete': 'Delete requests',
  
  // API key management
  'api-keys:create': 'Generate API keys',
  'api-keys:revoke': 'Revoke API keys',
  'api-keys:view': 'View API keys',
  
  // Billing (owner only)
  'billing:view': 'View subscription and invoices',
  'billing:manage': 'Manage subscription and payment methods',
} as const;

export type OrganizationPermissionKey = keyof typeof ORGANIZATION_PERMISSIONS;

// Role-based permission mapping
export const ROLE_PERMISSIONS: Record<string, OrganizationPermissionKey[]> = {
  owner: Object.keys(ORGANIZATION_PERMISSIONS) as OrganizationPermissionKey[],
  
  admin: [
    'org:users:invite',
    'venues:create', 'venues:update', 'venues:delete', 'venues:view',
    'systems:create', 'systems:update', 'systems:delete', 'systems:view',
    'requests:view', 'requests:process', 'requests:delete',
    'api-keys:create', 'api-keys:revoke', 'api-keys:view',
  ],
  
  manager: [
    'venues:update', 'venues:view',
    'systems:update', 'systems:view',
    'requests:view', 'requests:process', 'requests:delete',
    'api-keys:view',
  ],
  
  operator: [
    'venues:view',
    'systems:view',
    'requests:view',
    'requests:process',
  ],
};

export class OrganizationPermissionService {
  constructor(private prisma: PrismaClient) {}

  async getUserPermissions(
    customerProfileId: string,
    singrUserId: string
  ): Promise<Set<OrganizationPermissionKey>> {
    // Check if user is the customer profile owner
    const customerProfile = await this.prisma.customerProfile.findUnique({
      where: { id: customerProfileId },
      select: { singrUserId: true },
    });

    if (customerProfile?.singrUserId === singrUserId) {
      // Owner has all permissions
      return new Set(Object.keys(ORGANIZATION_PERMISSIONS) as OrganizationPermissionKey[]);
    }

    // Check organization user
    const orgUser = await this.prisma.organizationUser.findFirst({
      where: {
        customerProfileId,
        singrUserId,
        isActive: true,
        invitationAcceptedAt: { not: null },
      },
      include: {
        permissions: {
          select: { permissionKey: true },
        },
      },
    });

    if (!orgUser) {
      return new Set();
    }

    // Get role-based permissions
    const rolePermissions = new Set(ROLE_PERMISSIONS[orgUser.role] || []);

    // Add custom permissions
    orgUser.permissions.forEach((p) => {
      if (p.permissionKey in ORGANIZATION_PERMISSIONS) {
        rolePermissions.add(p.permissionKey as OrganizationPermissionKey);
      }
    });

    return rolePermissions;
  }

  async hasPermission(
    customerProfileId: string,
    singrUserId: string,
    permission: OrganizationPermissionKey
  ): Promise<boolean> {
    const permissions = await this.getUserPermissions(customerProfileId, singrUserId);
    return permissions.has(permission);
  }

  async requirePermission(
    customerProfileId: string,
    singrUserId: string,
    permission: OrganizationPermissionKey
  ): Promise<void> {
    const hasPermission = await this.hasPermission(
      customerProfileId,
      singrUserId,
      permission
    );

    if (!hasPermission) {
      throw new Error(`Permission denied: ${permission}`);
    }
  }
}
```

### 12.3 Organization User Service

```typescript
// src/services/organization-user-service.ts

import { PrismaClient } from '@prisma/client';
import { randomBytes } from 'crypto';
import { logger } from '../lib/logger';
import type { FastifyInstance } from 'fastify';

export interface InviteUserInput {
  email: string;
  role: 'admin' | 'manager' | 'operator';
  customPermissions?: string[];
}

export interface UpdateUserInput {
  role?: 'admin' | 'manager' | 'operator';
  isActive?: boolean;
  customPermissions?: string[];
}

export class OrganizationUserService {
  constructor(
    private prisma: PrismaClient,
    private server: FastifyInstance
  ) {}

  /**
   * Invite a new user to the organization
   */
  async inviteUser(
    customerProfileId: string,
    invitedByUserId: string,
    input: InviteUserInput
  ) {
    const { email, role, customPermissions = [] } = input;

    // Check if user already exists
    const existing = await this.prisma.organizationUser.findUnique({
      where: {
        organizationUsers_customerProfileId_email_key: {
          customerProfileId,
          email: email.toLowerCase(),
        },
      },
    });

    if (existing) {
      if (existing.invitationAcceptedAt) {
        throw new Error('User is already a member of this organization');
      }
      // Resend invitation
      return this.resendInvitation(existing.id, invitedByUserId);
    }

    const invitationToken = randomBytes(32).toString('hex');

    const orgUser = await this.prisma.organizationUser.create({
      data: {
        customerProfileId,
        email: email.toLowerCase(),
        role,
        invitedByUserId,
        invitationToken,
        invitationSentAt: new Date(),
      },
    });

    // Add custom permissions
    if (customPermissions.length > 0) {
      await this.prisma.organizationUserPermission.createMany({
        data: customPermissions.map((permissionKey) => ({
          organizationUserId: orgUser.id,
          permissionKey,
          grantedByUserId: invitedByUserId,
        })),
        skipDuplicates: true,
      });
    }

    // Log audit entry
    await this.prisma.organizationAuditLog.create({
      data: {
        customerProfileId,
        actorUserId: invitedByUserId,
        action: 'user.invited',
        targetEmail: email,
        metadata: { role, customPermissions },
      },
    });

    // Enqueue invitation email
    await this.server.queue.add('email', {
      type: 'organization_invitation',
      to: email,
      data: {
        invitationToken,
        role,
        inviterEmail: invitedByUserId, // Should fetch inviter details
      },
    });

    logger.info('Organization user invited', {
      customerProfileId,
      email,
      role,
      orgUserId: orgUser.id,
    });

    return {
      id: orgUser.id,
      email: orgUser.email,
      role: orgUser.role,
      invitationSentAt: orgUser.invitationSentAt,
    };
  }

  /**
   * Accept an organization invitation
   */
  async acceptInvitation(invitationToken: string, singrUserId: string) {
    const orgUser = await this.prisma.organizationUser.findFirst({
      where: {
        invitationToken,
        invitationAcceptedAt: null,
      },
    });

    if (!orgUser) {
      throw new Error('Invalid or expired invitation');
    }

    // Check if token is expired (7 days)
    const expirationDate = new Date(orgUser.invitationSentAt);
    expirationDate.setDate(expirationDate.getDate() + 7);

    if (new Date() > expirationDate) {
      throw new Error('Invitation has expired');
    }

    // Verify email matches the user's account
    const singrUser = await this.prisma.singrUser.findUnique({
      where: { id: singrUserId },
      select: { email: true },
    });

    if (singrUser?.email.toLowerCase() !== orgUser.email.toLowerCase()) {
      throw new Error('Email mismatch: This invitation was sent to a different email address');
    }

    // Accept invitation
    const updated = await this.prisma.organizationUser.update({
      where: { id: orgUser.id },
      data: {
        singrUserId,
        invitationAcceptedAt: new Date(),
        invitationToken: null,
        isActive: true,
      },
    });

    // Log audit entry
    await this.prisma.organizationAuditLog.create({
      data: {
        customerProfileId: orgUser.customerProfileId,
        actorUserId: singrUserId,
        action: 'user.accepted_invitation',
        targetUserId: singrUserId,
        targetEmail: orgUser.email,
      },
    });

    logger.info('Organization invitation accepted', {
      orgUserId: orgUser.id,
      customerProfileId: orgUser.customerProfileId,
      singrUserId,
    });

    return updated;
  }

  /**
   * Resend an invitation
   */
  async resendInvitation(orgUserId: string, resendByUserId: string) {
    const orgUser = await this.prisma.organizationUser.findUnique({
      where: { id: orgUserId },
    });

    if (!orgUser) {
      throw new Error('Organization user not found');
    }

    if (orgUser.invitationAcceptedAt) {
      throw new Error('User has already accepted the invitation');
    }

    const newToken = randomBytes(32).toString('hex');

    const updated = await this.prisma.organizationUser.update({
      where: { id: orgUserId },
      data: {
        invitationToken: newToken,
        invitationSentAt: new Date(),
      },
    });

    // Enqueue invitation email
    await this.server.queue.add('email', {
      type: 'organization_invitation',
      to: orgUser.email,
      data: {
        invitationToken: newToken,
        role: orgUser.role,
      },
    });

    logger.info('Organization invitation resent', {
      orgUserId,
      customerProfileId: orgUser.customerProfileId,
    });

    return updated;
  }

  /**
   * Update organization user role and permissions
   */
  async updateUser(
    orgUserId: string,
    updatedByUserId: string,
    input: UpdateUserInput
  ) {
    const orgUser = await this.prisma.organizationUser.findUnique({
      where: { id: orgUserId },
      include: { permissions: true },
    });

    if (!orgUser) {
      throw new Error('Organization user not found');
    }

    const updateData: any = { updatedAt: new Date() };

    if (input.role !== undefined) {
      updateData.role = input.role;
    }

    if (input.isActive !== undefined) {
      updateData.isActive = input.isActive;
    }

    const updated = await this.prisma.organizationUser.update({
      where: { id: orgUserId },
      data: updateData,
    });

    // Update custom permissions if provided
    if (input.customPermissions !== undefined) {
      // Remove existing custom permissions
      await this.prisma.organizationUserPermission.deleteMany({
        where: { organizationUserId: orgUserId },
      });

      // Add new permissions
      if (input.customPermissions.length > 0) {
        await this.prisma.organizationUserPermission.createMany({
          data: input.customPermissions.map((permissionKey) => ({
            organizationUserId: orgUserId,
            permissionKey,
            grantedByUserId: updatedByUserId,
          })),
        });
      }
    }

    // Log audit entry
    await this.prisma.organizationAuditLog.create({
      data: {
        customerProfileId: orgUser.customerProfileId,
        actorUserId: updatedByUserId,
        action: 'user.updated',
        targetUserId: orgUser.singrUserId,
        targetEmail: orgUser.email,
        metadata: input,
      },
    });

    logger.info('Organization user updated', {
      orgUserId,
      customerProfileId: orgUser.customerProfileId,
      changes: input,
    });

    return updated;
  }

  /**
   * Remove user from organization
   */
  async removeUser(orgUserId: string, removedByUserId: string) {
    const orgUser = await this.prisma.organizationUser.findUnique({
      where: { id: orgUserId },
    });

    if (!orgUser) {
      throw new Error('Organization user not found');
    }

    // Log audit entry before deletion
    await this.prisma.organizationAuditLog.create({
      data: {
        customerProfileId: orgUser.customerProfileId,
        actorUserId: removedByUserId,
        action: 'user.removed',
        targetUserId: orgUser.singrUserId,
        targetEmail: orgUser.email,
        metadata: { role: orgUser.role },
      },
    });

    await this.prisma.organizationUser.delete({
      where: { id: orgUserId },
    });

    logger.info('Organization user removed', {
      orgUserId,
      customerProfileId: orgUser.customerProfileId,
      email: orgUser.email,
    });
  }

  /**
   * List organization users
   */
  async listUsers(customerProfileId: string) {
    const users = await this.prisma.organizationUser.findMany({
      where: { customerProfileId },
      include: {
        singrUser: {
          select: {
            id: true,
            name: true,
            email: true,
            image: true,
          },
        },
        permissions: {
          select: { permissionKey: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return users.map((user) => ({
      id: user.id,
      email: user.email,
      role: user.role,
      isActive: user.isActive,
      user: user.singrUser,
      customPermissions: user.permissions.map((p) => p.permissionKey),
      invitationSentAt: user.invitationSentAt,
      invitationAcceptedAt: user.invitationAcceptedAt,
      createdAt: user.createdAt,
    }));
  }

  /**
   * Get audit log for organization
   */
  async getAuditLog(
    customerProfileId: string,
    options: {
      limit?: number;
      offset?: number;
      action?: string;
    } = {}
  ) {
    const { limit = 50, offset = 0, action } = options;

    const where: any = { customerProfileId };
    if (action) {
      where.action = action;
    }

    const [logs, total] = await Promise.all([
      this.prisma.organizationAuditLog.findMany({
        where,
        include: {
          actorUser: {
            select: { id: true, name: true, email: true },
          },
          targetUser: {
            select: { id: true, name: true, email: true },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.organizationAuditLog.count({ where }),
    ]);

    return {
      logs,
      pagination: {
        total,
        limit,
        offset,
        hasMore: offset + limit < total,
      },
    };
  }
}
```

### 12.4 Organization User Routes

```typescript
// src/routes/v1/customer/organization/users.ts

import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { OrganizationUserService } from '../../../../services/organization-user-service';
import { OrganizationPermissionService } from '../../../../lib/permissions/organization-permissions';

const InviteUserSchema = z.object({
  email: z.string().email(),
  role: z.enum(['admin', 'manager', 'operator']),
  customPermissions: z.array(z.string()).optional(),
});

const UpdateUserSchema = z.object({
  role: z.enum(['admin', 'manager', 'operator']).optional(),
  isActive: z.boolean().optional(),
  customPermissions: z.array(z.string()).optional(),
});

const AcceptInvitationSchema = z.object({
  invitationToken: z.string().min(1),
});

const organizationUsersRoutes: FastifyPluginAsync = async (server) => {
  const orgUserService = new OrganizationUserService(server.prisma, server);
  const permissionService = new OrganizationPermissionService(server.prisma);

  // List organization users
  server.get(
    '/organization/users',
    {
      schema: {
        tags: ['customer'],
        summary: 'List organization users',
        security: [{ bearerAuth: [] }],
        response: {
          200: {
            description: 'List of organization users',
            type: 'object',
            properties: {
              users: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    id: { type: 'string' },
                    email: { type: 'string' },
                    role: { type: 'string' },
                    isActive: { type: 'boolean' },
                    customPermissions: { type: 'array', items: { type: 'string' } },
                    invitationSentAt: { type: 'string', format: 'date-time', nullable: true },
                    invitationAcceptedAt: { type: 'string', format: 'date-time', nullable: true },
                    createdAt: { type: 'string', format: 'date-time' },
                  },
                },
              },
            },
          },
        },
      },
      preHandler: [server.authenticate],
    },
    async (request, reply) => {
      const customerProfileId = request.user.activeContext?.id;

      if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
        return reply.code(403).send({
          type: 'authorization_denied',
          title: 'Customer Context Required',
          detail: 'You must be in a customer context',
        });
      }

      const users = await orgUserService.listUsers(customerProfileId);

      return reply.send({ users });
    }
  );

  // Invite user to organization
  server.post(
    '/organization/users',
    {
      schema: {
        tags: ['customer'],
        summary: 'Invite user to organization',
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['email', 'role'],
          properties: {
            email: { type: 'string', format: 'email' },
            role: { type: 'string', enum: ['admin', 'manager', 'operator'] },
            customPermissions: { type: 'array', items: { type: 'string' } },
          },
        },
        response: {
          201: {
            description: 'User invited',
            type: 'object',
            properties: {
              id: { type: 'string' },
              email: { type: 'string' },
              role: { type: 'string' },
              invitationSentAt: { type: 'string', format: 'date-time' },
            },
          },
        },
      },
      preHandler: [server.authenticate],
    },
    async (request, reply) => {
      const customerProfileId = request.user.activeContext?.id;

      if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
        return reply.code(403).send({
          type: 'authorization_denied',
          title: 'Customer Context Required',
          detail: 'You must be in a customer context',
        });
      }

      // Check permission
      await permissionService.requirePermission(
        customerProfileId,
        request.user.id,
        'org:users:invite'
      );

      try {
        const data = InviteUserSchema.parse(request.body);
        const result = await orgUserService.inviteUser(
          customerProfileId,
          request.user.id,
          data
        );

        return reply.code(201).send(result);
      } catch (error) {
        if (error instanceof Error) {
          return reply.code(400).send({
            type: 'invalid_request',
            title: 'Invitation Failed',
            detail: error.message,
          });
        }
        throw error;
      }
    }
  );

  // Accept organization invitation
  server.post(
    '/organization/accept-invitation',
    {
      schema: {
        tags: ['customer'],
        summary: 'Accept organization invitation',
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['invitationToken'],
          properties: {
            invitationToken: { type: 'string' },
          },
        },
        response: {
          200: {
            description: 'Invitation accepted',
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              customerProfileId: { type: 'string' },
            },
          },
        },
      },
      preHandler: [server.authenticate],
    },
    async (request, reply) => {
      try {
        const { invitationToken } = AcceptInvitationSchema.parse(request.body);
        
        const orgUser = await orgUserService.acceptInvitation(
          invitationToken,
          request.user.id
        );

        return reply.send({
          success: true,
          customerProfileId: orgUser.customerProfileId,
        });
      } catch (error) {
        if (error instanceof Error) {
          return reply.code(400).send({
            type: 'invalid_request',
            title: 'Invitation Failed',
            detail: error.message,
          });
        }
        throw error;
      }
    }
  );

  // Update organization user
  server.patch(
    '/organization/users/:userId',
    {
      schema: {
        tags: ['customer'],
        summary: 'Update organization user',
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          properties: {
            userId: { type: 'string', format: 'uuid' },
          },
        },
        body: {
          type: 'object',
          properties: {
            role: { type: 'string', enum: ['admin', 'manager', 'operator'] },
            isActive: { type: 'boolean' },
            customPermissions: { type: 'array', items: { type: 'string' } },
          },
        },
      },
      preHandler: [server.authenticate],
    },
    async (request, reply) => {
      const { userId } = request.params as { userId: string };
      const customerProfileId = request.user.activeContext?.id;

      if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
        return reply.code(403).send({
          type: 'authorization_denied',
          title: 'Customer Context Required',
        });
      }

      // Check permission
      await permissionService.requirePermission(
        customerProfileId,
        request.user.id,
        'org:users:update-role'
      );

      try {
        const data = UpdateUserSchema.parse(request.body);
        const result = await orgUserService.updateUser(userId, request.user.id, data);

        return reply.send(result);
      } catch (error) {
        if (error instanceof Error) {
          return reply.code(400).send({
            type: 'invalid_request',
            title: 'Update Failed',
            detail: error.message,
          });
        }
        throw error;
      }
    }
  );

  // Remove organization user
  server.delete(
    '/organization/users/:userId',
    {
      schema: {
        tags: ['customer'],
        summary: 'Remove user from organization',
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          properties: {
            userId: { type: 'string', format: 'uuid' },
          },
        },
        response: {
          204: { description: 'User removed' },
        },
      },
      preHandler: [server.authenticate],
    },
    async (request, reply) => {
      const { userId } = request.params as { userId: string };
      const customerProfileId = request.user.activeContext?.id;

      if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
        return reply.code(403).send({
          type: 'authorization_denied',
          title: 'Customer Context Required',
        });
      }

      // Check permission
      await permissionService.requirePermission(
        customerProfileId,
        request.user.id,
        'org:users:remove'
      );

      try {
        await orgUserService.removeUser(userId, request.user.id);
        return reply.code(204).send();
      } catch (error) {
        if (error instanceof Error) {
          return reply.code(400).send({
            type: 'invalid_request',
            title: 'Remove Failed',
            detail: error.message,
          });
        }
        throw error;
      }
    }
  );

  // Get organization audit log
  server.get(
    '/organization/audit-log',
    {
      schema: {
        tags: ['customer'],
        summary: 'Get organization audit log',
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          properties: {
            limit: { type: 'integer', minimum: 1, maximum: 100, default: 50 },
            offset: { type: 'integer', minimum: 0, default: 0 },
            action: { type: 'string' },
          },
        },
      },
      preHandler: [server.authenticate],
    },
    async (request, reply) => {
      const customerProfileId = request.user.activeContext?.id;

      if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
        return reply.code(403).send({
          type: 'authorization_denied',
          title: 'Customer Context Required',
        });
      }

      const { limit, offset, action } = request.query as {
        limit?: number;
        offset?: number;
        action?: string;
      };

      const result = await orgUserService.getAuditLog(customerProfileId, {
        limit,
        offset,
        action,
      });

      return reply.send(result);
    }
  );
};

export default organizationUsersRoutes;
```

---

## Phase 13: Subscription & Billing Integration

**Objective**: Integrate Stripe for subscription management, payment processing, and customer portal access, following the patterns from the reference repository.

### 13.1 Stripe Service

```typescript
// src/services/stripe-service.ts

import Stripe from 'stripe';
import { PrismaClient } from '@prisma/client';
import { logger } from '../lib/logger';
import type { FastifyInstance } from 'fastify';

export class StripeService {
  private stripe: Stripe;

  constructor(
    private prisma: PrismaClient,
    private server: FastifyInstance
  ) {
    if (!process.env.STRIPE_SECRET_KEY) {
      throw new Error('STRIPE_SECRET_KEY is required');
    }

    this.stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
      apiVersion: '2024-11-20.acacia',
      typescript: true,
    });
  }

  /**
   * Get or create Stripe customer for customer profile
   */
  async getOrCreateStripeCustomer(customerProfileId: string) {
    const customerProfile = await this.prisma.customerProfile.findUnique({
      where: { id: customerProfileId },
      include: {
        singrUser: true,
        customers: {
          take: 1,
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!customerProfile) {
      throw new Error('Customer profile not found');
    }

    // Check if customer already exists
    if (customerProfile.stripeCustomerId) {
      try {
        const customer = await this.stripe.customers.retrieve(
          customerProfile.stripeCustomerId
        );
        if (!customer.deleted) {
          return customer;
        }
      } catch (error) {
        logger.warn('Stripe customer not found, creating new one', {
          stripeCustomerId: customerProfile.stripeCustomerId,
        });
      }
    }

    // Create new Stripe customer
    const customer = await this.stripe.customers.create({
      email: customerProfile.singrUser.email,
      name: customerProfile.businessName || customerProfile.singrUser.name,
      phone: customerProfile.singrUser.phoneNumber,
      metadata: {
        customerProfileId,
        singrUserId: customerProfile.singrUserId,
      },
    });

    // Update customer profile with Stripe customer ID
    await this.prisma.customerProfile.update({
      where: { id: customerProfileId },
      data: { stripeCustomerId: customer.id },
    });

    // Create or update customer record
    await this.prisma.customer.upsert({
      where: { stripeCustomerId: customer.id },
      create: {
        id: customerProfileId,
        stripeCustomerId: customer.id,
        customerProfileId,
        email: customer.email,
        name: customer.name,
        phone: customer.phone,
        description: customer.description,
        metadata: customer.metadata as any,
        invoiceSettings: customer.invoice_settings as any,
        shipping: customer.shipping as any,
        taxExempt: customer.tax_exempt,
        taxIds: [] as any,
        livemode: customer.livemode,
      },
      update: {
        email: customer.email,
        name: customer.name,
        phone: customer.phone,
      },
    });

    logger.info('Stripe customer created', {
      customerProfileId,
      stripeCustomerId: customer.id,
    });

    return customer;
  }

  /**
   * Create checkout session for subscription
   */
  async createCheckoutSession(
    customerProfileId: string,
    priceId: string,
    options: {
      successUrl: string;
      cancelUrl: string;
      trialDays?: number;
    }
  ) {
    const customer = await this.getOrCreateStripeCustomer(customerProfileId);

    const sessionParams: Stripe.Checkout.SessionCreateParams = {
      customer: customer.id,
      mode: 'subscription',
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      success_url: options.successUrl,
      cancel_url: options.cancelUrl,
      allow_promotion_codes: true,
      billing_address_collection: 'auto',
      metadata: {
        customerProfileId,
      },
    };

    if (options.trialDays && options.trialDays > 0) {
      sessionParams.subscription_data = {
        trial_period_days: options.trialDays,
        metadata: {
          customerProfileId,
        },
      };
    }

    const session = await this.stripe.checkout.sessions.create(sessionParams);

    // Store checkout session
    await this.prisma.stripeCheckoutSession.create({
      data: {
        id: session.id,
        customerId: customerProfileId,
        paymentStatus: session.payment_status,
        mode: session.mode || 'subscription',
        amountTotal: session.amount_total ? BigInt(session.amount_total) : null,
        currency: session.currency || 'usd',
        createdAt: new Date(session.created * 1000),
        expiresAt: session.expires_at ? new Date(session.expires_at * 1000) : null,
        url: session.url,
        metadata: session.metadata as any,
      },
    });

    logger.info('Checkout session created', {
      customerProfileId,
      sessionId: session.id,
      priceId,
    });

    return session;
  }

  /**
   * Create customer portal session
   */
  async createPortalSession(customerProfileId: string, returnUrl: string) {
    const customer = await this.getOrCreateStripeCustomer(customerProfileId);

    const session = await this.stripe.billingPortal.sessions.create({
      customer: customer.id,
      return_url: returnUrl,
    });

    logger.info('Customer portal session created', {
      customerProfileId,
      stripeCustomerId: customer.id,
    });

    return session;
  }

  /**
   * Get active subscription for customer
   */
  async getActiveSubscription(customerProfileId: string) {
    const subscription = await this.prisma.subscription.findFirst({
      where: {
        customerProfileId,
        status: {
          in: ['active', 'trialing'],
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return subscription;
  }

  /**
   * Check if customer has active subscription
   */
  async hasActiveSubscription(customerProfileId: string): Promise<boolean> {
    const subscription = await this.getActiveSubscription(customerProfileId);
    return !!subscription;
  }

  /**
   * Sync subscription from Stripe
   */
  async syncSubscription(stripeSubscriptionId: string) {
    const stripeSubscription = await this.stripe.subscriptions.retrieve(
      stripeSubscriptionId,
      {
        expand: ['customer'],
      }
    );

    const customer = stripeSubscription.customer;
    if (typeof customer === 'string') {
      throw new Error('Customer not expanded');
    }

    const customerProfileId = customer.metadata?.customerProfileId;
    if (!customerProfileId) {
      throw new Error('Customer profile ID not found in metadata');
    }

    // Upsert subscription
    await this.prisma.subscription.upsert({
      where: { id: stripeSubscription.id },
      create: {
        id: stripeSubscription.id,
        customerProfileId,
        status: stripeSubscription.status,
        currentPeriodStart: new Date(stripeSubscription.current_period_start * 1000),
        currentPeriodEnd: new Date(stripeSubscription.current_period_end * 1000),
        cancelAtPeriodEnd: stripeSubscription.cancel_at_period_end,
        cancelAt: stripeSubscription.cancel_at
          ? new Date(stripeSubscription.cancel_at * 1000)
          : null,
        canceledAt: stripeSubscription.canceled_at
          ? new Date(stripeSubscription.canceled_at * 1000)
          : null,
        metadata: stripeSubscription.metadata as any,
        createdAt: new Date(stripeSubscription.created * 1000),
        livemode: stripeSubscription.livemode,
      },
      update: {
        status: stripeSubscription.status,
        currentPeriodStart: new Date(stripeSubscription.current_period_start * 1000),
        currentPeriodEnd: new Date(stripeSubscription.current_period_end * 1000),
        cancelAtPeriodEnd: stripeSubscription.cancel_at_period_end,
        cancelAt: stripeSubscription.cancel_at
          ? new Date(stripeSubscription.cancel_at * 1000)
          : null,
        canceledAt: stripeSubscription.canceled_at
          ? new Date(stripeSubscription.canceled_at * 1000)
          : null,
        metadata: stripeSubscription.metadata as any,
      },
    });

    logger.info('Subscription synced', {
      subscriptionId: stripeSubscription.id,
      customerProfileId,
      status: stripeSubscription.status,
    });

    return stripeSubscription;
  }

  /**
   * Cancel subscription
   */
  async cancelSubscription(
    customerProfileId: string,
    subscriptionId: string,
    cancelAtPeriodEnd: boolean = true
  ) {
    // Verify subscription belongs to customer
    const subscription = await this.prisma.subscription.findFirst({
      where: {
        id: subscriptionId,
        customerProfileId,
      },
    });

    if (!subscription) {
      throw new Error('Subscription not found');
    }

    const updated = await this.stripe.subscriptions.update(subscriptionId, {
      cancel_at_period_end: cancelAtPeriodEnd,
    });

    await this.syncSubscription(subscriptionId);

    logger.info('Subscription cancelled', {
      subscriptionId,
      customerProfileId,
      cancelAtPeriodEnd,
    });

    return updated;
  }

  /**
   * Reactivate subscription
   */
  async reactivateSubscription(customerProfileId: string, subscriptionId: string) {
    // Verify subscription belongs to customer
    const subscription = await this.prisma.subscription.findFirst({
      where: {
        id: subscriptionId,
        customerProfileId,
      },
    });

    if (!subscription) {
      throw new Error('Subscription not found');
    }

    const updated = await this.stripe.subscriptions.update(subscriptionId, {
      cancel_at_period_end: false,
    });

    await this.syncSubscription(subscriptionId);

    logger.info('Subscription reactivated', {
      subscriptionId,
      customerProfileId,
    });

    return updated;
  }

  /**
   * List prices
   */
  async listPrices() {
    const prices = await this.stripe.prices.list({
      active: true,
      expand: ['data.product'],
    });

    return prices.data;
  }
}
```

### 13.2 Billing Routes

```typescript
// src/routes/v1/customer/billing.ts

import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { StripeService } from '../../../services/stripe-service';

const CreateCheckoutSessionSchema = z.object({
  priceId: z.string().min(1),
  successUrl: z.string().url(),
  cancelUrl: z.string().url(),
  trialDays: z.number().int().min(0).max(90).optional(),
});

const CancelSubscriptionSchema = z.object({
  subscriptionId: z.string().min(1),
  cancelAtPeriodEnd: z.boolean().default(true),
});

const billingRoutes: FastifyPluginAsync = async (server) => {
  const stripeService = new StripeService(server.prisma, server);

  // Get subscription status
  server.get(
    '/billing/subscription',
    {
      schema: {
        tags: ['customer'],
        summary: 'Get subscription status',
        security: [{ bearerAuth: [] }],
        response: {
          200: {
            description: 'Subscription details',
            type: 'object',
            properties: {
              hasActiveSubscription: { type: 'boolean' },
              subscription: {
                type: 'object',
                nullable: true,
                properties: {
                  id: { type: 'string' },
                  status: { type: 'string' },
                  currentPeriodStart: { type: 'string', format: 'date-time' },
                  currentPeriodEnd: { type: 'string', format: 'date-time' },
                  cancelAtPeriodEnd: { type: 'boolean' },
                },
              },
            },
          },
        },
      },
      preHandler: [server.authenticate],
    },
    async (request, reply) => {
      const customerProfileId = request.user.activeContext?.id;

      if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
        return reply.code(403).send({
          type: 'authorization_denied',
          title: 'Customer Context Required',
        });
      }

      const subscription = await stripeService.getActiveSubscription(customerProfileId);

      return reply.send({
        hasActiveSubscription: !!subscription,
        subscription: subscription || null,
      });
    }
  );

  // List available prices
  server.get(
    '/billing/prices',
    {
      schema: {
        tags: ['customer'],
        summary: 'List available subscription prices',
        security: [{ bearerAuth: [] }],
        response: {
          200: {
            description: 'List of prices',
            type: 'object',
            properties: {
              prices: {
                type: 'array',
                items: { type: 'object' },
              },
            },
          },
        },
      },
      preHandler: [server.authenticate],
    },
    async (request, reply) => {
      const prices = await stripeService.listPrices();

      return reply.send({ prices });
    }
  );

  // Create checkout session
  server.post(
    '/billing/create-checkout-session',
    {
      schema: {
        tags: ['customer'],
        summary: 'Create Stripe checkout session',
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['priceId', 'successUrl', 'cancelUrl'],
          properties: {
            priceId: { type: 'string' },
            successUrl: { type: 'string', format: 'uri' },
            cancelUrl: { type: 'string', format: 'uri' },
            trialDays: { type: 'integer', minimum: 0, maximum: 90 },
          },
        },
        response: {
          200: {
            description: 'Checkout session created',
            type: 'object',
            properties: {
              url: { type: 'string' },
              sessionId: { type: 'string' },
            },
          },
        },
      },
      preHandler: [server.authenticate],
    },
    async (request, reply) => {
      const customerProfileId = request.user.activeContext?.id;

      if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
        return reply.code(403).send({
          type: 'authorization_denied',
          title: 'Customer Context Required',
        });
      }

      try {
        const data = CreateCheckoutSessionSchema.parse(request.body);
        
        const session = await stripeService.createCheckoutSession(
          customerProfileId,
          data.priceId,
          {
            successUrl: data.successUrl,
            cancelUrl: data.cancelUrl,
            trialDays: data.trialDays,
          }
        );

        return reply.send({
          url: session.url,
          sessionId: session.id,
        });
      } catch (error) {
        if (error instanceof Error) {
          return reply.code(400).send({
            type: 'invalid_request',
            title: 'Checkout Failed',
            detail: error.message,
          });
        }
        throw error;
      }
    }
  );

  // Create customer portal session
  server.post(
    '/billing/create-portal-session',
    {
      schema: {
        tags: ['customer'],
        summary: 'Create customer portal session',
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['returnUrl'],
          properties: {
            returnUrl: { type: 'string', format: 'uri' },
          },
        },
        response: {
          200: {
            description: 'Portal session created',
            type: 'object',
            properties: {
              url: { type: 'string' },
            },
          },
        },
      },
      preHandler: [server.authenticate],
    },
    async (request, reply) => {
      const customerProfileId = request.user.activeContext?.id;

      if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
        return reply.code(403).send({
          type: 'authorization_denied',
          title: 'Customer Context Required',
        });
      }

      const { returnUrl } = request.body as { returnUrl: string };

      try {
        const session = await stripeService.createPortalSession(
          customerProfileId,
          returnUrl
        );

        return reply.send({ url: session.url });
      } catch (error) {
        if (error instanceof Error) {
          return reply.code(400).send({
            type: 'invalid_request',
            title: 'Portal Session Failed',
            detail: error.message,
          });
        }
        throw error;
      }
    }
  );

  // Cancel subscription
  server.post(
    '/billing/cancel-subscription',
    {
      schema: {
        tags: ['customer'],
        summary: 'Cancel subscription',
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['subscriptionId'],
          properties: {
            subscriptionId: { type: 'string' },
            cancelAtPeriodEnd: { type: 'boolean', default: true },
          },
        },
        response: {
          200: {
            description: 'Subscription cancelled',
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              cancelAtPeriodEnd: { type: 'boolean' },
            },
          },
        },
      },
      preHandler: [server.authenticate],
    },
    async (request, reply) => {
      const customerProfileId = request.user.activeContext?.id;

      if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
        return reply.code(403).send({
          type: 'authorization_denied',
          title: 'Customer Context Required',
        });
      }

      try {
        const data = CancelSubscriptionSchema.parse(request.body);
        
        await stripeService.cancelSubscription(
          customerProfileId,
          data.subscriptionId,
          data.cancelAtPeriodEnd
        );

        return reply.send({
          success: true,
          cancelAtPeriodEnd: data.cancelAtPeriodEnd,
        });
      } catch (error) {
        if (error instanceof Error) {
          return reply.code(400).send({
            type: 'invalid_request',
            title: 'Cancellation Failed',
            detail: error.message,
          });
        }
        throw error;
      }
    }
  );

  // Reactivate subscription
  server.post(
    '/billing/reactivate-subscription',
    {
      schema: {
        tags: ['customer'],
        summary: 'Reactivate cancelled subscription',
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['subscriptionId'],
          properties: {
            subscriptionId: { type: 'string' },
          },
        },
        response: {
          200: {
            description: 'Subscription reactivated',
            type: 'object',
            properties: {
              success: { type: 'boolean' },
            },
          },
        },
      },
      preHandler: [server.authenticate],
    },
    async (request, reply) => {
      const customerProfileId = request.user.activeContext?.id;

      if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
        return reply.code(403).send({
          type: 'authorization_denied',
          title: 'Customer Context Required',
        });
      }

      const { subscriptionId } = request.body as { subscriptionId: string };

      try {
        await stripeService.reactivateSubscription(customerProfileId, subscriptionId);

        return reply.send({ success: true });
      } catch (error) {
        if (error instanceof Error) {
          return reply.code(400).send({
            type: 'invalid_request',
            title: 'Reactivation Failed',
            detail: error.message,
          });
        }
        throw error;
      }
    }
  );
};

export default billingRoutes;
```

### 13.3 Stripe Webhook Handler

```typescript
// src/routes/webhooks/stripe.ts

import type { FastifyPluginAsync } from 'fastify';
import Stripe from 'stripe';
import { StripeService } from '../../services/stripe-service';
import { logger } from '../../lib/logger';

const stripeWebhookRoutes: FastifyPluginAsync = async (server) => {
  const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
    apiVersion: '2024-11-20.acacia',
  });

  const stripeService = new StripeService(server.prisma, server);

  server.post(
    '/webhooks/stripe',
    {
      config: {
        rawBody: true, // Need raw body for signature verification
      },
    },
    async (request, reply) => {
      const sig = request.headers['stripe-signature'];

      if (!sig || typeof sig !== 'string') {
        return reply.code(400).send({ error: 'Missing stripe-signature header' });
      }

      let event: Stripe.Event;

      try {
        event = stripe.webhooks.constructEvent(
          request.rawBody!,
          sig,
          process.env.STRIPE_WEBHOOK_SECRET!
        );
      } catch (error) {
        logger.error('Webhook signature verification failed', { error });
        return reply.code(400).send({ error: 'Invalid signature' });
      }

      // Store webhook event
      await server.prisma.stripeWebhookEvent.create({
        data: {
          eventId: event.id,
          eventType: event.type,
          payload: event.data.object as any,
          livemode: event.livemode,
          requestId: event.request?.id || null,
        },
      });

      // Process event
      try {
        switch (event.type) {
          case 'customer.subscription.created':
          case 'customer.subscription.updated':
          case 'customer.subscription.deleted': {
            const subscription = event.data.object as Stripe.Subscription;
            await stripeService.syncSubscription(subscription.id);
            break;
          }

          case 'checkout.session.completed': {
            const session = event.data.object as Stripe.Checkout.Session;
            
            // Update checkout session status
            await server.prisma.stripeCheckoutSession.update({
              where: { id: session.id },
              data: {
                paymentStatus: session.payment_status,
                completedAt: new Date(),
              },
            });

            // Sync subscription if present
            if (session.subscription && typeof session.subscription === 'string') {
              await stripeService.syncSubscription(session.subscription);
            }
            break;
          }

          case 'invoice.payment_succeeded':
          case 'invoice.payment_failed': {
            const invoice = event.data.object as Stripe.Invoice;
            logger.info('Invoice payment event', {
              invoiceId: invoice.id,
              status: invoice.status,
              customerId: invoice.customer,
            });
            break;
          }

          default:
            logger.info('Unhandled webhook event type', { type: event.type });
        }

        // Mark as processed
        await server.prisma.stripeWebhookEvent.updateMany({
          where: { eventId: event.id },
          data: {
            processed: true,
            processedAt: new Date(),
          },
        });
      } catch (error) {
        logger.error('Error processing webhook event', {
          eventId: event.id,
          type: event.type,
          error,
        });

        // Store error
        await server.prisma.stripeWebhookEvent.updateMany({
          where: { eventId: event.id },
          data: {
            errorMessage: error instanceof Error ? error.message : 'Unknown error',
          },
        });

        // Return 500 to trigger retry
        return reply.code(500).send({ error: 'Webhook processing failed' });
      }

      return reply.send({ received: true });
    }
  );
};

export default stripeWebhookRoutes;
```

---

## Phase 14: Request Interface API

**Objective**: Create a modern REST API with proper authentication headers for standalone request interface applications (desktop/web), allowing customers who don't use OpenKJ to receive song requests through native apps.

### 14.1 Request Interface Authentication

The standalone request interface will authenticate using OpenKJ API keys but via proper `Authorization` headers instead of body-based authentication. This makes the API easier to integrate with standard HTTP clients and future karaoke host software partnerships.

```typescript
// src/lib/middleware/request-interface-auth.ts

import type { FastifyRequest, FastifyReply } from 'fastify';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';
import { logger } from '../logger';

export interface RequestInterfaceAuthUser {
  customerProfileId: string;
  apiKeyId: string;
  hasActiveSubscription: boolean;
}

declare module 'fastify' {
  interface FastifyRequest {
    requestInterfaceUser?: RequestInterfaceAuthUser;
  }
}

/**
 * Authenticate request interface using API key from Authorization header
 * Format: Authorization: Bearer <api_key>
 */
export async function authenticateRequestInterface(
  request: FastifyRequest,
  reply: FastifyReply,
  prisma: PrismaClient
): Promise<void> {
  const authHeader = request.headers.authorization;

  if (!authHeader) {
    return reply.code(401).send({
      type: 'authentication_required',
      title: 'Authentication Required',
      detail: 'Missing Authorization header',
    });
  }

  const [scheme, token] = authHeader.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return reply.code(401).send({
      type: 'invalid_authentication',
      title: 'Invalid Authentication',
      detail: 'Authorization header must use Bearer scheme',
    });
  }

  // Find matching API key
  const apiKeys = await prisma.apiKey.findMany({
    where: {
      status: 'active',
      revokedAt: null,
    },
    include: {
      customerProfile: {
        include: {
          subscriptions: {
            where: {
              status: {
                in: ['active', 'trialing'],
              },
            },
            take: 1,
            orderBy: { createdAt: 'desc' },
          },
        },
      },
    },
  });

  let matchedKey = null;

  for (const key of apiKeys) {
    const isMatch = await bcrypt.compare(token, key.apiKeyHash);
    if (isMatch) {
      matchedKey = key;
      break;
    }
  }

  if (!matchedKey) {
    logger.warn('Request interface authentication failed - invalid API key', {
      ip: request.ip,
    });

    return reply.code(401).send({
      type: 'invalid_credentials',
      title: 'Invalid API Key',
      detail: 'The provided API key is not valid',
    });
  }

  // Update last used timestamp
  await prisma.apiKey.update({
    where: { id: matchedKey.id },
    data: { lastUsedAt: new Date() },
  });

  const hasActiveSubscription = matchedKey.customerProfile.subscriptions.length > 0;

  // Attach auth info to request
  request.requestInterfaceUser = {
    customerProfileId: matchedKey.customerProfileId,
    apiKeyId: matchedKey.id,
    hasActiveSubscription,
  };

  logger.info('Request interface authenticated', {
    customerProfileId: matchedKey.customerProfileId,
    apiKeyId: matchedKey.id,
  });
}
```

### 14.2 Request Interface Service

```typescript
// src/services/request-interface-service.ts

import { PrismaClient } from '@prisma/client';
import { logger } from '../lib/logger';

export interface RequestFilters {
  venueId?: string;
  processed?: boolean;
  limit?: number;
  offset?: number;
  singerName?: string;
  songSearch?: string;
}

export class RequestInterfaceService {
  constructor(private prisma: PrismaClient) {}

  /**
   * Get requests for customer with filters
   */
  async getRequests(customerProfileId: string, filters: RequestFilters = {}) {
    const {
      venueId,
      processed = false,
      limit = 100,
      offset = 0,
      singerName,
      songSearch,
    } = filters;

    const where: any = {
      venue: {
        customerProfileId,
      },
      processed,
    };

    if (venueId) {
      where.venueId = venueId;
    }

    if (singerName) {
      where.singerUser = {
        name: {
          contains: singerName,
          mode: 'insensitive',
        },
      };
    }

    if (songSearch) {
      where.OR = [
        {
          artist: {
            contains: songSearch,
            mode: 'insensitive',
          },
        },
        {
          title: {
            contains: songSearch,
            mode: 'insensitive',
          },
        },
      ];
    }

    const [requests, total] = await Promise.all([
      this.prisma.request.findMany({
        where,
        include: {
          venue: {
            select: {
              id: true,
              name: true,
              urlName: true,
            },
          },
          singerUser: {
            select: {
              id: true,
              name: true,
              email: true,
            },
          },
        },
        orderBy: { requestedAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.request.count({ where }),
    ]);

    return {
      requests: requests.map((r) => ({
        id: r.requestId.toString(),
        venueId: r.venueId,
        venueName: r.venue.name,
        singer: r.singerUser?.name || 'Anonymous',
        artist: r.artist,
        title: r.title,
        keyChange: r.keyChange,
        processed: r.processed,
        requestedAt: r.requestedAt,
      })),
      pagination: {
        total,
        limit,
        offset,
        hasMore: offset + limit < total,
      },
    };
  }

  /**
   * Get request statistics
   */
  async getStats(customerProfileId: string, venueId?: string) {
    const where: any = {
      venue: {
        customerProfileId,
      },
    };

    if (venueId) {
      where.venueId = venueId;
    }

    const [total, pending, processedToday] = await Promise.all([
      this.prisma.request.count({ where }),
      this.prisma.request.count({
        where: { ...where, processed: false },
      }),
      this.prisma.request.count({
        where: {
          ...where,
          processed: true,
          updatedAt: {
            gte: new Date(new Date().setHours(0, 0, 0, 0)),
          },
        },
      }),
    ]);

    return {
      total,
      pending,
      processedToday,
    };
  }

  /**
   * Mark request as processed
   */
  async markAsProcessed(
    customerProfileId: string,
    requestId: string
  ) {
    const request = await this.prisma.request.findFirst({
      where: {
        requestId: BigInt(requestId),
        venue: {
          customerProfileId,
        },
      },
    });

    if (!request) {
      throw new Error('Request not found or access denied');
    }

    const updated = await this.prisma.request.update({
      where: { requestId: BigInt(requestId) },
      data: { processed: true },
    });

    logger.info('Request marked as processed via interface', {
      requestId,
      customerProfileId,
    });

    return updated;
  }

  /**
   * Mark request as unprocessed (undo)
   */
  async markAsUnprocessed(
    customerProfileId: string,
    requestId: string
  ) {
    const request = await this.prisma.request.findFirst({
      where: {
        requestId: BigInt(requestId),
        venue: {
          customerProfileId,
        },
      },
    });

    if (!request) {
      throw new Error('Request not found or access denied');
    }

    const updated = await this.prisma.request.update({
      where: { requestId: BigInt(requestId) },
      data: { processed: false },
    });

    logger.info('Request marked as unprocessed via interface', {
      requestId,
      customerProfileId,
    });

    return updated;
  }

  /**
   * Bulk mark requests as processed
   */
  async bulkMarkAsProcessed(
    customerProfileId: string,
    requestIds: string[]
  ) {
    const result = await this.prisma.request.updateMany({
      where: {
        requestId: {
          in: requestIds.map((id) => BigInt(id)),
        },
        venue: {
          customerProfileId,
        },
      },
      data: { processed: true },
    });

    logger.info('Bulk mark as processed via interface', {
      customerProfileId,
      count: result.count,
    });

    return result;
  }

  /**
   * Delete request
   */
  async deleteRequest(
    customerProfileId: string,
    requestId: string
  ) {
    const request = await this.prisma.request.findFirst({
      where: {
        requestId: BigInt(requestId),
        venue: {
          customerProfileId,
        },
      },
    });

    if (!request) {
      throw new Error('Request not found or access denied');
    }

    await this.prisma.request.delete({
      where: { requestId: BigInt(requestId) },
    });

    logger.info('Request deleted via interface', {
      requestId,
      customerProfileId,
    });
  }

  /**
   * Get venues for customer
   */
  async getVenues(customerProfileId: string) {
    const venues = await this.prisma.venue.findMany({
      where: { customerProfileId },
      select: {
        id: true,
        name: true,
        urlName: true,
        acceptingRequests: true,
        address: true,
        city: true,
        state: true,
        _count: {
          select: {
            requests: {
              where: { processed: false },
            },
          },
        },
      },
      orderBy: { name: 'asc' },
    });

    return venues.map((v) => ({
      id: v.id,
      name: v.name,
      urlName: v.urlName,
      acceptingRequests: v.acceptingRequests,
      location: `${v.city}, ${v.state}`,
      pendingRequests: v._count.requests,
    }));
  }
}
```

### 14.3 Request Interface Routes

```typescript
// src/routes/v1/request-interface/index.ts

import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { RequestInterfaceService } from '../../../services/request-interface-service';
import { authenticateRequestInterface } from '../../../lib/middleware/request-interface-auth';

const GetRequestsSchema = z.object({
  venueId: z.string().uuid().optional(),
  processed: z.coerce.boolean().optional(),
  limit: z.coerce.number().int().min(1).max(500).optional(),
  offset: z.coerce.number().int().min(0).optional(),
  singerName: z.string().optional(),
  songSearch: z.string().optional(),
});

const MarkProcessedSchema = z.object({
  requestIds: z.array(z.string()),
});

const requestInterfaceRoutes: FastifyPluginAsync = async (server) => {
  const service = new RequestInterfaceService(server.prisma);

  // Middleware to authenticate all request interface routes
  server.addHook('preHandler', async (request, reply) => {
    await authenticateRequestInterface(request, reply, server.prisma);
  });

  // Get venues
  server.get(
    '/request-interface/venues',
    {
      schema: {
        tags: ['request-interface'],
        summary: 'Get venues',
        description: 'Get all venues for authenticated customer',
        security: [{ bearerAuth: [] }],
        response: {
          200: {
            description: 'List of venues',
            type: 'object',
            properties: {
              venues: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    id: { type: 'string' },
                    name: { type: 'string' },
                    urlName: { type: 'string' },
                    acceptingRequests: { type: 'boolean' },
                    location: { type: 'string' },
                    pendingRequests: { type: 'integer' },
                  },
                },
              },
            },
          },
        },
      },
    },
    async (request, reply) => {
      if (!request.requestInterfaceUser) {
        return reply.code(401).send({
          type: 'authentication_required',
          title: 'Authentication Required',
        });
      }

      const venues = await service.getVenues(
        request.requestInterfaceUser.customerProfileId
      );

      return reply.send({ venues });
    }
  );

  // Get requests
  server.get(
    '/request-interface/requests',
    {
      schema: {
        tags: ['request-interface'],
        summary: 'Get song requests',
        description: 'Get song requests with optional filters',
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          properties: {
            venueId: { type: 'string', format: 'uuid' },
            processed: { type: 'boolean', default: false },
            limit: { type: 'integer', minimum: 1, maximum: 500, default: 100 },
            offset: { type: 'integer', minimum: 0, default: 0 },
            singerName: { type: 'string' },
            songSearch: { type: 'string' },
          },
        },
        response: {
          200: {
            description: 'List of requests',
            type: 'object',
            properties: {
              requests: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    id: { type: 'string' },
                    venueId: { type: 'string' },
                    venueName: { type: 'string' },
                    singer: { type: 'string' },
                    artist: { type: 'string' },
                    title: { type: 'string' },
                    keyChange: { type: 'integer' },
                    processed: { type: 'boolean' },
                    requestedAt: { type: 'string', format: 'date-time' },
                  },
                },
              },
              pagination: {
                type: 'object',
                properties: {
                  total: { type: 'integer' },
                  limit: { type: 'integer' },
                  offset: { type: 'integer' },
                  hasMore: { type: 'boolean' },
                },
              },
            },
          },
        },
      },
    },
    async (request, reply) => {
      if (!request.requestInterfaceUser) {
        return reply.code(401).send({
          type: 'authentication_required',
          title: 'Authentication Required',
        });
      }

      const filters = GetRequestsSchema.parse(request.query);

      const result = await service.getRequests(
        request.requestInterfaceUser.customerProfileId,
        filters
      );

      return reply.send(result);
    }
  );

  // Get request statistics
  server.get(
    '/request-interface/stats',
    {
      schema: {
        tags: ['request-interface'],
        summary: 'Get request statistics',
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          properties: {
            venueId: { type: 'string', format: 'uuid' },
          },
        },
        response: {
          200: {
            description: 'Request statistics',
            type: 'object',
            properties: {
              total: { type: 'integer' },
              pending: { type: 'integer' },
              processedToday: { type: 'integer' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      if (!request.requestInterfaceUser) {
        return reply.code(401).send({
          type: 'authentication_required',
          title: 'Authentication Required',
        });
      }

      const { venueId } = request.query as { venueId?: string };

      const stats = await service.getStats(
        request.requestInterfaceUser.customerProfileId,
        venueId
      );

      return reply.send(stats);
    }
  );

  // Mark request as processed
  server.patch(
    '/request-interface/requests/:requestId/process',
    {
      schema: {
        tags: ['request-interface'],
        summary: 'Mark request as processed',
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          properties: {
            requestId: { type: 'string' },
          },
        },
        response: {
          200: {
            description: 'Request processed',
            type: 'object',
            properties: {
              success: { type: 'boolean' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      if (!request.requestInterfaceUser) {
        return reply.code(401).send({
          type: 'authentication_required',
          title: 'Authentication Required',
        });
      }

      const { requestId } = request.params as { requestId: string };

      try {
        await service.markAsProcessed(
          request.requestInterfaceUser.customerProfileId,
          requestId
        );

        return reply.send({ success: true });
      } catch (error) {
        if (error instanceof Error && error.message.includes('not found')) {
          return reply.code(404).send({
            type: 'resource_not_found',
            title: 'Request Not Found',
            detail: error.message,
          });
        }
        throw error;
      }
    }
  );

  // Mark request as unprocessed
  server.patch(
    '/request-interface/requests/:requestId/unprocess',
    {
      schema: {
        tags: ['request-interface'],
        summary: 'Mark request as unprocessed',
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          properties: {
            requestId: { type: 'string' },
          },
        },
        response: {
          200: {
            description: 'Request unprocessed',
            type: 'object',
            properties: {
              success: { type: 'boolean' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      if (!request.requestInterfaceUser) {
        return reply.code(401).send({
          type: 'authentication_required',
          title: 'Authentication Required',
        });
      }

      const { requestId } = request.params as { requestId: string };

      try {
        await service.markAsUnprocessed(
          request.requestInterfaceUser.customerProfileId,
          requestId
        );

        return reply.send({ success: true });
      } catch (error) {
        if (error instanceof Error && error.message.includes('not found')) {
          return reply.code(404).send({
            type: 'resource_not_found',
            title: 'Request Not Found',
            detail: error.message,
          });
        }
        throw error;
      }
    }
  );

  // Bulk mark as processed
  server.post(
    '/request-interface/requests/bulk/process',
    {
      schema: {
        tags: ['request-interface'],
        summary: 'Bulk mark requests as processed',
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['requestIds'],
          properties: {
            requestIds: {
              type: 'array',
              items: { type: 'string' },
              minItems: 1,
              maxItems: 100,
            },
          },
        },
        response: {
          200: {
            description: 'Requests processed',
            type: 'object',
            properties: {
              processedCount: { type: 'integer' },
            },
          },
        },
      },
      config: {
        rateLimit: {
          max: 10,
          timeWindow: '1 minute',
        },
      },
    },
    async (request, reply) => {
      if (!request.requestInterfaceUser) {
        return reply.code(401).send({
          type: 'authentication_required',
          title: 'Authentication Required',
        });
      }

      const { requestIds } = MarkProcessedSchema.parse(request.body);

      const result = await service.bulkMarkAsProcessed(
        request.requestInterfaceUser.customerProfileId,
        requestIds
      );

      return reply.send({ processedCount: result.count });
    }
  );

  // Delete request
  server.delete(
    '/request-interface/requests/:requestId',
    {
      schema: {
        tags: ['request-interface'],
        summary: 'Delete request',
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          properties: {
            requestId: { type: 'string' },
          },
        },
        response: {
          204: { description: 'Request deleted' },
        },
      },
    },
    async (request, reply) => {
      if (!request.requestInterfaceUser) {
        return reply.code(401).send({
          type: 'authentication_required',
          title: 'Authentication Required',
        });
      }

      const { requestId } = request.params as { requestId: string };

      try {
        await service.deleteRequest(
          request.requestInterfaceUser.customerProfileId,
          requestId
        );

        return reply.code(204).send();
      } catch (error) {
        if (error instanceof Error && error.message.includes('not found')) {
          return reply.code(404).send({
            type: 'resource_not_found',
            title: 'Request Not Found',
            detail: error.message,
          });
        }
        throw error;
      }
    }
  );
};

export default requestInterfaceRoutes;
```

### 14.4 Request Interface Example Client

```typescript
// examples/request-interface-client.ts
// Example implementation for standalone request interface application

import axios, { AxiosInstance } from 'axios';

export interface RequestInterfaceConfig {
  apiUrl: string;
  apiKey: string;
}

export class RequestInterfaceClient {
  private client: AxiosInstance;

  constructor(config: RequestInterfaceConfig) {
    this.client = axios.create({
      baseURL: config.apiUrl,
      headers: {
        'Authorization': `Bearer ${config.apiKey}`,
        'Content-Type': 'application/json',
      },
    });
  }

  /**
   * Get all venues
   */
  async getVenues() {
    const response = await this.client.get('/v1/request-interface/venues');
    return response.data.venues;
  }

  /**
   * Get pending requests for a venue
   */
  async getPendingRequests(venueId?: string) {
    const response = await this.client.get('/v1/request-interface/requests', {
      params: {
        venueId,
        processed: false,
        limit: 100,
      },
    });
    return response.data;
  }

  /**
   * Get request statistics
   */
  async getStats(venueId?: string) {
    const response = await this.client.get('/v1/request-interface/stats', {
      params: { venueId },
    });
    return response.data;
  }

  /**
   * Mark request as processed
   */
  async markAsProcessed(requestId: string) {
    const response = await this.client.patch(
      `/v1/request-interface/requests/${requestId}/process`
    );
    return response.data;
  }

  /**
   * Bulk mark requests as processed
   */
  async bulkMarkAsProcessed(requestIds: string[]) {
    const response = await this.client.post(
      '/v1/request-interface/requests/bulk/process',
      { requestIds }
    );
    return response.data;
  }

  /**
   * Delete request
   */
  async deleteRequest(requestId: string) {
    await this.client.delete(`/v1/request-interface/requests/${requestId}`);
  }

  /**
   * Search requests
   */
  async searchRequests(options: {
    venueId?: string;
    singerName?: string;
    songSearch?: string;
    processed?: boolean;
  }) {
    const response = await this.client.get('/v1/request-interface/requests', {
      params: options,
    });
    return response.data;
  }
}

// Usage example
async function example() {
  const client = new RequestInterfaceClient({
    apiUrl: 'https://api.singrkaraoke.com',
    apiKey: 'sk_live_xxxxxxxxxxxxx',
  });

  // Get venues
  const venues = await client.getVenues();
  console.log('Venues:', venues);

  // Get pending requests for first venue
  if (venues.length > 0) {
    const requests = await client.getPendingRequests(venues[0].id);
    console.log('Pending requests:', requests.requests);

    // Mark first request as processed
    if (requests.requests.length > 0) {
      await client.markAsProcessed(requests.requests[0].id);
      console.log('Request marked as processed');
    }
  }

  // Get statistics
  const stats = await client.getStats();
  console.log('Stats:', stats);
}
```

---

## Phase 15: Admin & Support Portal Backend

**Objective**: Implement comprehensive admin tooling with full CRUD operations and delegated access system for support users to operate within customer/singer contexts.

### 15.1 Admin & Support Database Schema

```sql
-- Migration: 015_admin_support_system.sql

-- Delegated access sessions for support users
CREATE TABLE delegated_access_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  support_admin_profile_id UUID NOT NULL REFERENCES admin_profiles(id) ON DELETE CASCADE,
  target_singr_user_id UUID NOT NULL REFERENCES singr_users(id) ON DELETE CASCADE,
  target_context_type VARCHAR(20) NOT NULL, -- 'customer', 'singer'
  target_context_id UUID NOT NULL, -- customer_profile_id or singer_profile_id
  session_token VARCHAR(255) NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by_admin_id UUID REFERENCES admin_profiles(id) ON DELETE SET NULL,
  
  CONSTRAINT valid_context_type CHECK (target_context_type IN ('customer', 'singer'))
);

CREATE INDEX idx_delegated_sessions_support_admin 
  ON delegated_access_sessions(support_admin_profile_id);
CREATE INDEX idx_delegated_sessions_target_user 
  ON delegated_access_sessions(target_singr_user_id);
CREATE INDEX idx_delegated_sessions_token 
  ON delegated_access_sessions(session_token) 
  WHERE revoked_at IS NULL;
CREATE INDEX idx_delegated_sessions_expires 
  ON delegated_access_sessions(expires_at) 
  WHERE revoked_at IS NULL;

-- Admin action audit log
CREATE TABLE admin_action_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_profile_id UUID NOT NULL REFERENCES admin_profiles(id) ON DELETE CASCADE,
  action VARCHAR(100) NOT NULL,
  target_type VARCHAR(50), -- 'user', 'venue', 'subscription', 'request', etc.
  target_id VARCHAR(100),
  metadata JSONB DEFAULT '{}',
  ip_address INET,
  user_agent TEXT,
  delegated_session_id UUID REFERENCES delegated_access_sessions(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_admin_audit_admin 
  ON admin_action_audit_log(admin_profile_id, created_at DESC);
CREATE INDEX idx_admin_audit_action 
  ON admin_action_audit_log(action);
CREATE INDEX idx_admin_audit_target 
  ON admin_action_audit_log(target_type, target_id);
CREATE INDEX idx_admin_audit_delegated 
  ON admin_action_audit_log(delegated_session_id) 
  WHERE delegated_session_id IS NOT NULL;

COMMENT ON TABLE delegated_access_sessions IS 
  'Temporary sessions allowing support users to operate as customers or singers';
COMMENT ON TABLE admin_action_audit_log IS 
  'Comprehensive audit log of all admin and support actions';
```

### 15.2 Delegated Access Service

```typescript
// src/services/delegated-access-service.ts

import { PrismaClient } from '@prisma/client';
import { randomBytes } from 'crypto';
import { logger } from '../lib/logger';

export interface DelegatedAccessSession {
  id: string;
  sessionToken: string;
  targetUserId: string;
  targetContextType: 'customer' | 'singer';
  targetContextId: string;
  expiresAt: Date;
}

export class DelegatedAccessService {
  constructor(private prisma: PrismaClient) {}

  /**
   * Create delegated access session
   * Allows support user to operate as a customer or singer
   */
  async createDelegatedSession(
    supportAdminProfileId: string,
    targetUserId: string,
    contextType: 'customer' | 'singer',
    durationHours: number = 4
  ): Promise<DelegatedAccessSession> {
    // Verify target user exists and has the requested context
    const targetUser = await this.prisma.singrUser.findUnique({
      where: { id: targetUserId },
      include: {
        customerProfile: true,
        singerProfile: true,
      },
    });

    if (!targetUser) {
      throw new Error('Target user not found');
    }

    let targetContextId: string;

    if (contextType === 'customer') {
      if (!targetUser.customerProfile) {
        throw new Error('User does not have a customer profile');
      }
      targetContextId = targetUser.customerProfile.id;
    } else {
      if (!targetUser.singerProfile) {
        throw new Error('User does not have a singer profile');
      }
      targetContextId = targetUser.singerProfile.id;
    }

    // Generate session token
    const sessionToken = randomBytes(48).toString('hex');
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + durationHours);

    // Create session
    const session = await this.prisma.delegatedAccessSession.create({
      data: {
        supportAdminProfileId,
        targetSingrUserId: targetUserId,
        targetContextType: contextType,
        targetContextId,
        sessionToken,
        expiresAt,
        createdByAdminId: supportAdminProfileId,
      },
    });

    // Log admin action
    await this.prisma.adminActionAuditLog.create({
      data: {
        adminProfileId: supportAdminProfileId,
        action: 'delegated_access.created',
        targetType: 'singr_user',
        targetId: targetUserId,
        metadata: {
          contextType,
          contextId: targetContextId,
          expiresAt: expiresAt.toISOString(),
        },
      },
    });

    logger.info('Delegated access session created', {
      supportAdminProfileId,
      targetUserId,
      contextType,
      sessionId: session.id,
      expiresAt,
    });

    return {
      id: session.id,
      sessionToken: session.sessionToken,
      targetUserId: session.targetSingrUserId,
      targetContextType: session.targetContextType as 'customer' | 'singer',
      targetContextId: session.targetContextId,
      expiresAt: session.expiresAt,
    };
  }

  /**
   * Validate and retrieve delegated session
   */
  async validateDelegatedSession(sessionToken: string) {
    const session = await this.prisma.delegatedAccessSession.findFirst({
      where: {
        sessionToken,
        revokedAt: null,
        expiresAt: {
          gt: new Date(),
        },
      },
      include: {
        supportAdminProfile: {
          include: {
            singrUser: {
              select: {
                id: true,
                email: true,
                name: true,
              },
            },
          },
        },
        targetSingrUser: {
          select: {
            id: true,
            email: true,
            name: true,
          },
        },
      },
    });

    if (!session) {
      throw new Error('Invalid or expired delegated session');
    }

    return session;
  }

  /**
   * Revoke delegated session
   */
  async revokeDelegatedSession(sessionId: string, revokedByAdminId: string) {
    const session = await this.prisma.delegatedAccessSession.findUnique({
      where: { id: sessionId },
    });

    if (!session) {
      throw new Error('Session not found');
    }

    await this.prisma.delegatedAccessSession.update({
      where: { id: sessionId },
      data: { revokedAt: new Date() },
    });

    // Log admin action
    await this.prisma.adminActionAuditLog.create({
      data: {
        adminProfileId: revokedByAdminId,
        action: 'delegated_access.revoked',
        targetType: 'delegated_session',
        targetId: sessionId,
        metadata: {
          originalSupportAdminId: session.supportAdminProfileId,
          targetUserId: session.targetSingrUserId,
        },
      },
    });

    logger.info('Delegated access session revoked', {
      sessionId,
      revokedByAdminId,
    });
  }

  /**
   * List active delegated sessions
   */
  async listActiveSessions(supportAdminProfileId?: string) {
    const where: any = {
      revokedAt: null,
      expiresAt: {
        gt: new Date(),
      },
    };

    if (supportAdminProfileId) {
      where.supportAdminProfileId = supportAdminProfileId;
    }

    const sessions = await this.prisma.delegatedAccessSession.findMany({
      where,
      include: {
        supportAdminProfile: {
          include: {
            singrUser: {
              select: {
                id: true,
                email: true,
                name: true,
              },
            },
          },
        },
        targetSingrUser: {
          select: {
            id: true,
            email: true,
            name: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return sessions;
  }

  /**
   * Cleanup expired sessions
   */
  async cleanupExpiredSessions() {
    const result = await this.prisma.delegatedAccessSession.updateMany({
      where: {
        revokedAt: null,
        expiresAt: {
          lt: new Date(),
        },
      },
      data: {
        revokedAt: new Date(),
      },
    });

    logger.info('Cleaned up expired delegated sessions', {
      count: result.count,
    });

    return result.count;
  }
}
```

### 15.3 Admin Utility Service

```typescript
// src/services/admin-utility-service.ts

import { PrismaClient } from '@prisma/client';
import { randomBytes } from 'crypto';
import bcrypt from 'bcryptjs';
import { logger } from '../lib/logger';

export class AdminUtilityService {
  constructor(private prisma: PrismaClient) {}

  /**
   * Generate password reset token for user (admin tool)
   */
  async generatePasswordResetForUser(
    adminProfileId: string,
    targetUserId: string
  ) {
    const user = await this.prisma.singrUser.findUnique({
      where: { id: targetUserId },
    });

    if (!user) {
      throw new Error('User not found');
    }

    const token = randomBytes(32).toString('hex');
    const expires = new Date();
    expires.setHours(expires.getHours() + 24);

    await this.prisma.verificationToken.create({
      data: {
        identifier: user.email,
        token: await bcrypt.hash(token, 10),
        expires,
      },
    });

    // Log admin action
    await this.prisma.adminActionAuditLog.create({
      data: {
        adminProfileId,
        action: 'password_reset.generated',
        targetType: 'singr_user',
        targetId: targetUserId,
        metadata: {
          userEmail: user.email,
          expiresAt: expires.toISOString(),
        },
      },
    });

    logger.info('Password reset generated by admin', {
      adminProfileId,
      targetUserId,
      email: user.email,
    });

    return {
      token,
      resetUrl: `${process.env.APP_URL}/auth/reset-password?token=${token}`,
      expiresAt: expires,
    };
  }

  /**
   * Clear all requests for a venue (mark as processed)
   */
  async clearVenueRequests(
    adminProfileId: string,
    venueId: string,
    markAsProcessed: boolean = true
  ) {
    const venue = await this.prisma.venue.findUnique({
      where: { id: venueId },
      select: {
        id: true,
        name: true,
        customerProfileId: true,
      },
    });

    if (!venue) {
      throw new Error('Venue not found');
    }

    let result;

    if (markAsProcessed) {
      result = await this.prisma.request.updateMany({
        where: {
          venueId,
          processed: false,
        },
        data: {
          processed: true,
        },
      });
    } else {
      result = await this.prisma.request.deleteMany({
        where: { venueId },
      });
    }

    // Log admin action
    await this.prisma.adminActionAuditLog.create({
      data: {
        adminProfileId,
        action: markAsProcessed ? 'venue.requests_cleared' : 'venue.requests_deleted',
        targetType: 'venue',
        targetId: venueId,
        metadata: {
          venueName: venue.name,
          customerProfileId: venue.customerProfileId,
          count: result.count,
        },
      },
    });

    logger.info('Venue requests cleared by admin', {
      adminProfileId,
      venueId,
      count: result.count,
      markAsProcessed,
    });

    return {
      clearedCount: result.count,
      venueName: venue.name,
    };
  }

  /**
   * Toggle venue accepting status
   */
  async toggleVenueAccepting(
    adminProfileId: string,
    venueId: string,
    accepting: boolean
  ) {
    const venue = await this.prisma.venue.update({
      where: { id: venueId },
      data: { acceptingRequests: accepting },
    });

    // Log admin action
    await this.prisma.adminActionAuditLog.create({
      data: {
        adminProfileId,
        action: 'venue.accepting_toggled',
        targetType: 'venue',
        targetId: venueId,
        metadata: {
          venueName: venue.name,
          accepting,
        },
      },
    });

    logger.info('Venue accepting toggled by admin', {
      adminProfileId,
      venueId,
      accepting,
    });

    return venue;
  }

  /**
   * Get platform statistics
   */
  async getPlatformStats() {
    const [
      totalUsers,
      totalCustomers,
      totalSingers,
      activeSubscriptions,
      totalVenues,
      totalRequests,
      requestsToday,
    ] = await Promise.all([
      this.prisma.singrUser.count(),
      this.prisma.customerProfile.count(),
      this.prisma.singerProfile.count(),
      this.prisma.subscription.count({
        where: {
          status: {
            in: ['active', 'trialing'],
          },
        },
      }),
      this.prisma.venue.count(),
      this.prisma.request.count(),
      this.prisma.request.count({
        where: {
          requestedAt: {
            gte: new Date(new Date().setHours(0, 0, 0, 0)),
          },
        },
      }),
    ]);

    return {
      totalUsers,
      totalCustomers,
      totalSingers,
      activeSubscriptions,
      totalVenues,
      totalRequests,
      requestsToday,
    };
  }

  /**
   * Search users (admin tool)
   */
  async searchUsers(query: string, limit: number = 20) {
    const users = await this.prisma.singrUser.findMany({
      where: {
        OR: [
          {
            email: {
              contains: query,
              mode: 'insensitive',
            },
          },
          {
            name: {
              contains: query,
              mode: 'insensitive',
            },
          },
        ],
      },
      include: {
        customerProfile: {
          select: {
            id: true,
            businessName: true,
          },
        },
        singerProfile: {
          select: {
            id: true,
            nickname: true,
          },
        },
        adminProfile: {
          select: {
            id: true,
            adminLevel: true,
          },
        },
      },
      take: limit,
      orderBy: { createdAt: 'desc' },
    });

    return users.map((user) => ({
      id: user.id,
      email: user.email,
      name: user.name,
      hasCustomerProfile: !!user.customerProfile,
      hasSingerProfile: !!user.singerProfile,
      hasAdminProfile: !!user.adminProfile,
      customerBusinessName: user.customerProfile?.businessName,
      singerNickname: user.singerProfile?.nickname,
      adminLevel: user.adminProfile?.adminLevel,
      createdAt: user.createdAt,
    }));
  }

  /**
   * Get admin audit log
   */
  async getAdminAuditLog(options: {
    adminProfileId?: string;
    action?: string;
    targetType?: string;
    limit?: number;
    offset?: number;
  } = {}) {
    const { adminProfileId, action, targetType, limit = 50, offset = 0 } = options;

    const where: any = {};

    if (adminProfileId) {
      where.adminProfileId = adminProfileId;
    }

    if (action) {
      where.action = action;
    }

    if (targetType) {
      where.targetType = targetType;
    }

    const [logs, total] = await Promise.all([
      this.prisma.adminActionAuditLog.findMany({
        where,
        include: {
          adminProfile: {
            include: {
              singrUser: {
                select: {
                  id: true,
                  email: true,
                  name: true,
                },
              },
            },
          },
          delegatedSession: {
            select: {
              id: true,
              targetSingrUserId: true,
              targetContextType: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.adminActionAuditLog.count({ where }),
    ]);

    return {
      logs,
      pagination: {
        total,
        limit,
        offset,
        hasMore: offset + limit < total,
      },
    };
  }
}
```

### 15.4 Admin Utility Routes

```typescript
// src/routes/v1/admin/utilities.ts

import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { AdminUtilityService } from '../../../services/admin-utility-service';
import { DelegatedAccessService } from '../../../services/delegated-access-service';

const CreateDelegatedSessionSchema = z.object({
  targetUserId: z.string().uuid(),
  contextType: z.enum(['customer', 'singer']),
  durationHours: z.number().int().min(1).max(24).default(4),
});

const ClearVenueRequestsSchema = z.object({
  venueId: z.string().uuid(),
  markAsProcessed: z.boolean().default(true),
});

const adminUtilityRoutes: FastifyPluginAsync = async (server) => {
  const utilityService = new AdminUtilityService(server.prisma);
  const delegatedService = new DelegatedAccessService(server.prisma);

  // All routes require admin authentication
  server.addHook('preHandler', server.authenticate);
  server.addHook('preHandler', async (request, reply) => {
    if (!request.user.adminProfile) {
      return reply.code(403).send({
        type: 'forbidden',
        title: 'Admin Access Required',
        detail: 'This endpoint requires admin privileges',
      });
    }
  });

  // Get platform statistics
  server.get(
    '/admin/stats',
    {
      schema: {
        tags: ['admin'],
        summary: 'Get platform statistics',
        security: [{ bearerAuth: [] }],
        response: {
          200: {
            description: 'Platform statistics',
            type: 'object',
            properties: {
              totalUsers: { type: 'integer' },
              totalCustomers: { type: 'integer' },
              totalSingers: { type: 'integer' },
              activeSubscriptions: { type: 'integer' },
              totalVenues: { type: 'integer' },
              totalRequests: { type: 'integer' },
              requestsToday: { type: 'integer' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const stats = await utilityService.getPlatformStats();
      return reply.send(stats);
    }
  );

  // Search users
  server.get(
    '/admin/users/search',
    {
      schema: {
        tags: ['admin'],
        summary: 'Search users',
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          required: ['q'],
          properties: {
            q: { type: 'string', minLength: 2 },
            limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
          },
        },
      },
    },
    async (request, reply) => {
      const { q, limit } = request.query as { q: string; limit?: number };

      const users = await utilityService.searchUsers(q, limit);
      return reply.send({ users });
    }
  );

  // Generate password reset for user
  server.post(
    '/admin/users/:userId/password-reset',
    {
      schema: {
        tags: ['admin'],
        summary: 'Generate password reset for user',
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          properties: {
            userId: { type: 'string', format: 'uuid' },
          },
        },
        response: {
          200: {
            description: 'Password reset generated',
            type: 'object',
            properties: {
              token: { type: 'string' },
              resetUrl: { type: 'string' },
              expiresAt: { type: 'string', format: 'date-time' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { userId } = request.params as { userId: string };

      // Only super_admin can generate password resets
      if (request.user.adminProfile?.adminLevel !== 'super_admin') {
        return reply.code(403).send({
          type: 'forbidden',
          title: 'Insufficient Permissions',
          detail: 'Only super admins can generate password resets',
        });
      }

      try {
        const result = await utilityService.generatePasswordResetForUser(
          request.user.adminProfile.id,
          userId
        );

        return reply.send(result);
      } catch (error) {
        if (error instanceof Error) {
          return reply.code(400).send({
            type: 'invalid_request',
            title: 'Failed',
            detail: error.message,
          });
        }
        throw error;
      }
    }
  );

  // Clear venue requests
  server.post(
    '/admin/venues/:venueId/clear-requests',
    {
      schema: {
        tags: ['admin'],
        summary: 'Clear all venue requests',
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          properties: {
            venueId: { type: 'string', format: 'uuid' },
          },
        },
        body: {
          type: 'object',
          properties: {
            markAsProcessed: { type: 'boolean', default: true },
          },
        },
        response: {
          200: {
            description: 'Requests cleared',
            type: 'object',
            properties: {
              clearedCount: { type: 'integer' },
              venueName: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { venueId } = request.params as { venueId: string };
      const { markAsProcessed } = ClearVenueRequestsSchema.parse(request.body);

      try {
        const result = await utilityService.clearVenueRequests(
          request.user.adminProfile!.id,
          venueId,
          markAsProcessed
        );

        return reply.send(result);
      } catch (error) {
        if (error instanceof Error) {
          return reply.code(400).send({
            type: 'invalid_request',
            title: 'Failed',
            detail: error.message,
          });
        }
        throw error;
      }
    }
  );

  // Create delegated access session
  server.post(
    '/admin/delegated-access',
    {
      schema: {
        tags: ['admin'],
        summary: 'Create delegated access session',
        description: 'Allows support to operate as a customer or singer',
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['targetUserId', 'contextType'],
          properties: {
            targetUserId: { type: 'string', format: 'uuid' },
            contextType: { type: 'string', enum: ['customer', 'singer'] },
            durationHours: { type: 'integer', minimum: 1, maximum: 24, default: 4 },
          },
        },
        response: {
          201: {
            description: 'Delegated session created',
            type: 'object',
            properties: {
              id: { type: 'string' },
              sessionToken: { type: 'string' },
              targetUserId: { type: 'string' },
              targetContextType: { type: 'string' },
              targetContextId: { type: 'string' },
              expiresAt: { type: 'string', format: 'date-time' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const data = CreateDelegatedSessionSchema.parse(request.body);

      try {
        const session = await delegatedService.createDelegatedSession(
          request.user.adminProfile!.id,
          data.targetUserId,
          data.contextType,
          data.durationHours
        );

        return reply.code(201).send(session);
      } catch (error) {
        if (error instanceof Error) {
          return reply.code(400).send({
            type: 'invalid_request',
            title: 'Failed',
            detail: error.message,
          });
        }
        throw error;
      }
    }
  );

  // List active delegated sessions
  server.get(
    '/admin/delegated-access',
    {
      schema: {
        tags: ['admin'],
        summary: 'List active delegated access sessions',
        security: [{ bearerAuth: [] }],
        response: {
          200: {
            description: 'List of active sessions',
            type: 'object',
            properties: {
              sessions: {
                type: 'array',
                items: { type: 'object' },
              },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const sessions = await delegatedService.listActiveSessions();
      return reply.send({ sessions });
    }
  );

  // Revoke delegated session
  server.delete(
    '/admin/delegated-access/:sessionId',
    {
      schema: {
        tags: ['admin'],
        summary: 'Revoke delegated access session',
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          properties: {
            sessionId: { type: 'string', format: 'uuid' },
          },
        },
        response: {
          204: { description: 'Session revoked' },
        },
      },
    },
    async (request, reply) => {
      const { sessionId } = request.params as { sessionId: string };

      try {
        await delegatedService.revokeDelegatedSession(
          sessionId,
          request.user.adminProfile!.id
        );

        return reply.code(204).send();
      } catch (error) {
        if (error instanceof Error) {
          return reply.code(400).send({
            type: 'invalid_request',
            title: 'Failed',
            detail: error.message,
          });
        }
        throw error;
      }
    }
  );

  // Get admin audit log
  server.get(
    '/admin/audit-log',
    {
      schema: {
        tags: ['admin'],
        summary: 'Get admin audit log',
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          properties: {
            adminProfileId: { type: 'string', format: 'uuid' },
            action: { type: 'string' },
            targetType: { type: 'string' },
            limit: { type: 'integer', minimum: 1, maximum: 100, default: 50 },
            offset: { type: 'integer', minimum: 0, default: 0 },
          },
        },
      },
    },
    async (request, reply) => {
      const options = request.query as {
        adminProfileId?: string;
        action?: string;
        targetType?: string;
        limit?: number;
        offset?: number;
      };

      const result = await utilityService.getAdminAuditLog(options);
      return reply.send(result);
    }
  );
};

export default adminUtilityRoutes;
```

---

## Phase 16: Analytics & Reporting

**Objective**: Build comprehensive analytics and reporting system leveraging processed request history data to provide insights for both admins and customers (as paid add-on feature).

### 16.1 Analytics Database Views and Functions

```sql
-- Migration: 016_analytics_reporting.sql

-- Create materialized view for daily request statistics
CREATE MATERIALIZED VIEW daily_request_stats AS
SELECT
  DATE(requested_at) AS date,
  v.customer_profile_id,
  v.id AS venue_id,
  v.name AS venue_name,
  COUNT(*) AS total_requests,
  COUNT(*) FILTER (WHERE processed = true) AS processed_requests,
  COUNT(DISTINCT singer_profile_id) AS unique_singers,
  COUNT(DISTINCT artist) AS unique_artists,
  COUNT(DISTINCT title) AS unique_songs
FROM requests r
JOIN venues v ON r.venue_id = v.id
GROUP BY DATE(requested_at), v.customer_profile_id, v.id, v.name;

CREATE UNIQUE INDEX idx_daily_stats_unique 
  ON daily_request_stats(date, customer_profile_id, venue_id);
CREATE INDEX idx_daily_stats_customer 
  ON daily_request_stats(customer_profile_id, date DESC);
CREATE INDEX idx_daily_stats_venue 
  ON daily_request_stats(venue_id, date DESC);

-- Refresh policy: Run daily at 1 AM UTC
COMMENT ON MATERIALIZED VIEW daily_request_stats IS 
  'Daily aggregated request statistics by venue. Refresh nightly via cron job.';

-- Song popularity aggregation
CREATE MATERIALIZED VIEW song_popularity_stats AS
SELECT
  r.artist,
  r.title,
  LOWER(r.artist || ' - ' || r.title) AS normalized_song,
  v.customer_profile_id,
  v.id AS venue_id,
  COUNT(*) AS request_count,
  COUNT(DISTINCT singer_profile_id) AS unique_requesters,
  COUNT(*) FILTER (WHERE processed = true) AS times_performed,
  MAX(requested_at) AS last_requested_at,
  MIN(requested_at) AS first_requested_at
FROM requests r
JOIN venues v ON r.venue_id = v.id
WHERE processed = true
GROUP BY r.artist, r.title, LOWER(r.artist || ' - ' || r.title), v.customer_profile_id, v.id;

CREATE INDEX idx_song_popularity_customer 
  ON song_popularity_stats(customer_profile_id, request_count DESC);
CREATE INDEX idx_song_popularity_venue 
  ON song_popularity_stats(venue_id, request_count DESC);
CREATE INDEX idx_song_popularity_normalized 
  ON song_popularity_stats(normalized_song, customer_profile_id);

-- Singer activity stats
CREATE MATERIALIZED VIEW singer_activity_stats AS
SELECT
  su.id AS singer_user_id,
  su.name AS singer_name,
  su.email AS singer_email,
  v.customer_profile_id,
  v.id AS venue_id,
  v.name AS venue_name,
  COUNT(*) AS total_requests,
  COUNT(*) FILTER (WHERE processed = true) AS requests_performed,
  COUNT(DISTINCT DATE(requested_at)) AS days_active,
  MAX(requested_at) AS last_request_at,
  MIN(requested_at) AS first_request_at
FROM requests r
JOIN singer_users su ON r.singer_profile_id = su.id
JOIN venues v ON r.venue_id = v.id
GROUP BY su.id, su.name, su.email, v.customer_profile_id, v.id, v.name;

CREATE INDEX idx_singer_activity_customer 
  ON singer_activity_stats(customer_profile_id, total_requests DESC);
CREATE INDEX idx_singer_activity_venue 
  ON singer_activity_stats(venue_id, total_requests DESC);
CREATE INDEX idx_singer_activity_singer 
  ON singer_activity_stats(singer_user_id, customer_profile_id);

-- Saved custom reports table
CREATE TABLE saved_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_profile_id UUID NOT NULL REFERENCES customer_profiles(id) ON DELETE CASCADE,
  created_by_user_id UUID NOT NULL REFERENCES singr_users(id) ON DELETE CASCADE,
  name VARCHAR(200) NOT NULL,
  description TEXT,
  report_type VARCHAR(50) NOT NULL, -- 'song_popularity', 'singer_activity', 'daily_stats', 'custom'
  filters JSONB DEFAULT '{}',
  columns JSONB DEFAULT '[]',
  sort_by JSONB DEFAULT '[]',
  is_public BOOLEAN DEFAULT false,
  schedule_cron VARCHAR(100), -- Optional: cron expression for scheduled reports
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_saved_reports_customer 
  ON saved_reports(customer_profile_id, created_at DESC);
CREATE INDEX idx_saved_reports_creator 
  ON saved_reports(created_by_user_id);
CREATE INDEX idx_saved_reports_type 
  ON saved_reports(report_type);

-- Report execution log
CREATE TABLE report_executions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  saved_report_id UUID REFERENCES saved_reports(id) ON DELETE SET NULL,
  executed_by_user_id UUID REFERENCES singr_users(id) ON DELETE SET NULL,
  report_type VARCHAR(50) NOT NULL,
  filters JSONB DEFAULT '{}',
  format VARCHAR(20) NOT NULL, -- 'json', 'csv', 'xlsx', 'pdf'
  row_count INTEGER,
  execution_time_ms INTEGER,
  file_url TEXT,
  file_size_bytes BIGINT,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_report_executions_saved_report 
  ON report_executions(saved_report_id, created_at DESC);
CREATE INDEX idx_report_executions_user 
  ON report_executions(executed_by_user_id, created_at DESC);
CREATE INDEX idx_report_executions_expires 
  ON report_executions(expires_at) 
  WHERE expires_at IS NOT NULL;

-- Trigger for updated_at
CREATE TRIGGER update_saved_reports_updated_at
  BEFORE UPDATE ON saved_reports
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to refresh all materialized views
CREATE OR REPLACE FUNCTION refresh_analytics_views()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY daily_request_stats;
  REFRESH MATERIALIZED VIEW CONCURRENTLY song_popularity_stats;
  REFRESH MATERIALIZED VIEW CONCURRENTLY singer_activity_stats;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION refresh_analytics_views IS 
  'Refresh all analytics materialized views. Schedule to run daily at 1 AM UTC.';

-- Platform-wide analytics (admin only)
CREATE MATERIALIZED VIEW platform_analytics AS
SELECT
  COUNT(DISTINCT cp.id) AS total_customers,
  COUNT(DISTINCT cp.id) FILTER (
    WHERE EXISTS (
      SELECT 1 FROM subscriptions s 
      WHERE s.customer_profile_id = cp.id 
      AND s.status IN ('active', 'trialing')
    )
  ) AS active_customers,
  COUNT(DISTINCT v.id) AS total_venues,
  COUNT(DISTINCT su.id) AS total_singers,
  COUNT(r.request_id) AS total_requests,
  COUNT(r.request_id) FILTER (WHERE r.processed = true) AS total_processed,
  COUNT(r.request_id) FILTER (
    WHERE r.requested_at >= CURRENT_DATE
  ) AS requests_today,
  COUNT(r.request_id) FILTER (
    WHERE r.requested_at >= DATE_TRUNC('month', CURRENT_DATE)
  ) AS requests_this_month
FROM customer_profiles cp
LEFT JOIN venues v ON v.customer_profile_id = cp.id
LEFT JOIN requests r ON r.venue_id = v.id
LEFT JOIN singer_users su ON r.singer_profile_id = su.id;

CREATE UNIQUE INDEX idx_platform_analytics_single_row 
  ON platform_analytics ((1));

COMMENT ON MATERIALIZED VIEW platform_analytics IS 
  'Platform-wide statistics for admin dashboard. Refresh hourly.';
```

### 16.2 Analytics Service

```typescript
// src/services/analytics-service.ts

import { PrismaClient } from '@prisma/client';
import { logger } from '../lib/logger';
import * as XLSX from 'xlsx';
import PDFDocument from 'pdfkit';
import { Parser } from 'json2csv';
import { createWriteStream } from 'fs';
import { join } from 'path';
import { randomBytes } from 'crypto';

export interface ReportFilters {
  venueId?: string;
  startDate?: Date;
  endDate?: Date;
  limit?: number;
  offset?: number;
}

export interface CustomReportConfig {
  name: string;
  description?: string;
  reportType: 'song_popularity' | 'singer_activity' | 'daily_stats' | 'custom';
  filters: ReportFilters;
  columns?: string[];
  sortBy?: Array<{ field: string; direction: 'asc' | 'desc' }>;
}

export class AnalyticsService {
  constructor(private prisma: PrismaClient) {}

  /**
   * Get daily request statistics
   */
  async getDailyStats(
    customerProfileId: string,
    filters: ReportFilters = {}
  ) {
    const { venueId, startDate, endDate, limit = 30, offset = 0 } = filters;

    const where: any = {
      customerProfileId,
    };

    if (venueId) {
      where.venueId = venueId;
    }

    if (startDate || endDate) {
      where.date = {};
      if (startDate) {
        where.date.gte = startDate;
      }
      if (endDate) {
        where.date.lte = endDate;
      }
    }

    const [stats, total] = await Promise.all([
      this.prisma.$queryRaw`
        SELECT * FROM daily_request_stats
        WHERE customer_profile_id = ${customerProfileId}::uuid
        ${venueId ? this.prisma.$queryRaw`AND venue_id = ${venueId}::uuid` : this.prisma.$queryRaw``}
        ${startDate ? this.prisma.$queryRaw`AND date >= ${startDate}::date` : this.prisma.$queryRaw``}
        ${endDate ? this.prisma.$queryRaw`AND date <= ${endDate}::date` : this.prisma.$queryRaw``}
        ORDER BY date DESC
        LIMIT ${limit}
        OFFSET ${offset}
      `,
      this.prisma.$queryRaw<[{ count: bigint }]>`
        SELECT COUNT(*) as count FROM daily_request_stats
        WHERE customer_profile_id = ${customerProfileId}::uuid
        ${venueId ? this.prisma.$queryRaw`AND venue_id = ${venueId}::uuid` : this.prisma.$queryRaw``}
        ${startDate ? this.prisma.$queryRaw`AND date >= ${startDate}::date` : this.prisma.$queryRaw``}
        ${endDate ? this.prisma.$queryRaw`AND date <= ${endDate}::date` : this.prisma.$queryRaw``}
      `,
    ]);

    return {
      stats,
      pagination: {
        total: Number(total[0].count),
        limit,
        offset,
        hasMore: offset + limit < Number(total[0].count),
      },
    };
  }

  /**
   * Get top songs by request count
   */
  async getTopSongs(
    customerProfileId: string,
    filters: ReportFilters & { venueId?: string } = {}
  ) {
    const { venueId, startDate, endDate, limit = 50 } = filters;

    let query = `
      SELECT
        artist,
        title,
        normalized_song,
        venue_id,
        venue_name,
        request_count,
        unique_requesters,
        times_performed,
        last_requested_at,
        first_requested_at
      FROM song_popularity_stats
      WHERE customer_profile_id = $1
    `;

    const params: any[] = [customerProfileId];
    let paramIndex = 2;

    if (venueId) {
      query += ` AND venue_id = $${paramIndex}`;
      params.push(venueId);
      paramIndex++;
    }

    if (startDate) {
      query += ` AND last_requested_at >= $${paramIndex}`;
      params.push(startDate);
      paramIndex++;
    }

    if (endDate) {
      query += ` AND last_requested_at <= $${paramIndex}`;
      params.push(endDate);
      paramIndex++;
    }

    query += ` ORDER BY request_count DESC LIMIT $${paramIndex}`;
    params.push(limit);

    const songs = await this.prisma.$queryRawUnsafe(query, ...params);

    return songs;
  }

  /**
   * Get most active singers
   */
  async getTopSingers(
    customerProfileId: string,
    filters: ReportFilters & { venueId?: string } = {}
  ) {
    const { venueId, startDate, endDate, limit = 50 } = filters;

    let query = `
      SELECT
        singer_user_id,
        singer_name,
        singer_email,
        venue_id,
        venue_name,
        total_requests,
        requests_performed,
        days_active,
        last_request_at,
        first_request_at
      FROM singer_activity_stats
      WHERE customer_profile_id = $1
    `;

    const params: any[] = [customerProfileId];
    let paramIndex = 2;

    if (venueId) {
      query += ` AND venue_id = $${paramIndex}`;
      params.push(venueId);
      paramIndex++;
    }

    if (startDate) {
      query += ` AND last_request_at >= $${paramIndex}`;
      params.push(startDate);
      paramIndex++;
    }

    if (endDate) {
      query += ` AND last_request_at <= $${paramIndex}`;
      params.push(endDate);
      paramIndex++;
    }

    query += ` ORDER BY total_requests DESC LIMIT $${paramIndex}`;
    params.push(limit);

    const singers = await this.prisma.$queryRawUnsafe(query, ...params);

    return singers;
  }

  /**
   * Get venue comparison statistics
   */
  async getVenueComparison(
    customerProfileId: string,
    filters: { startDate?: Date; endDate?: Date } = {}
  ) {
    const { startDate, endDate } = filters;

    let query = `
      SELECT
        venue_id,
        venue_name,
        SUM(total_requests) as total_requests,
        SUM(processed_requests) as processed_requests,
        AVG(unique_singers) as avg_unique_singers,
        MAX(date) as last_activity_date,
        MIN(date) as first_activity_date,
        COUNT(*) as days_with_activity
      FROM daily_request_stats
      WHERE customer_profile_id = $1
    `;

    const params: any[] = [customerProfileId];
    let paramIndex = 2;

    if (startDate) {
      query += ` AND date >= $${paramIndex}`;
      params.push(startDate);
      paramIndex++;
    }

    if (endDate) {
      query += ` AND date <= $${paramIndex}`;
      params.push(endDate);
      paramIndex++;
    }

    query += ` GROUP BY venue_id, venue_name ORDER BY total_requests DESC`;

    const venues = await this.prisma.$queryRawUnsafe(query, ...params);

    return venues;
  }

  /**
   * Get platform analytics (admin only)
   */
  async getPlatformAnalytics() {
    const stats = await this.prisma.$queryRaw`
      SELECT * FROM platform_analytics
    `;

    // Get top customers by request volume
    const topCustomers = await this.prisma.$queryRaw`
      SELECT
        cp.id,
        cp.business_name,
        su.email,
        COUNT(DISTINCT v.id) as venue_count,
        COUNT(r.request_id) as total_requests,
        COUNT(DISTINCT DATE(r.requested_at)) as active_days
      FROM customer_profiles cp
      JOIN singr_users su ON cp.singr_user_id = su.id
      LEFT JOIN venues v ON v.customer_profile_id = cp.id
      LEFT JOIN requests r ON r.venue_id = v.id
      WHERE EXISTS (
        SELECT 1 FROM subscriptions s
        WHERE s.customer_profile_id = cp.id
        AND s.status IN ('active', 'trialing')
      )
      GROUP BY cp.id, cp.business_name, su.email
      ORDER BY total_requests DESC
      LIMIT 20
    `;

    // Get most popular songs across platform
    const topPlatformSongs = await this.prisma.$queryRaw`
      SELECT
        artist,
        title,
        SUM(request_count) as total_requests,
        COUNT(DISTINCT customer_profile_id) as customer_count,
        COUNT(DISTINCT venue_id) as venue_count
      FROM song_popularity_stats
      GROUP BY artist, title
      ORDER BY total_requests DESC
      LIMIT 50
    `;

    return {
      overview: stats,
      topCustomers,
      topPlatformSongs,
    };
  }

  /**
   * Save custom report configuration
   */
  async saveReport(
    customerProfileId: string,
    createdByUserId: string,
    config: CustomReportConfig
  ) {
    const report = await this.prisma.savedReport.create({
      data: {
        customerProfileId,
        createdByUserId,
        name: config.name,
        description: config.description,
        reportType: config.reportType,
        filters: config.filters as any,
        columns: config.columns || [],
        sortBy: config.sortBy || [],
      },
    });

    logger.info('Custom report saved', {
      reportId: report.id,
      customerProfileId,
      reportType: config.reportType,
    });

    return report;
  }

  /**
   * Get saved reports
   */
  async getSavedReports(customerProfileId: string) {
    const reports = await this.prisma.savedReport.findMany({
      where: { customerProfileId },
      include: {
        createdByUser: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return reports;
  }

  /**
   * Execute saved report
   */
  async executeReport(
    reportId: string,
    executedByUserId: string,
    format: 'json' | 'csv' | 'xlsx' | 'pdf' = 'json'
  ) {
    const report = await this.prisma.savedReport.findUnique({
      where: { id: reportId },
    });

    if (!report) {
      throw new Error('Report not found');
    }

    const startTime = Date.now();

    // Fetch data based on report type
    let data: any[];

    switch (report.reportType) {
      case 'song_popularity':
        data = await this.getTopSongs(
          report.customerProfileId,
          report.filters as any
        );
        break;

      case 'singer_activity':
        data = await this.getTopSingers(
          report.customerProfileId,
          report.filters as any
        );
        break;

      case 'daily_stats':
        const result = await this.getDailyStats(
          report.customerProfileId,
          report.filters as any
        );
        data = result.stats;
        break;

      default:
        throw new Error('Unsupported report type');
    }

    const executionTime = Date.now() - startTime;

    // Generate file based on format
    let fileUrl: string | null = null;
    let fileSize: number | null = null;

    if (format !== 'json') {
      const result = await this.generateReportFile(
        data,
        format,
        report.name
      );
      fileUrl = result.url;
      fileSize = result.size;
    }

    // Log execution
    const execution = await this.prisma.reportExecution.create({
      data: {
        savedReportId: reportId,
        executedByUserId,
        reportType: report.reportType,
        filters: report.filters as any,
        format,
        rowCount: data.length,
        executionTimeMs: executionTime,
        fileUrl,
        fileSizeBytes: fileSize ? BigInt(fileSize) : null,
        expiresAt: fileUrl
          ? new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days
          : null,
      },
    });

    logger.info('Report executed', {
      reportId,
      executionId: execution.id,
      format,
      rowCount: data.length,
      executionTimeMs: executionTime,
    });

    return {
      executionId: execution.id,
      data: format === 'json' ? data : null,
      fileUrl,
      fileSize,
      rowCount: data.length,
      executionTime,
    };
  }

  /**
   * Generate report file in requested format
   */
  private async generateReportFile(
    data: any[],
    format: 'csv' | 'xlsx' | 'pdf',
    reportName: string
  ): Promise<{ url: string; size: number }> {
    const uploadDir = process.env.UPLOAD_DIR || './uploads/reports';
    const filename = `${reportName.replace(/[^a-zA-Z0-9]/g, '_')}_${Date.now()}.${format}`;
    const filepath = join(uploadDir, filename);

    switch (format) {
      case 'csv': {
        const parser = new Parser();
        const csv = parser.parse(data);
        await this.writeFile(filepath, csv);
        break;
      }

      case 'xlsx': {
        const worksheet = XLSX.utils.json_to_sheet(data);
        const workbook = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(workbook, worksheet, 'Report');
        XLSX.writeFile(workbook, filepath);
        break;
      }

      case 'pdf': {
        await this.generatePDF(data, filepath, reportName);
        break;
      }
    }

    const stats = await this.getFileStats(filepath);

    return {
      url: `/uploads/reports/${filename}`,
      size: stats.size,
    };
  }

  /**
   * Generate PDF report
   */
  private async generatePDF(
    data: any[],
    filepath: string,
    reportName: string
  ): Promise<void> {
    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ margin: 50 });
      const stream = createWriteStream(filepath);

      doc.pipe(stream);

      // Header
      doc
        .fontSize(20)
        .text(reportName, { align: 'center' })
        .moveDown();

      doc
        .fontSize(10)
        .text(`Generated: ${new Date().toLocaleString()}`, { align: 'center' })
        .moveDown(2);

      // Table
      if (data.length > 0) {
        const headers = Object.keys(data[0]);
        const columnWidth = (doc.page.width - 100) / headers.length;

        // Headers
        doc.fontSize(8).font('Helvetica-Bold');
        headers.forEach((header, i) => {
          doc.text(
            header,
            50 + i * columnWidth,
            doc.y,
            { width: columnWidth, continued: i < headers.length - 1 }
          );
        });
        doc.moveDown();

        // Rows
        doc.font('Helvetica');
        data.slice(0, 50).forEach((row) => {
          const y = doc.y;
          headers.forEach((header, i) => {
            const value = row[header]?.toString() || '';
            doc.text(
              value.substring(0, 30),
              50 + i * columnWidth,
              y,
              { width: columnWidth, continued: i < headers.length - 1 }
            );
          });
          doc.moveDown(0.5);

          if (doc.y > doc.page.height - 100) {
            doc.addPage();
          }
        });

        if (data.length > 50) {
          doc
            .moveDown()
            .text(
              `... and ${data.length - 50} more rows. Download full data as CSV or XLSX.`,
              { align: 'center' }
            );
        }
      } else {
        doc.text('No data available for this report.', { align: 'center' });
      }

      doc.end();

      stream.on('finish', resolve);
      stream.on('error', reject);
    });
  }

  /**
   * Helper to write file
   */
  private writeFile(filepath: string, content: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const stream = createWriteStream(filepath);
      stream.write(content);
      stream.end();
      stream.on('finish', resolve);
      stream.on('error', reject);
    });
  }

  /**
   * Helper to get file stats
   */
  private async getFileStats(filepath: string): Promise<{ size: number }> {
    const fs = await import('fs/promises');
    const stats = await fs.stat(filepath);
    return { size: stats.size };
  }

  /**
   * Delete old report files
   */
  async cleanupExpiredReports() {
    const expired = await this.prisma.reportExecution.findMany({
      where: {
        fileUrl: { not: null },
        expiresAt: { lt: new Date() },
      },
    });

    let deletedCount = 0;

    for (const execution of expired) {
      if (execution.fileUrl) {
        try {
          const filepath = join(
            process.env.UPLOAD_DIR || './uploads/reports',
            execution.fileUrl.split('/').pop()!
          );
          const fs = await import('fs/promises');
          await fs.unlink(filepath);
          deletedCount++;
        } catch (error) {
          logger.warn('Failed to delete expired report file', {
            executionId: execution.id,
            fileUrl: execution.fileUrl,
            error,
          });
        }
      }
    }

    // Mark as cleaned up
    await this.prisma.reportExecution.updateMany({
      where: {
        id: { in: expired.map((e) => e.id) },
      },
      data: {
        fileUrl: null,
      },
    });

    logger.info('Cleaned up expired report files', { deletedCount });

    return deletedCount;
  }

  /**
   * Refresh materialized views
   */
  async refreshViews() {
    await this.prisma.$executeRaw`SELECT refresh_analytics_views()`;
    logger.info('Analytics materialized views refreshed');
  }
}
```

### 16.3 Analytics Routes

```typescript
// src/routes/v1/customer/analytics.ts

import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { AnalyticsService } from '../../../services/analytics-service';

const ReportFiltersSchema = z.object({
  venueId: z.string().uuid().optional(),
  startDate: z.coerce.date().optional(),
  endDate: z.coerce.date().optional(),
  limit: z.coerce.number().int().min(1).max(500).optional(),
  offset: z.coerce.number().int().min(0).optional(),
});

const SaveReportSchema = z.object({
  name: z.string().min(1).max(200),
  description: z.string().max(1000).optional(),
  reportType: z.enum(['song_popularity', 'singer_activity', 'daily_stats', 'custom']),
  filters: z.object({
    venueId: z.string().uuid().optional(),
    startDate: z.coerce.date().optional(),
    endDate: z.coerce.date().optional(),
  }),
  columns: z.array(z.string()).optional(),
  sortBy: z
    .array(
      z.object({
        field: z.string(),
        direction: z.enum(['asc', 'desc']),
      })
    )
    .optional(),
});

const analyticsRoutes: FastifyPluginAsync = async (server) => {
  const analyticsService = new AnalyticsService(server.prisma);

  // All routes require authentication and customer context
  server.addHook('preHandler', server.authenticate);

  // Check for analytics feature access (could be premium feature)
  const checkAnalyticsAccess = async (request: any, reply: any) => {
    const customerProfileId = request.user.activeContext?.id;

    if (!customerProfileId || request.user.activeContext?.type !== 'customer') {
      return reply.code(403).send({
        type: 'authorization_denied',
        title: 'Customer Context Required',
      });
    }

    // TODO: Check if customer has analytics feature enabled
    // For now, require active subscription
    const hasActiveSubscription = await server.prisma.subscription.findFirst({
      where: {
        customerProfileId,
        status: { in: ['active', 'trialing'] },
      },
    });

    if (!hasActiveSubscription) {
      return reply.code(403).send({
        type: 'feature_not_available',
        title: 'Analytics Feature Not Available',
        detail: 'Analytics requires an active subscription',
      });
    }
  };

  server.addHook('preHandler', checkAnalyticsAccess);

  // Get daily statistics
  server.get(
    '/analytics/daily-stats',
    {
      schema: {
        tags: ['analytics'],
        summary: 'Get daily request statistics',
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          properties: {
            venueId: { type: 'string', format: 'uuid' },
            startDate: { type: 'string', format: 'date' },
            endDate: { type: 'string', format: 'date' },
            limit: { type: 'integer', minimum: 1, maximum: 500, default: 30 },
            offset: { type: 'integer', minimum: 0, default: 0 },
          },
        },
      },
    },
    async (request, reply) => {
      const customerProfileId = request.user.activeContext!.id;
      const filters = ReportFiltersSchema.parse(request.query);

      const result = await analyticsService.getDailyStats(customerProfileId, filters);

      return reply.send(result);
    }
  );

  // Get top songs
  server.get(
    '/analytics/top-songs',
    {
      schema: {
        tags: ['analytics'],
        summary: 'Get most requested songs',
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          properties: {
            venueId: { type: 'string', format: 'uuid' },
            startDate: { type: 'string', format: 'date' },
            endDate: { type: 'string', format: 'date' },
            limit: { type: 'integer', minimum: 1, maximum: 500, default: 50 },
          },
        },
      },
    },
    async (request, reply) => {
      const customerProfileId = request.user.activeContext!.id;
      const filters = ReportFiltersSchema.parse(request.query);

      const songs = await analyticsService.getTopSongs(customerProfileId, filters);

      return reply.send({ songs });
    }
  );

  // Get top singers
  server.get(
    '/analytics/top-singers',
    {
      schema: {
        tags: ['analytics'],
        summary: 'Get most active singers',
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          properties: {
            venueId: { type: 'string', format: 'uuid' },
            startDate: { type: 'string', format: 'date' },
            endDate: { type: 'string', format: 'date' },
            limit: { type: 'integer', minimum: 1, maximum: 500, default: 50 },
          },
        },
      },
    },
    async (request, reply) => {
      const customerProfileId = request.user.activeContext!.id;
      const filters = ReportFiltersSchema.parse(request.query);

      const singers = await analyticsService.getTopSingers(customerProfileId, filters);

      return reply.send({ singers });
    }
  );

  // Get venue comparison
  server.get(
    '/analytics/venue-comparison',
    {
      schema: {
        tags: ['analytics'],
        summary: 'Compare venue performance',
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          properties: {
            startDate: { type: 'string', format: 'date' },
            endDate: { type: 'string', format: 'date' },
          },
        },
      },
    },
    async (request, reply) => {
      const customerProfileId = request.user.activeContext!.id;
      const { startDate, endDate } = request.query as {
        startDate?: Date;
        endDate?: Date;
      };

      const venues = await analyticsService.getVenueComparison(customerProfileId, {
        startDate,
        endDate,
      });

      return reply.send({ venues });
    }
  );

  // Save custom report
  server.post(
    '/analytics/reports',
    {
      schema: {
        tags: ['analytics'],
        summary: 'Save custom report configuration',
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['name', 'reportType', 'filters'],
          properties: {
            name: { type: 'string', minLength: 1, maxLength: 200 },
            description: { type: 'string', maxLength: 1000 },
            reportType: {
              type: 'string',
              enum: ['song_popularity', 'singer_activity', 'daily_stats', 'custom'],
            },
            filters: { type: 'object' },
            columns: { type: 'array', items: { type: 'string' } },
            sortBy: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  field: { type: 'string' },
                  direction: { type: 'string', enum: ['asc', 'desc'] },
                },
              },
            },
          },
        },
        response: {
          201: {
            description: 'Report saved',
            type: 'object',
            properties: {
              id: { type: 'string' },
              name: { type: 'string' },
              reportType: { type: 'string' },
              createdAt: { type: 'string', format: 'date-time' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const customerProfileId = request.user.activeContext!.id;
      const config = SaveReportSchema.parse(request.body);

      const report = await analyticsService.saveReport(
        customerProfileId,
        request.user.id,
        config
      );

      return reply.code(201).send({
        id: report.id,
        name: report.name,
        reportType: report.reportType,
        createdAt: report.createdAt,
      });
    }
  );

  // Get saved reports
  server.get(
    '/analytics/reports',
    {
      schema: {
        tags: ['analytics'],
        summary: 'Get saved custom reports',
        security: [{ bearerAuth: [] }],
      },
    },
    async (request, reply) => {
      const customerProfileId = request.user.activeContext!.id;

      const reports = await analyticsService.getSavedReports(customerProfileId);

      return reply.send({ reports });
    }
  );

  // Execute saved report
  server.post(
    '/analytics/reports/:reportId/execute',
    {
      schema: {
        tags: ['analytics'],
        summary: 'Execute saved report',
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          properties: {
            reportId: { type: 'string', format: 'uuid' },
          },
        },
        querystring: {
          type: 'object',
          properties: {
            format: {
              type: 'string',
              enum: ['json', 'csv', 'xlsx', 'pdf'],
              default: 'json',
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { reportId } = request.params as { reportId: string };
      const { format = 'json' } = request.query as { format?: 'json' | 'csv' | 'xlsx' | 'pdf' };

      const result = await analyticsService.executeReport(
        reportId,
        request.user.id,
        format
      );

      return reply.send(result);
    }
  );
};

export default analyticsRoutes;
```

---

## Phase 17: Testing, Documentation & Deployment

**Objective**: Implement comprehensive testing, generate API documentation, and prepare for production deployment.

### 17.1 Testing Strategy

```typescript
// package.json - Add test dependencies
{
  "devDependencies": {
    "@types/jest": "^29.5.0",
    "@types/supertest": "^6.0.0",
    "jest": "^29.7.0",
    "supertest": "^6.3.3",
    "ts-jest": "^29.1.0"
  },
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:integration": "jest --testPathPattern=integration",
    "test:unit": "jest --testPathPattern=unit"
  }
}
```

```typescript
// jest.config.js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src', '<rootDir>/tests'],
  testMatch: ['**/__tests__/**/*.ts', '**/*.test.ts', '**/*.spec.ts'],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/**/__tests__/**',
  ],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70,
    },
  },
  setupFilesAfterEnv: ['<rootDir>/tests/setup.ts'],
};
```

```typescript
// tests/setup.ts
// Global test setup

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

beforeAll(async () => {
  // Setup test database
  await prisma.$connect();
});

afterAll(async () => {
  // Cleanup
  await prisma.$disconnect();
});

afterEach(async () => {
  // Clear test data between tests
  const tables = [
    'requests',
    'venues',
    'systems',
    'songdb',
    'api_keys',
    'subscriptions',
    'organization_users',
  ];

  for (const table of tables) {
    await prisma.$executeRawUnsafe(`TRUNCATE TABLE ${table} CASCADE`);
  }
});
```

```typescript
// tests/unit/services/venue-service.test.ts

import { VenueService } from '../../../src/services/venue-service';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const venueService = new VenueService(prisma);

describe('VenueService', () => {
  describe('createVenue', () => {
    it('should create a venue with valid data', async () => {
      const customerProfileId = 'test-customer-id';
      const data = {
        name: 'Test Venue',
        urlName: 'test-venue',
        address: '123 Main St',
        city: 'Test City',
        state: 'TS',
        postalCode: '12345',
        acceptingRequests: true,
      };

      const venue = await venueService.createVenue(customerProfileId, data);

      expect(venue).toBeDefined();
      expect(venue.name).toBe(data.name);
      expect(venue.customerProfileId).toBe(customerProfileId);
    });

    it('should throw error for duplicate urlName', async () => {
      const customerProfileId = 'test-customer-id';
      const data = {
        name: 'Test Venue',
        urlName: 'duplicate',
        address: '123 Main St',
        city: 'Test City',
        state: 'TS',
        postalCode: '12345',
        acceptingRequests: true,
      };

      await venueService.createVenue(customerProfileId, data);

      await expect(
        venueService.createVenue(customerProfileId, data)
      ).rejects.toThrow();
    });
  });

  describe('updateVenue', () => {
    it('should update venue details', async () => {
      const customerProfileId = 'test-customer-id';
      const venue = await venueService.createVenue(customerProfileId, {
        name: 'Original Name',
        urlName: 'original',
        address: '123 Main St',
        city: 'Test City',
        state: 'TS',
        postalCode: '12345',
        acceptingRequests: true,
      });

      const updated = await venueService.updateVenue(
        venue.id,
        customerProfileId,
        { name: 'Updated Name' }
      );

      expect(updated.name).toBe('Updated Name');
    });

    it('should throw error for non-existent venue', async () => {
      await expect(
        venueService.updateVenue('fake-id', 'customer-id', { name: 'Test' })
      ).rejects.toThrow('Venue not found');
    });
  });
});
```

```typescript
// tests/integration/routes/venue-routes.test.ts

import supertest from 'supertest';
import { build } from '../../../src/app';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

describe('Venue Routes', () => {
  let app: any;
  let authToken: string;

  beforeAll(async () => {
    app = await build();
    await app.ready();

    // Create test user and get auth token
    const response = await supertest(app.server)
      .post('/v1/auth/signup')
      .send({
        email: 'test@example.com',
        password: 'Test123!@#',
        name: 'Test User',
      });

    authToken = response.body.token;
  });

  afterAll(async () => {
    await app.close();
  });

  describe('POST /v1/customer/venues', () => {
    it('should create a new venue', async () => {
      const response = await supertest(app.server)
        .post('/v1/customer/venues')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Test Venue',
          urlName: 'test-venue',
          address: '123 Main St',
          city: 'Test City',
          state: 'TS',
          postalCode: '12345',
          acceptingRequests: true,
        });

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('id');
      expect(response.body.name).toBe('Test Venue');
    });

    it('should return 400 for missing required fields', async () => {
      const response = await supertest(app.server)
        .post('/v1/customer/venues')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Test Venue',
        });

      expect(response.status).toBe(400);
    });

    it('should return 401 without auth token', async () => {
      const response = await supertest(app.server)
        .post('/v1/customer/venues')
        .send({
          name: 'Test Venue',
          urlName: 'test',
        });

      expect(response.status).toBe(401);
    });
  });

  describe('GET /v1/customer/venues', () => {
    it('should list customer venues', async () => {
      const response = await supertest(app.server)
        .get('/v1/customer/venues')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('venues');
      expect(Array.isArray(response.body.venues)).toBe(true);
    });
  });
});
```

### 17.2 API Documentation Generation

```typescript
// src/app.ts - Add Swagger/OpenAPI documentation

import fastify from 'fastify';
import fastifySwagger from '@fastify/swagger';
import fastifySwaggerUi from '@fastify/swagger-ui';

export async function build() {
  const server = fastify({
    logger: true,
  });

  // Register Swagger
  await server.register(fastifySwagger, {
    openapi: {
      info: {
        title: 'Singr Karaoke Connect API',
        description: 'Professional karaoke management platform API',
        version: '1.0.0',
        contact: {
          name: 'Singr Karaoke Support',
          email: 'support@singrkaraoke.com',
          url: 'https://singrkaraoke.com',
        },
      },
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server',
        },
        {
          url: 'https://api.singrkaraoke.com',
          description: 'Production server',
        },
      ],
      tags: [
        { name: 'auth', description: 'Authentication endpoints' },
        { name: 'customer', description: 'Customer management endpoints' },
        { name: 'singer', description: 'Singer endpoints' },
        { name: 'admin', description: 'Admin endpoints' },
        { name: 'public', description: 'Public endpoints' },
        { name: 'analytics', description: 'Analytics and reporting' },
        { name: 'request-interface', description: 'Request interface API' },
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT',
          },
        },
      },
    },
  });

  // Register Swagger UI
  await server.register(fastifySwaggerUi, {
    routePrefix: '/docs',
    uiConfig: {
      docExpansion: 'list',
      deepLinking: true,
    },
    staticCSP: true,
  });

  // Register routes
  // ... route registration

  return server;
}
```

### 17.3 Production Configuration

```typescript
// src/config/production.ts

export const productionConfig = {
  server: {
    host: '0.0.0.0',
    port: parseInt(process.env.PORT || '3000'),
    trustProxy: true,
  },

  database: {
    url: process.env.DATABASE_URL!,
    ssl: {
      rejectUnauthorized: true,
    },
    pool: {
      min: 2,
      max: 10,
    },
  },

  redis: {
    host: process.env.REDIS_HOST!,
    port: parseInt(process.env.REDIS_PORT || '6379'),
    password: process.env.REDIS_PASSWORD,
    tls: process.env.REDIS_TLS === 'true' ? {} : undefined,
  },

  cors: {
    origin: process.env.ALLOWED_ORIGINS?.split(',') || ['https://singrkaraoke.com'],
    credentials: true,
  },

  rateLimit: {
    global: {
      max: 100,
      timeWindow: '1 minute',
    },
    auth: {
      max: 5,
      timeWindow: '15 minutes',
    },
  },

  logging: {
    level: 'info',
    transport: {
      target: 'pino-pretty',
      options: {
        colorize: false,
        translateTime: 'SYS:standard',
      },
    },
  },

  security: {
    jwtSecret: process.env.JWT_SECRET!,
    jwtExpiresIn: '7d',
    bcryptRounds: 12,
  },

  monitoring: {
    sentryDsn: process.env.SENTRY_DSN,
    environment: 'production',
  },
};
```

### 17.4 Deployment Checklist

```markdown
# Production Deployment Checklist

## Pre-Deployment

### Database
- [ ] Run all migrations on production database
- [ ] Verify database backups are configured
- [ ] Create materialized views: `SELECT refresh_analytics_views()`
- [ ] Verify indexes are created
- [ ] Set up read replicas (if applicable)

### Environment Variables
- [ ] Set all required environment variables
- [ ] Verify Stripe keys (live mode)
- [ ] Configure Sentry DSN
- [ ] Set JWT secret (strong random value)
- [ ] Configure Redis connection
- [ ] Set allowed CORS origins
- [ ] Configure email provider credentials
- [ ] Set webhook secrets

### Security
- [ ] Enable SSL/TLS
- [ ] Configure security headers
- [ ] Set up rate limiting
- [ ] Enable CORS with proper origins
- [ ] Configure firewall rules
- [ ] Set up DDoS protection
- [ ] Enable audit logging

### Monitoring
- [ ] Set up Sentry error tracking
- [ ] Configure application performance monitoring (APM)
- [ ] Set up database query monitoring
- [ ] Configure uptime monitoring
- [ ] Set up log aggregation
- [ ] Create alerting rules

### Scheduled Jobs
- [ ] Set up cron job to refresh analytics views (daily at 1 AM UTC)
- [ ] Set up cron job to cleanup expired reports (daily)
- [ ] Set up cron job to cleanup expired delegated sessions (hourly)
- [ ] Configure BullMQ workers for background jobs

## Deployment

### Application
- [ ] Build production bundle: `npm run build`
- [ ] Run tests: `npm test`
- [ ] Verify OpenAPI documentation accessible at `/docs`
- [ ] Deploy to production environment
- [ ] Verify application starts successfully
- [ ] Check health endpoint: `GET /health`

### Infrastructure
- [ ] Configure load balancer
- [ ] Set up auto-scaling (if applicable)
- [ ] Configure CDN for static assets
- [ ] Set up backup strategy
- [ ] Configure disaster recovery plan

## Post-Deployment

### Verification
- [ ] Verify all API endpoints are accessible
- [ ] Test authentication flow
- [ ] Verify Stripe webhook delivery
- [ ] Test email delivery
- [ ] Verify Redis connectivity
- [ ] Check database connectivity
- [ ] Test rate limiting

### Monitoring
- [ ] Verify Sentry is receiving errors
- [ ] Check application logs
- [ ] Monitor database performance
- [ ] Monitor API response times
- [ ] Check scheduled job execution

### Documentation
- [ ] Update API documentation
- [ ] Document deployment process
- [ ] Create runbook for common issues
- [ ] Document rollback procedure
- [ ] Update change log

## Rollback Plan

If issues are encountered:
1. Stop new deployment
2. Revert to previous version
3. Run database rollback if needed
4. Verify previous version is working
5. Investigate and fix issues
6. Re-deploy when ready
```

### 17.5 Monitoring and Observability

```typescript
// src/lib/monitoring.ts

import * as Sentry from '@sentry/node';
import { ProfilingIntegration } from '@sentry/profiling-node';

export function initializeMonitoring() {
  if (process.env.SENTRY_DSN) {
    Sentry.init({
      dsn: process.env.SENTRY_DSN,
      environment: process.env.NODE_ENV || 'development',
      integrations: [
        new ProfilingIntegration(),
      ],
      tracesSampleRate: 0.1, // Capture 10% of transactions
      profilesSampleRate: 0.1,
      beforeSend(event, hint) {
        // Filter sensitive data
        if (event.request?.headers) {
          delete event.request.headers.authorization;
          delete event.request.headers.cookie;
        }
        return event;
      },
    });
  }
}

export function captureException(error: Error, context?: Record<string, any>) {
  console.error('Error:', error);
  
  if (process.env.SENTRY_DSN) {
    Sentry.captureException(error, {
      extra: context,
    });
  }
}

export function captureMessage(message: string, level: 'info' | 'warning' | 'error' = 'info') {
  console.log(`[${level.toUpperCase()}] ${message}`);
  
  if (process.env.SENTRY_DSN) {
    Sentry.captureMessage(message, level);
  }
}

export function addBreadcrumb(breadcrumb: {
  message: string;
  category?: string;
  level?: 'info' | 'warning' | 'error';
  data?: Record<string, any>;
}) {
  if (process.env.SENTRY_DSN) {
    Sentry.addBreadcrumb(breadcrumb);
  }
}
```

```typescript
// src/plugins/monitoring.ts

import type { FastifyPluginAsync } from 'fastify';
import * as Sentry from '@sentry/node';
import { captureException } from '../lib/monitoring';

const monitoringPlugin: FastifyPluginAsync = async (server) => {
  // Request tracking
  server.addHook('onRequest', async (request, reply) => {
    request.log.info({
      method: request.method,
      url: request.url,
      ip: request.ip,
    });
  });

  // Response time tracking
  server.addHook('onResponse', async (request, reply) => {
    const responseTime = reply.getResponseTime();
    
    request.log.info({
      method: request.method,
      url: request.url,
      statusCode: reply.statusCode,
      responseTime,
    });

    // Track slow requests
    if (responseTime > 1000) {
      request.log.warn({
        message: 'Slow request detected',
        method: request.method,
        url: request.url,
        responseTime,
      });
    }
  });

  // Error tracking
  server.setErrorHandler((error, request, reply) => {
    const statusCode = error.statusCode || 500;

    captureException(error, {
      method: request.method,
      url: request.url,
      user: request.user?.id,
    });

    if (statusCode >= 500) {
      request.log.error(error);
    } else {
      request.log.warn(error);
    }

    reply.status(statusCode).send({
      type: 'internal_error',
      title: 'Internal Server Error',
      detail: process.env.NODE_ENV === 'production'
        ? 'An unexpected error occurred'
        : error.message,
    });
  });

  // Health check endpoint
  server.get('/health', async (request, reply) => {
    // Check database
    try {
      await server.prisma.$queryRaw`SELECT 1`;
    } catch (error) {
      return reply.code(503).send({
        status: 'unhealthy',
        database: 'down',
      });
    }

    // Check Redis
    try {
      await server.redis.ping();
    } catch (error) {
      return reply.code(503).send({
        status: 'unhealthy',
        redis: 'down',
      });
    }

    return reply.send({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    });
  });
};

export default monitoringPlugin;
```

### 17.6 Production Scripts

```typescript
// scripts/production-startup.ts
/**
 * Production startup script
 * Ensures all prerequisites are met before starting the application
 */

import { PrismaClient } from '@prisma/client';
import Redis from 'ioredis';

const prisma = new PrismaClient();

async function checkDatabase() {
  console.log('Checking database connection...');
  try {
    await prisma.$connect();
    await prisma.$queryRaw`SELECT 1`;
    console.log('✓ Database connection successful');
    return true;
  } catch (error) {
    console.error('✗ Database connection failed:', error);
    return false;
  }
}

async function checkRedis() {
  console.log('Checking Redis connection...');
  try {
    const redis = new Redis({
      host: process.env.REDIS_HOST,
      port: parseInt(process.env.REDIS_PORT || '6379'),
      password: process.env.REDIS_PASSWORD,
    });

    await redis.ping();
    await redis.disconnect();
    console.log('✓ Redis connection successful');
    return true;
  } catch (error) {
    console.error('✗ Redis connection failed:', error);
    return false;
  }
}

async function checkEnvironmentVariables() {
  console.log('Checking environment variables...');
  
  const required = [
    'DATABASE_URL',
    'REDIS_HOST',
    'JWT_SECRET',
    'STRIPE_SECRET_KEY',
    'STRIPE_WEBHOOK_SECRET',
  ];

  const missing = required.filter((key) => !process.env[key]);

  if (missing.length > 0) {
    console.error('✗ Missing required environment variables:', missing);
    return false;
  }

  console.log('✓ All required environment variables set');
  return true;
}

async function refreshAnalyticsViews() {
  console.log('Refreshing analytics views...');
  try {
    await prisma.$executeRaw`SELECT refresh_analytics_views()`;
    console.log('✓ Analytics views refreshed');
    return true;
  } catch (error) {
    console.error('✗ Failed to refresh analytics views:', error);
    return false;
  }
}

async function main() {
  console.log('='.repeat(50));
  console.log('Singr Karaoke Connect - Production Startup Check');
  console.log('='.repeat(50));

  const checks = [
    await checkEnvironmentVariables(),
    await checkDatabase(),
    await checkRedis(),
    await refreshAnalyticsViews(),
  ];

  await prisma.$disconnect();

  if (checks.every((check) => check)) {
    console.log('\n✓ All checks passed! Starting application...\n');
    process.exit(0);
  } else {
    console.log('\n✗ Some checks failed. Please fix the issues before starting.\n');
    process.exit(1);
  }
}

main();
```
