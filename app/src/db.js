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

function createDb(dbConfig) {
  const pool = new Pool({ ...dbConfig, max: 5, connectionTimeoutMillis: 3000 });

  return {
    async migrate() {
      await pool.query(MIGRATION_SQL);
    },
    async listItems() {
      const result = await pool.query('SELECT id, name FROM items ORDER BY id LIMIT 100');
      return result.rows;
    },
    close() {
      return pool.end();
    },
  };
}

module.exports = { createDb };
