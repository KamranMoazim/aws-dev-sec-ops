const request = require('supertest');
const { createApp } = require('../src/app');
const { loadConfig } = require('../src/config');
const packageJson = require('../package.json');

function fakeDb(items) {
  return { listItems: jest.fn().mockResolvedValue(items) };
}

describe('hello service', () => {
  test('GET / returns service name and semantic version without build details', async () => {
    const app = createApp({ db: fakeDb([]), version: '1.2.3' });

    const response = await request(app).get('/');

    expect(response.status).toBe(200);
    expect(response.body).toEqual({ service: 'hello', version: '1.2.3' });
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
  test('version comes from package.json as semver', () => {
    expect(loadConfig({}).version).toMatch(/^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$/);
  });

  test('uses defaults when env is empty', () => {
    const config = loadConfig({});

    expect(config.port).toBe(3000);
    expect(config.version).toBe(packageJson.version);
    expect(config.commit).toBe('local');
    expect(config.db.ssl).toBe(false);
  });

  test('reads values from env', () => {
    const config = loadConfig({
      PORT: '8080',
      APP_COMMIT: 'abc1234',
      DB_HOST: 'db',
      DB_SSL: 'true',
    });

    expect(config.port).toBe(8080);
    expect(config.commit).toBe('abc1234');
    expect(config.db.host).toBe('db');
    expect(config.db.ssl).toEqual({ rejectUnauthorized: false });
  });
});
