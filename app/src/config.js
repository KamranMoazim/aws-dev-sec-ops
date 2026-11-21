function loadConfig(env = process.env) {
  return {
    port: Number(env.PORT || 3000),
    version: env.APP_VERSION || 'dev',
    db: {
      host: env.DB_HOST || 'localhost',
      port: Number(env.DB_PORT || 5432),
      user: env.DB_USER || 'hello',
      password: env.DB_PASSWORD || '',
      database: env.DB_NAME || 'hello',
      ssl: env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
    },
  };
}

module.exports = { loadConfig };
