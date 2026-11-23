const { Pool } = require('pg');

const MIGRATION_SQL = `
  CREATE TABLE IF NOT EXISTS items (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
  );
  INSERT INTO items (name)
  SELECT seed.name FROM (VALUES ('alpha'), ('beta'), ('gamma')) AS seed(name)
  WHERE NOT EXISTS (SELECT 1 FROM items);
`;

const INVALID_PASSWORD = '28P01';

function createDb(dbConfig, { secretPassword } = {}) {
  const pool = new Pool({
    ...dbConfig,
    password: secretPassword ? () => secretPassword.get() : dbConfig.password,
    max: 5,
    connectionTimeoutMillis: 3000,
  });

  // A rotated password invalidates the cached one; the next connection fetches the new value.
  async function query(sql) {
    try {
      return await pool.query(sql);
    } catch (error) {
      if (secretPassword && error.code === INVALID_PASSWORD) {
        secretPassword.invalidate();
      }
      throw error;
    }
  }

  return {
    async migrate() {
      await query(MIGRATION_SQL);
    },
    async listItems() {
      const result = await query('SELECT id, name FROM items ORDER BY id LIMIT 100');
      return result.rows;
    },
    close() {
      return pool.end();
    },
  };
}

module.exports = { createDb };
