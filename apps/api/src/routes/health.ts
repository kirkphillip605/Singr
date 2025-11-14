import { prisma } from '@singr/database';
import { FastifyInstance } from 'fastify';

export default async function healthRoutes(fastify: FastifyInstance) {
  // Basic health check
  fastify.get('/', {
    schema: {
      tags: ['health'],
      description: 'Basic health check',
      response: {
        200: {
          type: 'object',
          properties: {
            status: { type: 'string' },
            timestamp: { type: 'string' },
          },
        },
      },
    },
  }, async () => {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
    };
  });

  // Detailed health check
  fastify.get('/detailed', {
    schema: {
      tags: ['health'],
      description: 'Detailed health check including database',
      response: {
        200: {
          type: 'object',
          properties: {
            status: { type: 'string' },
            timestamp: { type: 'string' },
            services: { type: 'object' },
          },
        },
      },
    },
  }, async (_request, reply) => {
    const services: Record<string, { status: string; message?: string }> = {};

    // Check database
    try {
      await prisma.$queryRaw`SELECT 1`;
      services.database = { status: 'ok' };
    } catch (error) {
      services.database = {
        status: 'error',
        message: error instanceof Error ? error.message : 'Unknown error',
      };
    }

    const allHealthy = Object.values(services).every(s => s.status === 'ok');

    return reply.status(allHealthy ? 200 : 503).send({
      status: allHealthy ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
      services,
    });
  });

  // Readiness check
  fastify.get('/ready', {
    schema: {
      tags: ['health'],
      description: 'Readiness check for K8s',
    },
  }, async (_request, reply) => {
    try {
      await prisma.$queryRaw`SELECT 1`;
      return reply.status(200).send({ ready: true });
    } catch (error) {
      return reply.status(503).send({ ready: false });
    }
  });

  // Liveness check
  fastify.get('/live', {
    schema: {
      tags: ['health'],
      description: 'Liveness check for K8s',
    },
  }, async () => {
    return { alive: true };
  });
}
