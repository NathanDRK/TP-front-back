import { pool } from '../config/db.postgres.js';

export async function getBooks() {
  const { rows } = await pool.query(
    'SELECT id, title, author, available FROM books ORDER BY id ASC'
  );
  return rows;
}

export async function createBook({ title, author, available = true }) {
  const { rows } = await pool.query(
    'INSERT INTO books (title, author, available) VALUES ($1, $2, $3) RETURNING id, title, author, available',
    [title, author, available]
  );
  return rows[0];
}

