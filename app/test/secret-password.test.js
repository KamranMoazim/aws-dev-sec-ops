const { createSecretPassword } = require('../src/secret-password');

function fakeClient(passwords) {
  const remaining = [...passwords];
  return {
    send: jest.fn().mockImplementation(async () => ({
      SecretString: JSON.stringify({ username: 'hello_admin', password: remaining.shift() }),
    })),
  };
}

describe('createSecretPassword', () => {
  test('fetches the password once and serves it from cache', async () => {
    const client = fakeClient(['first']);
    const secret = createSecretPassword({ secretArn: 'arn:secret', client });

    expect(await secret.get()).toBe('first');
    expect(await secret.get()).toBe('first');
    expect(client.send).toHaveBeenCalledTimes(1);
    expect(client.send.mock.calls[0][0].input).toEqual({ SecretId: 'arn:secret' });
  });

  test('shares one request between concurrent callers', async () => {
    const client = fakeClient(['first']);
    const secret = createSecretPassword({ secretArn: 'arn:secret', client });

    await Promise.all([secret.get(), secret.get(), secret.get()]);

    expect(client.send).toHaveBeenCalledTimes(1);
  });

  test('re-fetches after invalidate, e.g. when the password was rotated', async () => {
    const client = fakeClient(['old', 'rotated']);
    const secret = createSecretPassword({ secretArn: 'arn:secret', client });

    expect(await secret.get()).toBe('old');
    secret.invalidate();

    expect(await secret.get()).toBe('rotated');
  });

  test('re-fetches once the cache expires', async () => {
    let clock = 0;
    const client = fakeClient(['old', 'rotated']);
    const secret = createSecretPassword({
      secretArn: 'arn:secret',
      client,
      ttlMs: 1000,
      now: () => clock,
    });

    expect(await secret.get()).toBe('old');
    clock = 1001;

    expect(await secret.get()).toBe('rotated');
  });

  test('does not cache a failed fetch', async () => {
    const client = { send: jest.fn().mockRejectedValueOnce(new Error('throttled')) };
    client.send.mockResolvedValueOnce({ SecretString: JSON.stringify({ password: 'ok' }) });
    const secret = createSecretPassword({ secretArn: 'arn:secret', client });

    await expect(secret.get()).rejects.toThrow('throttled');

    expect(await secret.get()).toBe('ok');
  });
});
