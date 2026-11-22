const { GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');

const DEFAULT_TTL_MS = 5 * 60 * 1000;

function createSecretPassword({ secretArn, client, ttlMs = DEFAULT_TTL_MS, now = Date.now }) {
  let cached = null;
  let pending = null;

  async function fetchPassword() {
    const response = await client.send(new GetSecretValueCommand({ SecretId: secretArn }));
    return JSON.parse(response.SecretString).password;
  }

  return {
    get() {
      if (cached && now() < cached.expiresAt) {
        return Promise.resolve(cached.password);
      }
      if (!pending) {
        pending = fetchPassword()
          .then((password) => {
            cached = { password, expiresAt: now() + ttlMs };
            return password;
          })
          .finally(() => {
            pending = null;
          });
      }
      return pending;
    },
    invalidate() {
      cached = null;
    },
  };
}

module.exports = { createSecretPassword };
