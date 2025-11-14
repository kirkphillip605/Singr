import { AppError } from '@singr/shared';
import { FastifyInstance, FastifyError, FastifyReply, FastifyRequest } from 'fastify';
import fp from 'fastify-plugin';
import { ZodError } from 'zod';

async function errorHandlerPlugin(fastify: FastifyInstance) {
  fastify.setErrorHandler(
    async (error: FastifyError | AppError | Error, request: FastifyRequest, reply: FastifyReply) => {
      request.log.error(error);

      // Handle Zod validation errors
      if (error instanceof ZodError) {
        return reply.status(400).send({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Validation failed',
            details: error.errors,
          },
        });
      }

      // Handle custom AppError
      if (error instanceof AppError) {
        return reply.status(error.statusCode).send({
          success: false,
          error: {
            code: error.code,
            message: error.message,
            details: error.details,
          },
        });
      }

      // Handle Fastify errors
      if ('statusCode' in error) {
        return reply.status(error.statusCode || 500).send({
          success: false,
          error: {
            code: error.code || 'INTERNAL_ERROR',
            message: error.message,
          },
        });
      }

      // Handle unknown errors
      return reply.status(500).send({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'An unexpected error occurred',
        },
      });
    }
  );
}

export default fp(errorHandlerPlugin, {
  name: 'error-handler',
});
