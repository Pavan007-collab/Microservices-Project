const express = require('express');
const cors = require('cors');
const client = require('prom-client');
const { pool, initSchema } = require('./db');

const app = express();
app.use(express.json());
app.use(cors());

const PORT = process.env.PORT || 3001;
const SERVICE_NAME = 'user-service';
const METRIC_SERVICE_NAME = 'user_service';

function normalizeRoute(path) {
  if (path === '/health' || path === '/users') return path;
  if (path.startsWith('/users/')) return '/users/:id';
  if (path === '/metrics') return '/metrics';
  return path;
}

// Prometheus metrics
client.collectDefaultMetrics();
const httpRequestsTotal = new client.Counter({
  name: `${METRIC_SERVICE_NAME}_http_requests_total`,
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

app.use((req, res, next) => {
  res.on('finish', () => {
    httpRequestsTotal.inc({
      method: req.method,
      route: normalizeRoute(req.path),
      status_code: res.statusCode
    });
  });
  next();
});

// Prometheus metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', service: SERVICE_NAME, db: 'connected' });
  } catch (err) {
    res.status(503).json({ status: 'error', service: SERVICE_NAME, db: 'unreachable' });
  }
});

app.get('/users', async (req, res) => {
  const { rows } = await pool.query('SELECT id, name, email FROM users ORDER BY id');
  res.json(rows);
});

app.get('/users/:id', async (req, res) => {
  const { rows } = await pool.query(
    'SELECT id, name, email FROM users WHERE id = $1',
    [req.params.id]
  );
  if (rows.length === 0) return res.status(404).json({ error: 'User not found' });
  res.json(rows[0]);
});

app.post('/users', async (req, res) => {
  const { name, email } = req.body;
  if (!name || !email) return res.status(400).json({ error: 'name and email required' });
  try {
    const { rows } = await pool.query(
      'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING id, name, email',
      [name, email]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === '23505') return res.status(409).json({ error: 'Email already exists' });
    console.error(err);
    res.status(500).json({ error: 'Internal error' });
  }
});

app.delete('/users/:id', async (req, res) => {
  await pool.query('DELETE FROM users WHERE id = $1', [req.params.id]);
  res.status(204).send();
});

// Retry loop: on first boot the DB (or Cloud SQL Auth Proxy sidecar) may not
// be ready yet, so don't crash-loop the pod - wait and retry.
async function start() {
  const maxAttempts = 10;
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await initSchema();
      app.listen(PORT, () => console.log(`${SERVICE_NAME} listening on port ${PORT}`));
      return;
    } catch (err) {
      console.error(`DB not ready (attempt ${attempt}/${maxAttempts}): ${err.message}`);
      if (attempt === maxAttempts) process.exit(1);
      await new Promise(r => setTimeout(r, 2000));
    }
  }
}

start();
