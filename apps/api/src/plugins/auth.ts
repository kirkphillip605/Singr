import { verifyToken } from '@singr/auth';
import { AuthenticationError } from '@singr/shared';
import { FastifyInstance, FastifyRequest } from 'fastify';
import fp from 'fastify-plugin';

declare module 'fastify' {
  interface FastifyRequest {
    user?: {
      userId: string;
      email: string;
      roles: string[];
    };
  }
}

async function authPlugin(fastify: FastifyInstance) {
  // Decorator to check authentication
  fastify.decorate('authenticate', async (request: FastifyRequest) => {
    try {
      const authHeader = request.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        throw new AuthenticationError('Missing or invalid authorization header');
      }

      const token = authHeader.substring(7); // Remove 'Bearer ' prefix
      const payload = verifyToken(token);

      if (payload.type !== 'access') {
        throw new AuthenticationError('Invalid token type');
      }

      request.user = {
        userId: payload.userId,
        email: payload.email,
        roles: payload.roles,
      };
    } catch (error) {
      if (error instanceof AuthenticationError) {
        throw error;
      }
      throw new AuthenticationError('Invalid or expired token');
    }
  });
}

export default fp(authPlugin, {
  name: 'auth-plugin',
});
