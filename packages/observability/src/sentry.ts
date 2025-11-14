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
          // Skip connection errors in development
          if (
            config.NODE_ENV === 'development' &&
            error.message.includes('ECONNREFUSED')
          ) {
            return null;
          }
        }
      }
      return event;
    },
  });

  logger.info('Sentry initialized');
}

export { Sentry };
