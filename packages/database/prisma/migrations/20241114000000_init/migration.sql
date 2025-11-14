-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "postgis";

-- CreateEnum
CREATE TYPE "branding_owner_type" AS ENUM ('platform', 'customer');

-- CreateEnum
CREATE TYPE "branding_status" AS ENUM ('active', 'suspended', 'revoked');

-- CreateEnum
CREATE TYPE "organization_user_status" AS ENUM ('invited', 'active', 'suspended', 'revoked');

-- CreateEnum
CREATE TYPE "api_key_status" AS ENUM ('active', 'revoked', 'expired', 'suspended');

-- CreateEnum
CREATE TYPE "subscription_status" AS ENUM ('incomplete', 'incomplete_expired', 'trialing', 'active', 'past_due', 'canceled', 'unpaid', 'paused');

-- CreateTable
CREATE TABLE "users" (
    "users_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "email" TEXT NOT NULL,
    "password_hash" TEXT,
    "password_algo" TEXT DEFAULT 'argon2id',
    "name" TEXT,
    "display_name" TEXT,
    "phone_number" TEXT,
    "image_url" TEXT,
    "is_email_verified" BOOLEAN NOT NULL DEFAULT false,
    "last_login_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("users_id")
);

-- CreateTable
CREATE TABLE "roles" (
    "roles_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "slug" TEXT NOT NULL,
    "description" TEXT,
    "is_system" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "roles_pkey" PRIMARY KEY ("roles_id")
);

-- CreateTable
CREATE TABLE "permissions" (
    "permissions_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "slug" TEXT NOT NULL,
    "description" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "permissions_pkey" PRIMARY KEY ("permissions_id")
);

-- CreateTable
CREATE TABLE "role_permissions" (
    "role_permissions_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "roles_id" UUID NOT NULL,
    "permissions_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "role_permissions_pkey" PRIMARY KEY ("role_permissions_id")
);

-- CreateTable
CREATE TABLE "user_roles" (
    "user_roles_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "users_id" UUID NOT NULL,
    "roles_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_roles_pkey" PRIMARY KEY ("user_roles_id")
);

-- CreateTable
CREATE TABLE "accounts" (
    "accounts_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "users_id" UUID NOT NULL,
    "provider" TEXT NOT NULL,
    "provider_account_id" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "refresh_token" TEXT,
    "access_token" TEXT,
    "expires_at" BIGINT,
    "token_type" TEXT,
    "scope" TEXT,
    "id_token" TEXT,
    "session_state" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "accounts_pkey" PRIMARY KEY ("accounts_id")
);

-- CreateTable
CREATE TABLE "sessions" (
    "sessions_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "users_id" UUID NOT NULL,
    "session_token" TEXT NOT NULL,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sessions_pkey" PRIMARY KEY ("sessions_id")
);

-- CreateTable
CREATE TABLE "verification_tokens" (
    "identifier" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "verification_tokens_pkey" PRIMARY KEY ("identifier","token")
);

-- CreateTable
CREATE TABLE "customer_profiles" (
    "customer_profiles_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "users_id" UUID NOT NULL,
    "legal_business_name" TEXT,
    "dba_name" TEXT,
    "stripe_customer_id" TEXT,
    "contact_email" TEXT,
    "contact_phone" TEXT,
    "timezone" TEXT DEFAULT 'UTC',
    "billing_address" JSONB,
    "metadata" JSONB DEFAULT '{}',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "customer_profiles_pkey" PRIMARY KEY ("customer_profiles_id")
);

-- CreateTable
CREATE TABLE "singer_profiles" (
    "singer_profiles_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "users_id" UUID NOT NULL,
    "nickname" TEXT,
    "avatar_url" TEXT,
    "preferences" JSONB DEFAULT '{}',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "singer_profiles_pkey" PRIMARY KEY ("singer_profiles_id")
);

-- CreateTable
CREATE TABLE "organization_users" (
    "organization_users_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "customer_profiles_id" UUID NOT NULL,
    "users_id" UUID NOT NULL,
    "invited_by_user_id" UUID,
    "role_id" UUID,
    "status" "organization_user_status" NOT NULL DEFAULT 'invited',
    "invitation_token" TEXT,
    "invitation_expires_at" TIMESTAMPTZ(6),
    "last_accessed_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "organization_users_pkey" PRIMARY KEY ("organization_users_id")
);

-- CreateTable
CREATE TABLE "organization_user_permissions" (
    "organization_user_permissions_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organization_users_id" UUID NOT NULL,
    "permissions_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "organization_user_permissions_pkey" PRIMARY KEY ("organization_user_permissions_id")
);

-- CreateTable
CREATE TABLE "customers" (
    "customers_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "stripe_customer_id" TEXT NOT NULL,
    "customer_profiles_id" UUID NOT NULL,
    "email" TEXT,
    "name" TEXT,
    "phone" TEXT,
    "description" TEXT,
    "metadata" JSONB NOT NULL DEFAULT '{}',
    "invoice_settings" JSONB NOT NULL DEFAULT '{}',
    "shipping" JSONB NOT NULL DEFAULT '{}',
    "tax_exempt" TEXT,
    "tax_ids" JSONB NOT NULL DEFAULT '[]',
    "livemode" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "customers_pkey" PRIMARY KEY ("customers_id")
);

-- CreateTable
CREATE TABLE "subscriptions" (
    "subscriptions_id" UUID NOT NULL,
    "stripe_sub_id" TEXT NOT NULL,
    "customer_profiles_id" UUID NOT NULL,
    "prices_id" UUID NOT NULL,
    "status" "subscription_status" NOT NULL,
    "current_period_start" TIMESTAMPTZ(6) NOT NULL,
    "current_period_end" TIMESTAMPTZ(6) NOT NULL,
    "cancel_at_period_end" BOOLEAN NOT NULL DEFAULT false,
    "canceled_at" TIMESTAMPTZ(6),
    "trial_start" TIMESTAMPTZ(6),
    "trial_end" TIMESTAMPTZ(6),
    "metadata" JSONB NOT NULL DEFAULT '{}',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("subscriptions_id")
);

-- CreateTable
CREATE TABLE "products" (
    "products_id" UUID NOT NULL,
    "stripe_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "metadata" JSONB NOT NULL DEFAULT '{}',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "products_pkey" PRIMARY KEY ("products_id")
);

-- CreateTable
CREATE TABLE "prices" (
    "prices_id" UUID NOT NULL,
    "stripe_id" TEXT NOT NULL,
    "products_id" UUID NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "currency" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "unit_amount" BIGINT,
    "interval" TEXT,
    "interval_count" INTEGER,
    "trial_days" INTEGER,
    "metadata" JSONB NOT NULL DEFAULT '{}',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "prices_pkey" PRIMARY KEY ("prices_id")
);

-- CreateTable
CREATE TABLE "stripe_webhook_events" (
    "stripe_webhook_events_id" UUID NOT NULL,
    "stripe_id" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "livemode" BOOLEAN NOT NULL,
    "api_version" TEXT,
    "data" JSONB NOT NULL,
    "processed" BOOLEAN NOT NULL DEFAULT false,
    "processed_at" TIMESTAMPTZ(6),
    "error" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "stripe_webhook_events_pkey" PRIMARY KEY ("stripe_webhook_events_id")
);

-- CreateTable
CREATE TABLE "stripe_checkout_sessions" (
    "stripe_checkout_sessions_id" UUID NOT NULL,
    "stripe_session_id" TEXT NOT NULL,
    "customers_id" UUID NOT NULL,
    "mode" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "success_url" TEXT,
    "cancel_url" TEXT,
    "payment_status" TEXT,
    "subscription_id" TEXT,
    "amount_total" BIGINT,
    "currency" TEXT,
    "metadata" JSONB NOT NULL DEFAULT '{}',
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "stripe_checkout_sessions_pkey" PRIMARY KEY ("stripe_checkout_sessions_id")
);

-- CreateTable
CREATE TABLE "state" (
    "state_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "customer_profiles_id" UUID NOT NULL,
    "state" JSONB NOT NULL DEFAULT '{}',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "state_pkey" PRIMARY KEY ("state_id")
);

-- CreateTable
CREATE TABLE "venues" (
    "venues_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "customer_profiles_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "url_name" TEXT NOT NULL,
    "description" TEXT,
    "address" TEXT,
    "city" TEXT,
    "state" TEXT,
    "postal_code" TEXT,
    "country" TEXT DEFAULT 'US',
    "phone" TEXT,
    "website" TEXT,
    "timezone" TEXT DEFAULT 'UTC',
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "settings" JSONB DEFAULT '{}',
    "metadata" JSONB DEFAULT '{}',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "venues_pkey" PRIMARY KEY ("venues_id")
);

-- CreateTable
CREATE TABLE "systems" (
    "systems_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "customer_profiles_id" UUID NOT NULL,
    "venues_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "settings" JSONB DEFAULT '{}',
    "metadata" JSONB DEFAULT '{}',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "systems_pkey" PRIMARY KEY ("systems_id")
);

-- CreateTable
CREATE TABLE "songdb" (
    "songdb_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "customer_profiles_id" UUID NOT NULL,
    "systems_id" UUID NOT NULL,
    "artist" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "disc_id" TEXT,
    "duration" INTEGER,
    "metadata" JSONB DEFAULT '{}',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "songdb_pkey" PRIMARY KEY ("songdb_id")
);

-- CreateTable
CREATE TABLE "requests" (
    "requests_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "venues_id" UUID NOT NULL,
    "systems_id" UUID NOT NULL,
    "singer_profiles_id" UUID,
    "submitted_by_user_id" UUID,
    "singer_name" TEXT NOT NULL,
    "artist" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "key_change" INTEGER NOT NULL DEFAULT 0,
    "notes" TEXT,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "priority" INTEGER NOT NULL DEFAULT 0,
    "position" INTEGER NOT NULL DEFAULT 0,
    "requested_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completed_at" TIMESTAMPTZ(6),
    "metadata" JSONB DEFAULT '{}',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "requests_pkey" PRIMARY KEY ("requests_id")
);

-- CreateTable
CREATE TABLE "api_keys" (
    "api_keys_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "customer_profiles_id" UUID NOT NULL,
    "customers_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "key_hash" TEXT NOT NULL,
    "key_prefix" TEXT NOT NULL,
    "status" "api_key_status" NOT NULL DEFAULT 'active',
    "expires_at" TIMESTAMPTZ(6),
    "last_used_at" TIMESTAMPTZ(6),
    "rate_limit" INTEGER,
    "permissions" JSONB DEFAULT '[]',
    "created_by_user_id" UUID,
    "metadata" JSONB DEFAULT '{}',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "api_keys_pkey" PRIMARY KEY ("api_keys_id")
);

-- CreateTable
CREATE TABLE "singer_favorite_songs" (
    "singer_favorite_songs_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "singer_profiles_id" UUID NOT NULL,
    "artist" TEXT,
    "title" TEXT,
    "key_change" INTEGER NOT NULL DEFAULT 0,
    "metadata" JSONB DEFAULT '{}',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "singer_favorite_songs_pkey" PRIMARY KEY ("singer_favorite_songs_id")
);

-- CreateTable
CREATE TABLE "singer_request_history" (
    "singer_request_history_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "singer_profiles_id" UUID NOT NULL,
    "venues_id" UUID NOT NULL,
    "artist" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "key_change" INTEGER NOT NULL DEFAULT 0,
    "requested_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "song_fingerprint" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "singer_request_history_pkey" PRIMARY KEY ("singer_request_history_id")
);

-- CreateTable
CREATE TABLE "singer_favorite_venues" (
    "singer_profiles_id" UUID NOT NULL,
    "venues_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "singer_favorite_venues_pkey" PRIMARY KEY ("singer_profiles_id","venues_id")
);

-- CreateTable
CREATE TABLE "branding_profiles" (
    "branding_profiles_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "owner_type" "branding_owner_type" NOT NULL,
    "owner_id" UUID,
    "name" TEXT NOT NULL,
    "logo_url" TEXT,
    "color_palette" JSONB NOT NULL DEFAULT '{}',
    "powered_by_singr" BOOLEAN NOT NULL DEFAULT true,
    "domain" TEXT,
    "app_bundle_id" TEXT,
    "app_package_name" TEXT,
    "status" "branding_status" NOT NULL DEFAULT 'active',
    "metadata" JSONB DEFAULT '{}',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "branding_profiles_pkey" PRIMARY KEY ("branding_profiles_id")
);

-- CreateTable
CREATE TABLE "branded_apps" (
    "branded_apps_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "customer_profiles_id" UUID NOT NULL,
    "branding_profiles_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "platform" TEXT NOT NULL,
    "bundle_identifier" TEXT,
    "status" "branding_status" NOT NULL DEFAULT 'active',
    "config" JSONB NOT NULL DEFAULT '{}',
    "rate_limit_override" JSONB,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "branded_apps_pkey" PRIMARY KEY ("branded_apps_id")
);

-- CreateTable
CREATE TABLE "branded_app_api_keys" (
    "branded_app_api_keys_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "branded_apps_id" UUID NOT NULL,
    "api_key_hash" TEXT NOT NULL,
    "description" TEXT,
    "last_used_at" TIMESTAMPTZ(6),
    "status" "branding_status" NOT NULL DEFAULT 'active',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "branded_app_api_keys_pkey" PRIMARY KEY ("branded_app_api_keys_id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "audit_logs_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "table_name" TEXT NOT NULL,
    "record_id" TEXT,
    "user_id" UUID,
    "operation" TEXT NOT NULL,
    "old_data" JSONB,
    "new_data" JSONB,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("audit_logs_id")
);

-- CreateTable
CREATE TABLE "saved_reports" (
    "saved_reports_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "customer_profiles_id" UUID NOT NULL,
    "created_by_users_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "report_type" TEXT NOT NULL,
    "filters" JSONB NOT NULL DEFAULT '{}',
    "columns" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "sort_by" JSONB NOT NULL DEFAULT '[]',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "saved_reports_pkey" PRIMARY KEY ("saved_reports_id")
);

-- CreateTable
CREATE TABLE "report_executions" (
    "report_executions_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "saved_reports_id" UUID NOT NULL,
    "executed_by_users_id" UUID NOT NULL,
    "report_type" TEXT NOT NULL,
    "filters" JSONB NOT NULL DEFAULT '{}',
    "format" TEXT NOT NULL,
    "row_count" INTEGER,
    "execution_time_ms" INTEGER,
    "file_url" TEXT,
    "file_size_bytes" BIGINT,
    "expires_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "report_executions_pkey" PRIMARY KEY ("report_executions_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "users_email_idx" ON "users"("email");

-- CreateIndex
CREATE INDEX "users_phone_number_idx" ON "users"("phone_number");

-- CreateIndex
CREATE UNIQUE INDEX "roles_slug_key" ON "roles"("slug");

-- CreateIndex
CREATE INDEX "roles_slug_idx" ON "roles"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "permissions_slug_key" ON "permissions"("slug");

-- CreateIndex
CREATE INDEX "permissions_slug_idx" ON "permissions"("slug");

-- CreateIndex
CREATE INDEX "role_permissions_roles_id_idx" ON "role_permissions"("roles_id");

-- CreateIndex
CREATE INDEX "role_permissions_permissions_id_idx" ON "role_permissions"("permissions_id");

-- CreateIndex
CREATE UNIQUE INDEX "ux_role_permissions_role_permission" ON "role_permissions"("roles_id", "permissions_id");

-- CreateIndex
CREATE INDEX "user_roles_users_id_idx" ON "user_roles"("users_id");

-- CreateIndex
CREATE INDEX "user_roles_roles_id_idx" ON "user_roles"("roles_id");

-- CreateIndex
CREATE UNIQUE INDEX "ux_user_roles_user_role" ON "user_roles"("users_id", "roles_id");

-- CreateIndex
CREATE INDEX "accounts_users_id_idx" ON "accounts"("users_id");

-- CreateIndex
CREATE UNIQUE INDEX "accounts_provider_provider_account_id_key" ON "accounts"("provider", "provider_account_id");

-- CreateIndex
CREATE UNIQUE INDEX "sessions_session_token_key" ON "sessions"("session_token");

-- CreateIndex
CREATE INDEX "sessions_users_id_idx" ON "sessions"("users_id");

-- CreateIndex
CREATE INDEX "sessions_session_token_idx" ON "sessions"("session_token");

-- CreateIndex
CREATE INDEX "sessions_expires_at_idx" ON "sessions"("expires_at");

-- CreateIndex
CREATE INDEX "idx_verification_tokens_expires" ON "verification_tokens"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "customer_profiles_users_id_key" ON "customer_profiles"("users_id");

-- CreateIndex
CREATE INDEX "customer_profiles_users_id_idx" ON "customer_profiles"("users_id");

-- CreateIndex
CREATE INDEX "customer_profiles_stripe_customer_id_idx" ON "customer_profiles"("stripe_customer_id");

-- CreateIndex
CREATE UNIQUE INDEX "singer_profiles_users_id_key" ON "singer_profiles"("users_id");

-- CreateIndex
CREATE INDEX "singer_profiles_users_id_idx" ON "singer_profiles"("users_id");

-- CreateIndex
CREATE INDEX "organization_users_customer_profiles_id_idx" ON "organization_users"("customer_profiles_id");

-- CreateIndex
CREATE INDEX "organization_users_users_id_idx" ON "organization_users"("users_id");

-- CreateIndex
CREATE INDEX "organization_users_status_idx" ON "organization_users"("status");

-- CreateIndex
CREATE UNIQUE INDEX "ux_organization_users_customer_user" ON "organization_users"("customer_profiles_id", "users_id");

-- CreateIndex
CREATE INDEX "organization_user_permissions_organization_users_id_idx" ON "organization_user_permissions"("organization_users_id");

-- CreateIndex
CREATE INDEX "organization_user_permissions_permissions_id_idx" ON "organization_user_permissions"("permissions_id");

-- CreateIndex
CREATE UNIQUE INDEX "ux_org_user_permissions" ON "organization_user_permissions"("organization_users_id", "permissions_id");

-- CreateIndex
CREATE INDEX "customers_customer_profiles_id_idx" ON "customers"("customer_profiles_id");

-- CreateIndex
CREATE UNIQUE INDEX "customers_stripe_customer_id_key" ON "customers"("stripe_customer_id");

-- CreateIndex
CREATE INDEX "subscriptions_customer_profiles_id_idx" ON "subscriptions"("customer_profiles_id");

-- CreateIndex
CREATE INDEX "subscriptions_status_idx" ON "subscriptions"("status");

-- CreateIndex
CREATE UNIQUE INDEX "subscriptions_stripe_sub_id_key" ON "subscriptions"("stripe_sub_id");

-- CreateIndex
CREATE UNIQUE INDEX "products_stripe_id_key" ON "products"("stripe_id");

-- CreateIndex
CREATE INDEX "prices_products_id_idx" ON "prices"("products_id");

-- CreateIndex
CREATE UNIQUE INDEX "prices_stripe_id_key" ON "prices"("stripe_id");

-- CreateIndex
CREATE INDEX "stripe_webhook_events_type_idx" ON "stripe_webhook_events"("type");

-- CreateIndex
CREATE INDEX "stripe_webhook_events_processed_idx" ON "stripe_webhook_events"("processed");

-- CreateIndex
CREATE INDEX "stripe_webhook_events_created_at_idx" ON "stripe_webhook_events"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "stripe_webhook_events_stripe_id_key" ON "stripe_webhook_events"("stripe_id");

-- CreateIndex
CREATE INDEX "stripe_checkout_sessions_customers_id_idx" ON "stripe_checkout_sessions"("customers_id");

-- CreateIndex
CREATE INDEX "stripe_checkout_sessions_status_idx" ON "stripe_checkout_sessions"("status");

-- CreateIndex
CREATE UNIQUE INDEX "stripe_checkout_sessions_stripe_session_id_key" ON "stripe_checkout_sessions"("stripe_session_id");

-- CreateIndex
CREATE UNIQUE INDEX "state_customer_profiles_id_key" ON "state"("customer_profiles_id");

-- CreateIndex
CREATE INDEX "state_customer_profiles_id_idx" ON "state"("customer_profiles_id");

-- CreateIndex
CREATE UNIQUE INDEX "venues_url_name_key" ON "venues"("url_name");

-- CreateIndex
CREATE INDEX "venues_customer_profiles_id_idx" ON "venues"("customer_profiles_id");

-- CreateIndex
CREATE INDEX "venues_url_name_idx" ON "venues"("url_name");

-- CreateIndex
CREATE INDEX "venues_is_active_idx" ON "venues"("is_active");

-- CreateIndex
CREATE INDEX "systems_customer_profiles_id_idx" ON "systems"("customer_profiles_id");

-- CreateIndex
CREATE INDEX "systems_venues_id_idx" ON "systems"("venues_id");

-- CreateIndex
CREATE INDEX "systems_is_active_idx" ON "systems"("is_active");

-- CreateIndex
CREATE INDEX "songdb_customer_profiles_id_idx" ON "songdb"("customer_profiles_id");

-- CreateIndex
CREATE INDEX "songdb_systems_id_idx" ON "songdb"("systems_id");

-- CreateIndex
CREATE INDEX "songdb_artist_title_idx" ON "songdb"("artist", "title");

-- CreateIndex
CREATE INDEX "requests_venues_id_idx" ON "requests"("venues_id");

-- CreateIndex
CREATE INDEX "requests_systems_id_idx" ON "requests"("systems_id");

-- CreateIndex
CREATE INDEX "requests_singer_profiles_id_idx" ON "requests"("singer_profiles_id");

-- CreateIndex
CREATE INDEX "requests_status_idx" ON "requests"("status");

-- CreateIndex
CREATE INDEX "requests_requested_at_idx" ON "requests"("requested_at");

-- CreateIndex
CREATE INDEX "api_keys_customer_profiles_id_idx" ON "api_keys"("customer_profiles_id");

-- CreateIndex
CREATE INDEX "api_keys_customers_id_idx" ON "api_keys"("customers_id");

-- CreateIndex
CREATE INDEX "api_keys_key_prefix_idx" ON "api_keys"("key_prefix");

-- CreateIndex
CREATE INDEX "api_keys_status_idx" ON "api_keys"("status");

-- CreateIndex
CREATE UNIQUE INDEX "api_keys_key_hash_key" ON "api_keys"("key_hash");

-- CreateIndex
CREATE INDEX "singer_favorite_songs_singer_profiles_id_idx" ON "singer_favorite_songs"("singer_profiles_id");

-- CreateIndex
CREATE UNIQUE INDEX "singer_favorite_songs_singer_profiles_id_artist_title_key_c_key" ON "singer_favorite_songs"("singer_profiles_id", "artist", "title", "key_change");

-- CreateIndex
CREATE INDEX "singer_request_history_singer_profiles_id_idx" ON "singer_request_history"("singer_profiles_id");

-- CreateIndex
CREATE INDEX "singer_request_history_singer_profiles_id_requested_at_idx" ON "singer_request_history"("singer_profiles_id", "requested_at");

-- CreateIndex
CREATE INDEX "singer_request_history_venues_id_idx" ON "singer_request_history"("venues_id");

-- CreateIndex
CREATE INDEX "singer_favorite_venues_singer_profiles_id_idx" ON "singer_favorite_venues"("singer_profiles_id");

-- CreateIndex
CREATE INDEX "singer_favorite_venues_venues_id_idx" ON "singer_favorite_venues"("venues_id");

-- CreateIndex
CREATE INDEX "branding_profiles_owner_type_owner_id_idx" ON "branding_profiles"("owner_type", "owner_id");

-- CreateIndex
CREATE INDEX "branding_profiles_status_idx" ON "branding_profiles"("status");

-- CreateIndex
CREATE UNIQUE INDEX "ux_branding_profiles_owner" ON "branding_profiles"("owner_type", "owner_id", "name");

-- CreateIndex
CREATE INDEX "branded_apps_customer_profiles_id_idx" ON "branded_apps"("customer_profiles_id");

-- CreateIndex
CREATE INDEX "branded_apps_branding_profiles_id_idx" ON "branded_apps"("branding_profiles_id");

-- CreateIndex
CREATE INDEX "branded_app_api_keys_branded_apps_id_idx" ON "branded_app_api_keys"("branded_apps_id");

-- CreateIndex
CREATE INDEX "branded_app_api_keys_api_key_hash_idx" ON "branded_app_api_keys"("api_key_hash");

-- CreateIndex
CREATE UNIQUE INDEX "branded_app_api_keys_branded_apps_id_api_key_hash_key" ON "branded_app_api_keys"("branded_apps_id", "api_key_hash");

-- CreateIndex
CREATE INDEX "audit_logs_table_name_record_id_idx" ON "audit_logs"("table_name", "record_id");

-- CreateIndex
CREATE INDEX "audit_logs_user_id_created_at_idx" ON "audit_logs"("user_id", "created_at");

-- CreateIndex
CREATE INDEX "audit_logs_created_at_idx" ON "audit_logs"("created_at");

-- CreateIndex
CREATE INDEX "saved_reports_customer_profiles_id_idx" ON "saved_reports"("customer_profiles_id");

-- CreateIndex
CREATE INDEX "saved_reports_created_by_users_id_idx" ON "saved_reports"("created_by_users_id");

-- CreateIndex
CREATE INDEX "report_executions_saved_reports_id_idx" ON "report_executions"("saved_reports_id");

-- CreateIndex
CREATE INDEX "report_executions_executed_by_users_id_idx" ON "report_executions"("executed_by_users_id");

-- CreateIndex
CREATE INDEX "report_executions_created_at_idx" ON "report_executions"("created_at");

-- CreateIndex
CREATE INDEX "report_executions_expires_at_idx" ON "report_executions"("expires_at");

-- AddForeignKey
ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_roles_id_fkey" FOREIGN KEY ("roles_id") REFERENCES "roles"("roles_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_permissions_id_fkey" FOREIGN KEY ("permissions_id") REFERENCES "permissions"("permissions_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_users_id_fkey" FOREIGN KEY ("users_id") REFERENCES "users"("users_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_roles_id_fkey" FOREIGN KEY ("roles_id") REFERENCES "roles"("roles_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "accounts" ADD CONSTRAINT "accounts_users_id_fkey" FOREIGN KEY ("users_id") REFERENCES "users"("users_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_users_id_fkey" FOREIGN KEY ("users_id") REFERENCES "users"("users_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "customer_profiles" ADD CONSTRAINT "customer_profiles_users_id_fkey" FOREIGN KEY ("users_id") REFERENCES "users"("users_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "singer_profiles" ADD CONSTRAINT "singer_profiles_users_id_fkey" FOREIGN KEY ("users_id") REFERENCES "users"("users_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "organization_users" ADD CONSTRAINT "organization_users_customer_profiles_id_fkey" FOREIGN KEY ("customer_profiles_id") REFERENCES "customer_profiles"("customer_profiles_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "organization_users" ADD CONSTRAINT "organization_users_users_id_fkey" FOREIGN KEY ("users_id") REFERENCES "users"("users_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "organization_users" ADD CONSTRAINT "organization_users_invited_by_user_id_fkey" FOREIGN KEY ("invited_by_user_id") REFERENCES "users"("users_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "organization_users" ADD CONSTRAINT "organization_users_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "roles"("roles_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "organization_user_permissions" ADD CONSTRAINT "organization_user_permissions_organization_users_id_fkey" FOREIGN KEY ("organization_users_id") REFERENCES "organization_users"("organization_users_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "organization_user_permissions" ADD CONSTRAINT "organization_user_permissions_permissions_id_fkey" FOREIGN KEY ("permissions_id") REFERENCES "permissions"("permissions_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "customers" ADD CONSTRAINT "customers_customer_profiles_id_fkey" FOREIGN KEY ("customer_profiles_id") REFERENCES "customer_profiles"("customer_profiles_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_customer_profiles_id_fkey" FOREIGN KEY ("customer_profiles_id") REFERENCES "customer_profiles"("customer_profiles_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_prices_id_fkey" FOREIGN KEY ("prices_id") REFERENCES "prices"("prices_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "prices" ADD CONSTRAINT "prices_products_id_fkey" FOREIGN KEY ("products_id") REFERENCES "products"("products_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stripe_checkout_sessions" ADD CONSTRAINT "stripe_checkout_sessions_customers_id_fkey" FOREIGN KEY ("customers_id") REFERENCES "customers"("customers_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "state" ADD CONSTRAINT "state_customer_profiles_id_fkey" FOREIGN KEY ("customer_profiles_id") REFERENCES "customer_profiles"("customer_profiles_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "venues" ADD CONSTRAINT "venues_customer_profiles_id_fkey" FOREIGN KEY ("customer_profiles_id") REFERENCES "customer_profiles"("customer_profiles_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "systems" ADD CONSTRAINT "systems_customer_profiles_id_fkey" FOREIGN KEY ("customer_profiles_id") REFERENCES "customer_profiles"("customer_profiles_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "systems" ADD CONSTRAINT "systems_venues_id_fkey" FOREIGN KEY ("venues_id") REFERENCES "venues"("venues_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "songdb" ADD CONSTRAINT "songdb_customer_profiles_id_fkey" FOREIGN KEY ("customer_profiles_id") REFERENCES "customer_profiles"("customer_profiles_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "songdb" ADD CONSTRAINT "songdb_systems_id_fkey" FOREIGN KEY ("systems_id") REFERENCES "systems"("systems_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "requests" ADD CONSTRAINT "requests_venues_id_fkey" FOREIGN KEY ("venues_id") REFERENCES "venues"("venues_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "requests" ADD CONSTRAINT "requests_systems_id_fkey" FOREIGN KEY ("systems_id") REFERENCES "systems"("systems_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "requests" ADD CONSTRAINT "requests_singer_profiles_id_fkey" FOREIGN KEY ("singer_profiles_id") REFERENCES "singer_profiles"("singer_profiles_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "requests" ADD CONSTRAINT "requests_submitted_by_user_id_fkey" FOREIGN KEY ("submitted_by_user_id") REFERENCES "users"("users_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "api_keys" ADD CONSTRAINT "api_keys_customer_profiles_id_fkey" FOREIGN KEY ("customer_profiles_id") REFERENCES "customer_profiles"("customer_profiles_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "api_keys" ADD CONSTRAINT "api_keys_customers_id_fkey" FOREIGN KEY ("customers_id") REFERENCES "customers"("customers_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "api_keys" ADD CONSTRAINT "api_keys_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("users_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "singer_favorite_songs" ADD CONSTRAINT "singer_favorite_songs_singer_profiles_id_fkey" FOREIGN KEY ("singer_profiles_id") REFERENCES "singer_profiles"("singer_profiles_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "singer_request_history" ADD CONSTRAINT "singer_request_history_singer_profiles_id_fkey" FOREIGN KEY ("singer_profiles_id") REFERENCES "singer_profiles"("singer_profiles_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "singer_request_history" ADD CONSTRAINT "singer_request_history_venues_id_fkey" FOREIGN KEY ("venues_id") REFERENCES "venues"("venues_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "singer_favorite_venues" ADD CONSTRAINT "singer_favorite_venues_singer_profiles_id_fkey" FOREIGN KEY ("singer_profiles_id") REFERENCES "singer_profiles"("singer_profiles_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "singer_favorite_venues" ADD CONSTRAINT "singer_favorite_venues_venues_id_fkey" FOREIGN KEY ("venues_id") REFERENCES "venues"("venues_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "branded_apps" ADD CONSTRAINT "branded_apps_customer_profiles_id_fkey" FOREIGN KEY ("customer_profiles_id") REFERENCES "customer_profiles"("customer_profiles_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "branded_apps" ADD CONSTRAINT "branded_apps_branding_profiles_id_fkey" FOREIGN KEY ("branding_profiles_id") REFERENCES "branding_profiles"("branding_profiles_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "branded_app_api_keys" ADD CONSTRAINT "branded_app_api_keys_branded_apps_id_fkey" FOREIGN KEY ("branded_apps_id") REFERENCES "branded_apps"("branded_apps_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_reports" ADD CONSTRAINT "saved_reports_customer_profiles_id_fkey" FOREIGN KEY ("customer_profiles_id") REFERENCES "customer_profiles"("customer_profiles_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_reports" ADD CONSTRAINT "saved_reports_created_by_users_id_fkey" FOREIGN KEY ("created_by_users_id") REFERENCES "users"("users_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "report_executions" ADD CONSTRAINT "report_executions_saved_reports_id_fkey" FOREIGN KEY ("saved_reports_id") REFERENCES "saved_reports"("saved_reports_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "report_executions" ADD CONSTRAINT "report_executions_executed_by_users_id_fkey" FOREIGN KEY ("executed_by_users_id") REFERENCES "users"("users_id") ON DELETE CASCADE ON UPDATE CASCADE;

