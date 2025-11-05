import { getBooks, createBook } from '../models/Book.model.js';

export async function listBooks(req, res) {
  try {
    const books = await getBooks();
    res.json(books);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}

export async function addBook(req, res) {
  try {
    const { title, author, available } = req.body;
    if (!title || !author) return res.status(400).json({ error: 'title & author required' });
    const book = await createBook({ title, author, available });
    res.status(201).json(book);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}