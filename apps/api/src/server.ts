import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';
import { config, corsOrigins } from '@singr/config';
import { logger } from '@singr/observability';
import Fastify from 'fastify';

import healthRoutes from './routes/health';

export async function createServer() {
  const fastify = Fastify({
    logger: logger as any,
    requestIdHeader: 'x-request-id',
    requestIdLogLabel: 'reqId',
    disableRequestLogging: false,
  });

  // Register plugins
  await fastify.register(helmet, {
    contentSecurityPolicy: false, // Disable for development
  });

  await fastify.register(cors, {
    origin: corsOrigins,
    credentials: true,
  });

  await fastify.register(rateLimit, {
    max: 100,
    timeWindow: '1 minute',
  });

  // Swagger documentation
  await fastify.register(swagger, {
    swagger: {
      info: {
        title: 'Singr API',
        description: 'Singr Central API Backend Documentation',
        version: '1.0.0',
      },
      externalDocs: {
        url: 'https://singrkaraoke.com',
        description: 'Find more info here',
      },
      host: `localhost:${config.PORT}`,
      schemes: ['http', 'https'],
      consumes: ['application/json'],
      produces: ['application/json'],
      tags: [
        { name: 'health', description: 'Health check endpoints' },
        { name: 'auth', description: 'Authentication endpoints' },
        { name: 'venues', description: 'Venue management endpoints' },
        { name: 'requests', description: 'Request management endpoints' },
      ],
      securityDefinitions: {
        bearerAuth: {
          type: 'apiKey',
          name: 'Authorization',
          in: 'header',
        },
      },
    },
  });

  await fastify.register(swaggerUi, {
    routePrefix: '/docs',
    uiConfig: {
      docExpansion: 'list',
      deepLinking: false,
    },
  });

  // Custom plugins
  const errorHandler = await import('./plugins/errorHandler');
  const authPlugin = await import('./plugins/auth');
  await fastify.register(errorHandler.default);
  await fastify.register(authPlugin.default);

  // Register routes
  await fastify.register(healthRoutes, { prefix: '/health' });

  return fastify;
}
