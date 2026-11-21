const express = require('express');
const logger = require('./logger');

function createApp({ db, version }) {
  const app = express();
  app.disable('x-powered-by');

  app.get('/', (req, res) => {
    res.json({ service: 'hello', version });
  });

  app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
  });

  app.get('/items', async (req, res) => {
    try {
      const items = await db.listItems();
      res.json({ count: items.length, items });
    } catch (error) {
      logger.error('Failed to list items', { error: error.message });
      res.status(503).json({ error: 'database unavailable' });
    }
  });

  app.use((req, res) => {
    res.status(404).json({ error: 'not found' });
  });

  return app;
}

module.exports = { createApp };
