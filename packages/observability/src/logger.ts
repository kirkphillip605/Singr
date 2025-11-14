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
      'token',
      'secret',
    ],
    remove: true,
  },
  serializers: {
    req: (req: any) => ({
      method: req.method,
      url: req.url,
      headers: {
        host: req.headers?.host,
        'user-agent': req.headers?.['user-agent'],
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

/**
 * Create a child logger with additional context
 */
export function createLogger(module: string) {
  return logger.child({ module });
}

/**
 * Log levels for convenience
 */
export const LogLevel = {
  FATAL: 'fatal',
  ERROR: 'error',
  WARN: 'warn',
  INFO: 'info',
  DEBUG: 'debug',
  TRACE: 'trace',
} as const;

export type LogLevel = (typeof LogLevel)[keyof typeof LogLevel];
