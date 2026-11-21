function write(level, message, fields = {}) {
  const line = JSON.stringify({ time: new Date().toISOString(), level, message, ...fields });
  process.stdout.write(`${line}\n`);
}

module.exports = {
  info: (message, fields) => write('info', message, fields),
  warn: (message, fields) => write('warn', message, fields),
  error: (message, fields) => write('error', message, fields),
};
