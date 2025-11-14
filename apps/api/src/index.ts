import { config } from '@singr/config';
import { logger, initSentry } from '@singr/observability';

import { createServer } from './server';

async function start() {
  try {
    // Initialize Sentry for error tracking
    if (config.SENTRY_DSN) {
      initSentry();
    }

    // Create and start server
    const server = await createServer();

    await server.listen({
      port: config.PORT,
      host: '0.0.0.0',
    });

    logger.info(
      `🚀 Server running on http://localhost:${config.PORT}`
    );
    logger.info(
      `📖 API Documentation available at http://localhost:${config.PORT}/docs`
    );

    // Graceful shutdown
    const signals = ['SIGINT', 'SIGTERM'];
    signals.forEach((signal) => {
      process.on(signal, async () => {
        logger.info(`Received ${signal}, shutting down gracefully...`);
        await server.close();
        process.exit(0);
      });
    });
  } catch (error) {
    logger.error(error, 'Error starting server');
    process.exit(1);
  }
}

start();
