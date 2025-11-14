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
  SENTRY_DSN: str({ default: '', allowEmpty: true }),
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
  TWILIO_VERIFY_SERVICE_SID: str({ default: '', allowEmpty: true }), // Optional: Use Twilio Verify API

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

// Parse CORS origins into array
export const corsOrigins = config.CORS_ORIGINS.split(',').map((origin) =>
  origin.trim()
);
