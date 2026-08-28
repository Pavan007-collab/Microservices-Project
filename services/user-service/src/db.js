const { Pool } = require('pg');

// Connection settings come from env vars so the same code works unchanged
// across docker-compose, Kubernetes, and Cloud SQL (see README "Database" section).
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'users_db',
  max: 10,
  idleTimeoutMillis: 30000
});

async function initSchema() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      created_at TIMESTAMPTZ DEFAULT now()
    );
  `);

  const { rows } = await pool.query('SELECT COUNT(*)::int AS count FROM users');
  if (rows[0].count === 0) {
    await pool.query(
      `INSERT INTO users (name, email) VALUES
         ('Aarav Sharma', 'aarav@example.com'),
         ('Priya Nair', 'priya@example.com')`
    );
  }
}

module.exports = { pool, initSchema };
