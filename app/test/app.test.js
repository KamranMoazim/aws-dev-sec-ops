const request = require('supertest');
const { createApp } = require('../src/app');
const { loadConfig } = require('../src/config');

function fakeDb(items) {
  return { listItems: jest.fn().mockResolvedValue(items) };
}

describe('hello service', () => {
  test('GET / returns service name and version', async () => {
    const app = createApp({ db: fakeDb([]), version: 'abc123' });

    const response = await request(app).get('/');

    expect(response.status).toBe(200);
    expect(response.body).toEqual({ service: 'hello', version: 'abc123' });
  });

  test('GET /health returns ok', async () => {
    const app = createApp({ db: fakeDb([]), version: 'dev' });

    const response = await request(app).get('/health');

    expect(response.status).toBe(200);
    expect(response.body).toEqual({ status: 'ok' });
  });

  test('GET /items returns items from the database', async () => {
    const items = [
      { id: 1, name: 'first' },
      { id: 2, name: 'second' },
    ];
    const app = createApp({ db: fakeDb(items), version: 'dev' });

    const response = await request(app).get('/items');

    expect(response.status).toBe(200);
    expect(response.body).toEqual({ count: 2, items });
  });

  test('GET /items returns 503 when the database fails', async () => {
    const db = { listItems: jest.fn().mockRejectedValue(new Error('connection refused')) };
    const app = createApp({ db, version: 'dev' });
    jest.spyOn(process.stdout, 'write').mockImplementation(() => true);

    const response = await request(app).get('/items');

    expect(response.status).toBe(503);
    expect(response.body).toEqual({ error: 'database unavailable' });
  });

  test('unknown route returns 404 without x-powered-by header', async () => {
    const app = createApp({ db: fakeDb([]), version: 'dev' });

    const response = await request(app).get('/nope');

    expect(response.status).toBe(404);
    expect(response.headers['x-powered-by']).toBeUndefined();
  });
});

describe('loadConfig', () => {
  test('uses defaults when env is empty', () => {
    const config = loadConfig({});

    expect(config.port).toBe(3000);
    expect(config.version).toBe('dev');
    expect(config.db.ssl).toBe(false);
  });

  test('reads values from env', () => {
    const config = loadConfig({ PORT: '8080', APP_VERSION: 'v1', DB_HOST: 'db', DB_SSL: 'true' });

    expect(config.port).toBe(8080);
    expect(config.version).toBe('v1');
    expect(config.db.host).toBe('db');
    expect(config.db.ssl).toEqual({ rejectUnauthorized: false });
  });
});
