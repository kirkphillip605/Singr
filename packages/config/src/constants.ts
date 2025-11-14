/**
 * Rate limits for different endpoint categories
 * Format: { max: number, window: string }
 */
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
} as const;

/**
 * Cache TTL values in seconds
 */
export const CACHE_TTL = {
  VENUES_LIST: 300, // 5 minutes
  VENUE_DETAIL: 600, // 10 minutes
  SONGDB_SEARCH: 300, // 5 minutes
  PERMISSIONS: 1800, // 30 minutes
  PUBLIC_BRANDING: 3600, // 1 hour
  TWO_FACTOR_CODE: 300, // 5 minutes
} as const;

/**
 * Pagination defaults
 */
export const PAGINATION = {
  DEFAULT_LIMIT: 20,
  MAX_LIMIT: 100,
  MIN_LIMIT: 1,
} as const;

/**
 * Pagination limits by resource type
 */
export const PAGINATION_LIMITS = {
  VENUES: { default: 20, max: 100 },
  SONGS: { default: 20, max: 100 },
  REQUESTS: { default: 20, max: 100 },
  USERS: { default: 20, max: 50 },
} as const;

/**
 * Argon2 password hashing configuration
 */
export const PASSWORD_CONFIG = {
  memoryCost: 19456, // 19 MB
  timeCost: 2,
  outputLen: 32,
  parallelism: 1,
} as const;

/**
 * API key prefix for identification
 */
export const API_KEY_PREFIX = 'sk_live_';

/**
 * Token expiry times in milliseconds
 */
export const TOKEN_EXPIRY = {
  INVITATION: 7 * 24 * 60 * 60 * 1000, // 7 days
  EMAIL_VERIFICATION: 24 * 60 * 60 * 1000, // 24 hours
  PASSWORD_RESET: 60 * 60 * 1000, // 1 hour
  MAGIC_LINK: 15 * 60 * 1000, // 15 minutes
  TWO_FACTOR_BACKUP: 0, // Never expires until used
} as const;

/**
 * Two-factor authentication configuration
 */
export const TWO_FACTOR = {
  TOTP_WINDOW: 1, // Allow 1 step before/after for clock skew
  TOTP_STEP: 30, // 30 second intervals
  SMS_CODE_LENGTH: 6,
  SMS_CODE_TTL: 300, // 5 minutes
  BACKUP_CODE_COUNT: 10,
  BACKUP_CODE_LENGTH: 8,
} as const;

/**
 * Email types for tracking
 */
export const EMAIL_TYPES = {
  VERIFICATION: 'email_verification',
  PASSWORD_RESET: 'password_reset',
  MAGIC_LINK: 'magic_link',
  TWO_FACTOR_CODE: 'two_factor_code',
  WELCOME: 'welcome',
  INVITATION: 'invitation',
  REQUEST_NOTIFICATION: 'request_notification',
} as const;

/**
 * SMS types for tracking
 */
export const SMS_TYPES = {
  VERIFICATION: 'sms_verification',
  TWO_FACTOR_CODE: 'two_factor_code',
  MAGIC_LINK: 'magic_link',
} as const;

/**
 * Default system roles
 */
export const DEFAULT_ROLES = [
  { slug: 'admin', description: 'Platform administrator', isSystem: true },
  { slug: 'support_admin', description: 'Support team admin', isSystem: true },
  {
    slug: 'customer_owner',
    description: 'Customer account owner',
    isSystem: true,
  },
  {
    slug: 'customer_manager',
    description: 'Customer manager',
    isSystem: true,
  },
  { slug: 'customer_staff', description: 'Customer staff member', isSystem: true },
  { slug: 'singer', description: 'Singer user', isSystem: true },
] as const;

/**
 * Default system permissions
 */
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
] as const;

/**
 * Mailjet sandbox mode configuration
 */
export const MAILJET_SANDBOX_MODE = {
  enabled: process.env.NODE_ENV === 'development',
  testEmail: 'test@singrkaraoke.com',
} as const;

/**
 * Communication retry configuration
 */
export const COMMUNICATION_RETRY = {
  maxAttempts: 3,
  backoffMs: 1000, // Start with 1 second
  backoffMultiplier: 2, // Double each retry
} as const;

/**
 * Geographic search radius defaults (in meters)
 */
export const GEO_SEARCH = {
  DEFAULT_RADIUS_METERS: 50000, // 50km
  MAX_RADIUS_METERS: 200000, // 200km
  MIN_RADIUS_METERS: 1000, // 1km
} as const;

/**
 * Request status constants
 */
export const REQUEST_STATUS = {
  PENDING: 'pending',
  ACCEPTED: 'accepted',
  REJECTED: 'rejected',
  COMPLETED: 'completed',
  CANCELED: 'canceled',
} as const;

/**
 * File upload limits
 */
export const UPLOAD_LIMITS = {
  AVATAR_MAX_SIZE: 5 * 1024 * 1024, // 5MB
  LOGO_MAX_SIZE: 2 * 1024 * 1024, // 2MB
  SONGDB_CSV_MAX_SIZE: 50 * 1024 * 1024, // 50MB
  ALLOWED_IMAGE_TYPES: ['image/jpeg', 'image/png', 'image/webp'],
  ALLOWED_CSV_TYPES: ['text/csv', 'application/vnd.ms-excel'],
} as const;
