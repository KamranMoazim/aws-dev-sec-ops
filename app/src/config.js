const { version } = require('../package.json');

function loadConfig(env = process.env) {
  return {
    port: Number(env.PORT || 3000),
    version,
    commit: env.APP_COMMIT || 'local',
    db: {
      host: env.DB_HOST || 'localhost',
      port: Number(env.DB_PORT || 5432),
      user: env.DB_USER || 'hello',
      password: env.DB_PASSWORD || '',
      secretArn: env.DB_SECRET_ARN || null,
      database: env.DB_NAME || 'hello',
      ssl: env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
    },
  };
}

module.exports = { loadConfig };
