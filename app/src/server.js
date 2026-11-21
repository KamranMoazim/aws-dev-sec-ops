const { createApp } = require('./app');
const { createDb } = require('./db');
const { loadConfig } = require('./config');
const logger = require('./logger');

async function start() {
  const config = loadConfig();
  const db = createDb(config.db);

  try {
    await db.migrate();
  } catch (error) {
    logger.error('Database migration failed', { error: error.message });
    process.exit(1);
  }

  const app = createApp({ db, version: config.version });
  const server = app.listen(config.port, () => {
    logger.info('Server started', { port: config.port, version: config.version });
  });

  // ECS sends SIGTERM on deploy/scale-in; drain in-flight requests before exit.
  function shutdown(signal) {
    logger.info('Shutting down', { signal });
    server.close(async () => {
      await db.close();
      process.exit(0);
    });
    setTimeout(() => process.exit(1), 10000).unref();
  }

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

start();
