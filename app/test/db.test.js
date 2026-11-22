const mockQuery = jest.fn();
let mockPoolConfig;

jest.mock('pg', () => ({
  Pool: jest.fn().mockImplementation((config) => {
    mockPoolConfig = config;
    return { query: mockQuery, end: jest.fn() };
  }),
}));

const { createDb } = require('../src/db');

describe('createDb', () => {
  beforeEach(() => {
    mockQuery.mockReset();
  });

  test('uses the static password when no secret is configured', () => {
    createDb({ host: 'db', password: 'local' });

    expect(mockPoolConfig.password).toBe('local');
  });

  test('asks the secret for a password on every new connection', async () => {
    const secretPassword = {
      get: jest.fn().mockResolvedValue('from-secret'),
      invalidate: jest.fn(),
    };
    createDb({ host: 'db', password: '' }, { secretPassword });

    expect(await mockPoolConfig.password()).toBe('from-secret');
  });

  test('drops the cached password when the database rejects it', async () => {
    const secretPassword = { get: jest.fn(), invalidate: jest.fn() };
    const authFailure = Object.assign(new Error('password authentication failed'), {
      code: '28P01',
    });
    mockQuery.mockRejectedValueOnce(authFailure);
    const db = createDb({ host: 'db' }, { secretPassword });

    await expect(db.listItems()).rejects.toThrow('password authentication failed');

    expect(secretPassword.invalidate).toHaveBeenCalledTimes(1);
  });

  test('keeps the cached password for other errors', async () => {
    const secretPassword = { get: jest.fn(), invalidate: jest.fn() };
    mockQuery.mockRejectedValueOnce(Object.assign(new Error('timeout'), { code: 'ETIMEDOUT' }));
    const db = createDb({ host: 'db' }, { secretPassword });

    await expect(db.listItems()).rejects.toThrow('timeout');

    expect(secretPassword.invalidate).not.toHaveBeenCalled();
  });
});
