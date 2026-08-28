const express = require('express');
const cors = require('cors');
const { pool, initSchema } = require('./db');

const app = express();
app.use(express.json());
app.use(cors());

const PORT = process.env.PORT || 3002;
const SERVICE_NAME = 'product-service';

app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', service: SERVICE_NAME, db: 'connected' });
  } catch (err) {
    res.status(503).json({ status: 'error', service: SERVICE_NAME, db: 'unreachable' });
  }
});

app.get('/products', async (req, res) => {
  const { rows } = await pool.query('SELECT id, name, price, stock FROM products ORDER BY id');
  res.json(rows);
});

app.get('/products/:id', async (req, res) => {
  const { rows } = await pool.query(
    'SELECT id, name, price, stock FROM products WHERE id = $1',
    [req.params.id]
  );
  if (rows.length === 0) return res.status(404).json({ error: 'Product not found' });
  res.json(rows[0]);
});

app.post('/products', async (req, res) => {
  const { name, price, stock } = req.body;
  if (!name || price == null) return res.status(400).json({ error: 'name and price required' });
  const { rows } = await pool.query(
    'INSERT INTO products (name, price, stock) VALUES ($1, $2, $3) RETURNING id, name, price, stock',
    [name, price, stock || 0]
  );
  res.status(201).json(rows[0]);
});

// Atomic, race-safe stock update - guards against overselling under concurrent orders.
app.patch('/products/:id/stock', async (req, res) => {
  const { delta } = req.body;
  const { rows } = await pool.query(
    `UPDATE products SET stock = stock + $1
     WHERE id = $2 AND stock + $1 >= 0
     RETURNING id, name, price, stock`,
    [delta, req.params.id]
  );
  if (rows.length === 0) {
    return res.status(409).json({ error: 'Insufficient stock or product not found' });
  }
  res.json(rows[0]);
});

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
