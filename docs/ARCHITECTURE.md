# Singr API Backend - Architecture

## Overview

The Singr API Backend is a **single, unified REST API service** that serves multiple front-end applications. Access to endpoints is controlled through JWT authentication and role-based access control (RBAC).

## Architectural Principles

### 1. Single API Service
- **One codebase, one deployment**
- All user types (guests, singers, customers, admins) use the same API
- Different routes and permissions based on user context
- Shared business logic and data models

### 2. Role-Based Access Control
- JWT tokens contain user role and context information
- Middleware enforces permissions at the route level
- Fine-grained permissions can be assigned per organization

### 3. Multi-Tenant Design
- Customer profiles represent separate business entities
- Data isolation at the database level
- Shared infrastructure with logical separation

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Client Applications                      │
│  • Singer Web/Mobile  • Customer Portal  • Admin Dashboard  │
└─────────────────────────────────┬───────────────────────────┘
                                  │ HTTPS + JWT
┌─────────────────────────────────┴───────────────────────────┐
│                    Load Balancer / CDN                       │
│              (TLS Termination, CORS, Rate Limiting)         │
└─────────────────────────────────┬───────────────────────────┘
                                  │
┌─────────────────────────────────┴───────────────────────────┐
│                 Single Fastify API Service                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Route Groups (by user context)                        │  │
│  │  • /v1/auth/*      - Authentication (all users)       │  │
│  │  • /v1/public/*    - Public/guest endpoints           │  │
│  │  • /v1/singer/*    - Singer user endpoints            │  │
│  │  • /v1/customer/*  - Customer/venue owner endpoints   │  │
│  │  • /v1/admin/*     - Admin endpoints                  │  │
│  │  • /api/*          - OpenKJ compatibility layer       │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Middleware Layer                                       │  │
│  │  • JWT Verification                                    │  │
│  │  • RBAC Enforcement                                    │  │
│  │  • Request Validation (Zod)                           │  │
│  │  • Rate Limiting (per role/endpoint)                  │  │
│  │  • Logging & Metrics                                  │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Services Layer                                         │  │
│  │  • Venue Service                                       │  │
│  │  • Song Service                                        │  │
│  │  • Request Service                                     │  │
│  │  • User Service                                        │  │
│  │  • Billing Service (Stripe)                           │  │
│  │  • Email/SMS Service (Mailjet, Twilio)               │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Background Workers (BullMQ)                           │  │
│  │  • Email queue                                         │  │
│  │  • SMS queue                                           │  │
│  │  • Analytics processing                               │  │
│  │  • Report generation                                   │  │
│  └───────────────────────────────────────────────────────┘  │
└───┬───────┬────────┬─────────┬────────┬──────────────────┘
    │       │        │         │        │
    ▼       ▼        ▼         ▼        ▼
┌────────┐ ┌────┐ ┌─────┐ ┌────────┐ ┌──────┐
│Postgre ││Redis││ S3  ││ Stripe ││Mailjet│
│SQL+GIS ││Cache││Store││  API   ││Twilio │
└────────┘ └────┘ └─────┘ └────────┘ └──────┘
```

## API Route Organization

### /v1/auth/* (Public - No authentication required initially)
- POST /signup - User registration
- POST /signin - User login
- POST /signout - User logout
- POST /refresh - Token refresh
- POST /forgot-password - Password reset request
- POST /reset-password - Password reset
- POST /verify-email - Email verification
- POST /magic-link - Magic link authentication
- POST /2fa/setup - 2FA setup
- POST /2fa/verify - 2FA verification

### /v1/public/* (Public - No authentication required)
- GET /venues - Search venues by location
- GET /venues/:urlName - Get venue details
- GET /venues/:urlName/songs - Search venue's song database
- POST /venues/:urlName/requests - Submit guest request

### /v1/singer/* (Requires singer authentication)
- GET /profile - Get singer profile
- PUT /profile - Update singer profile
- GET /favorites/songs - Get favorite songs
- POST /favorites/songs - Add favorite song
- GET /favorites/venues - Get favorite venues
- POST /favorites/venues - Add favorite venue
- GET /history - Get request history
- POST /requests - Submit authenticated request

### /v1/customer/* (Requires customer authentication)
- GET /venues - List customer's venues
- POST /venues - Create new venue
- PUT /venues/:id - Update venue
- GET /systems - List karaoke systems
- POST /systems - Create system
- GET /systems/:id/songs - List songs in system
- POST /systems/:id/songs/import - Bulk import songs
- GET /requests - Get request queue
- PUT /requests/:id - Update request status
- GET /organization/users - List team members
- POST /organization/invite - Invite team member
- GET /subscription - Get subscription details
- POST /subscription/checkout - Create checkout session
- GET /analytics/daily-stats - Get analytics

### /v1/admin/* (Requires admin authentication)
- GET /customers - List all customers
- GET /customers/:id - Get customer details
- GET /platform/analytics - Platform-wide analytics
- POST /customers/:id/impersonate - Impersonate customer
- GET /audit-logs - View audit logs

### /api/* (OpenKJ compatibility - API key authentication)
- GET /api/requests/:apiKey - Get requests for OpenKJ
- POST /api/requests/:apiKey - Submit request via OpenKJ
- PUT /api/requests/:apiKey/:id - Update request via OpenKJ

## Authentication & Authorization

### JWT Token Structure
```typescript
{
  sub: string;        // User ID
  email: string;      // User email
  name: string;       // User name
  role: string;       // Primary role (admin, customer, singer)
  activeContext?: {   // Current operating context
    type: 'customer' | 'admin';
    id: string;       // Customer profile ID or admin context
  },
  permissions: string[]; // Granted permissions
  iat: number;        // Issued at
  exp: number;        // Expires at
}
```

### Role Hierarchy
1. **Guest** - No authentication, limited public access
2. **Singer** - Authenticated singer users
3. **Customer Staff** - Team member with limited permissions
4. **Customer Manager** - Team member with extended permissions
5. **Customer Owner** - Full control over customer account
6. **Admin** - Platform administrator
7. **Super Admin** - Full system access

### Permission Model
- Permissions are checked via middleware before route handlers
- Customer context is required for customer/* endpoints
- Singer profile is required for singer/* endpoints
- Admin role is required for admin/* endpoints
- Fine-grained permissions can override role defaults

## Data Isolation

### Multi-Tenancy
- Each customer has a `customer_profile_id`
- All customer data (venues, systems, requests) is scoped to profile
- Database queries include customer_profile_id in WHERE clauses
- Row-level security via Prisma middleware

### Cross-Tenant Features
- Singers can interact with multiple venues (different customers)
- Requests link singer_profile to venue (different customer)
- Favorites and history track cross-customer activity

## Scalability Considerations

### Horizontal Scaling
- Stateless API design (JWT tokens, no server sessions)
- Redis for distributed caching and session storage
- PostgreSQL read replicas for read-heavy operations
- BullMQ for distributed background job processing

### Performance Optimization
- Database indexes on frequently queried fields
- Materialized views for analytics
- Redis caching for frequently accessed data
- Connection pooling (PgBouncer)
- CDN for static assets

### Rate Limiting
- Per-IP rate limiting for public endpoints
- Per-user rate limiting for authenticated endpoints
- Per-customer rate limiting for customer endpoints
- API key rate limiting for OpenKJ integration

## Background Processing

### Worker Integration
- Workers run in the same codebase (`src/workers/`)
- Can be deployed separately or with the API
- BullMQ queues for async tasks:
  - Email delivery
  - SMS delivery
  - Report generation
  - Analytics refresh
  - Cleanup jobs

### Queue Structure
```typescript
{
  emailQueue: Queue<EmailJobData>,
  smsQueue: Queue<SMSJobData>,
  analyticsQueue: Queue<AnalyticsJobData>,
  reportQueue: Queue<ReportJobData>
}
```

## Deployment Model

### Single Deployment Unit
- One Docker image contains the API and workers
- Environment variable determines if workers start
- Kubernetes/ECS can run multiple replicas
- Some replicas serve API, others process queues
- Or single replica does both (suitable for small/medium load)

### Environment Modes
```bash
# API only
NODE_ENV=production
RUN_WORKERS=false

# Workers only
NODE_ENV=production
RUN_WORKERS=true
RUN_API=false

# Both (default)
NODE_ENV=production
RUN_WORKERS=true
RUN_API=true
```

## Security Architecture

### Defense in Depth
1. **Network Layer** - TLS 1.3, firewall rules
2. **Application Layer** - JWT validation, RBAC, input validation
3. **Data Layer** - Parameterized queries (Prisma), encryption at rest
4. **Audit Layer** - All sensitive operations logged

### Attack Mitigation
- **DDoS** - Rate limiting, CDN
- **SQL Injection** - Prisma ORM (parameterized queries)
- **XSS** - Input sanitization, Content Security Policy
- **CSRF** - SameSite cookies, CSRF tokens where needed
- **Brute Force** - Progressive delays, account lockouts
- **Token Theft** - Short-lived access tokens, refresh rotation

## Monitoring & Observability

### Logging Strategy
- Structured JSON logs (Pino)
- Correlation IDs for request tracing
- Sensitive data redaction
- Log levels: error, warn, info, debug, trace

### Metrics Collection
- Request count, latency, error rate per endpoint
- Active users, concurrent requests
- Database query performance
- Queue depths and processing times
- Business metrics (requests submitted, venues created, etc.)

### Error Tracking
- Sentry for production error tracking
- Stack traces, user context, breadcrumbs
- Error grouping and notifications
- Release tracking for regression detection

## Disaster Recovery

### Backup Strategy
- Database: Daily full backups + WAL archiving
- Configuration: Version controlled (Git)
- Secrets: Encrypted in secrets manager
- User uploads: Replicated in S3/GCS

### Rollback Procedures
1. Database: Point-in-time recovery
2. Application: Deploy previous version
3. Migrations: Reversible migrations only
4. Feature flags: Toggle features without deployment

---

**Last Updated**: 2025-11-14  
**Version**: 1.0.0  
**Status**: Living Document
