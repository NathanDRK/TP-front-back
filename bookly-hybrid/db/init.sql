-- Schéma minimal pour l'API hybride (PostgreSQL)
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS books (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  available BOOLEAN NOT NULL DEFAULT TRUE
);

-- Données seed légères pour permettre un test immédiat
INSERT INTO users (name, email)
SELECT 'Alice', 'alice@example.com'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'alice@example.com');

INSERT INTO books (title, author, available)
SELECT '1984', 'George Orwell', TRUE
WHERE NOT EXISTS (SELECT 1 FROM books WHERE title = '1984');

