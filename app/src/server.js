const { createApp } = require('./app');
const { SecretsManagerClient } = require('@aws-sdk/client-secrets-manager');
const { createDb } = require('./db');
const { createSecretPassword } = require('./secret-password');
const { loadConfig } = require('./config');
const logger = require('./logger');

async function start() {
  const config = loadConfig();
  const secretPassword = config.db.secretArn
    ? createSecretPassword({ secretArn: config.db.secretArn, client: new SecretsManagerClient({}) })
    : undefined;
  const db = createDb(config.db, { secretPassword });

  try {
    await db.migrate();
  } catch (error) {
    logger.error('Database migration failed', { error: error.message });
    process.exit(1);
  }

  const app = createApp({ db, version: config.version });
  const server = app.listen(config.port, () => {
    logger.info('Server started', {
      port: config.port,
      version: config.version,
      commit: config.commit,
    });
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
