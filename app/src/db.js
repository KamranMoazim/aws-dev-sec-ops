const { Pool } = require('pg');

function createDb(dbConfig) {
  const pool = new Pool({ ...dbConfig, max: 5, connectionTimeoutMillis: 3000 });

  return {
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
