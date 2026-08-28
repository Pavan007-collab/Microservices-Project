const express = require('express');
const cors = require('cors');
const axios = require('axios');
const { pool, initSchema } = require('./db');

const app = express();
app.use(express.json());
app.use(cors());

const PORT = process.env.PORT || 3003;
const SERVICE_NAME = 'order-service';

const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'http://localhost:3001';
const PRODUCT_SERVICE_URL = process.env.PRODUCT_SERVICE_URL || 'http://localhost:3002';

app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', service: SERVICE_NAME, db: 'connected' });
  } catch (err) {
    res.status(503).json({ status: 'error', service: SERVICE_NAME, db: 'unreachable' });
  }
});

app.get('/orders', async (req, res) => {
  const { rows } = await pool.query('SELECT * FROM orders ORDER BY id DESC');
  res.json(rows);
});

app.get('/orders/:id', async (req, res) => {
  const { rows } = await pool.query('SELECT * FROM orders WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ error: 'Order not found' });
  res.json(rows[0]);
});

app.post('/orders', async (req, res) => {
  const { userId, productId, quantity } = req.body;
  if (!userId || !productId || !quantity) {
    return res.status(400).json({ error: 'userId, productId, quantity required' });
  }

  try {
    const [userRes, productRes] = await Promise.all([
      axios.get(`${USER_SERVICE_URL}/users/${userId}`),
      axios.get(`${PRODUCT_SERVICE_URL}/products/${productId}`)
    ]);
    const user = userRes.data;
    const product = productRes.data;

    // Atomic decrement - product-service rejects this with 409 if stock would
    // go negative, so we never oversell even under concurrent requests.
    let updatedProduct;
    try {
      const stockRes = await axios.patch(
        `${PRODUCT_SERVICE_URL}/products/${productId}/stock`,
        { delta: -quantity }
      );
      updatedProduct = stockRes.data;
    } catch (stockErr) {
      if (stockErr.response && stockErr.response.status === 409) {
        return res.status(409).json({ error: 'Insufficient stock' });
      }
      throw stockErr;
    }

    const totalPrice = product.price * quantity;
    const { rows } = await pool.query(
      `INSERT INTO orders (user_id, user_name, product_id, product_name, quantity, total_price)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [userId, user.name, productId, product.name, quantity, totalPrice]
    );

    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.response && err.response.status === 404) {
      return res.status(404).json({ error: 'User or product not found' });
    }
    console.error(err.message);
    res.status(502).json({ error: 'Upstream service error', detail: err.message });
  }
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
