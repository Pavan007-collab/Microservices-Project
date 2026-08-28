const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'products_db',
  max: 10,
  idleTimeoutMillis: 30000
});

async function initSchema() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS products (
      id SERIAL PRIMARY KEY,
      name TEXT NOT NULL,
      price NUMERIC(10,2) NOT NULL,
      stock INTEGER NOT NULL DEFAULT 0
    );
  `);

  const { rows } = await pool.query('SELECT COUNT(*)::int AS count FROM products');
  if (rows[0].count === 0) {
    await pool.query(
      `INSERT INTO products (name, price, stock) VALUES
         ('Wireless Mouse', 799, 50),
         ('Mechanical Keyboard', 3499, 20),
         ('USB-C Hub', 1299, 35)`
    );
  }
}

module.exports = { pool, initSchema };
