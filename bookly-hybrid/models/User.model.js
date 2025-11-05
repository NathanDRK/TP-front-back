import { pool } from '../config/db.postgres.js';

export async function getUsers() {
  const { rows } = await pool.query('SELECT id, name, email FROM users ORDER BY id ASC');
  return rows;
}

export async function createUser({ name, email }) {
  const { rows } = await pool.query(
    'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING id, name, email',
    [name, email]
  );
  return rows[0];
}

export async function getUserById(id) {
  const { rows } = await pool.query('SELECT id, name, email FROM users WHERE id = $1', [id]);
  return rows[0] || null;
}

export async function updateUser({ id, name, email }) {
  const { rows } = await pool.query(
    'UPDATE users SET name = $1, email = $2 WHERE id = $3 RETURNING id, name, email',
    [name, email, id]
  );
  return rows[0] || null;
}

export async function deleteUser(id) {
  await pool.query('DELETE FROM users WHERE id = $1', [id]);
}