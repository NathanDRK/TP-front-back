import { useEffect, useState } from "react";
import { api } from "../api/client";

export default function BooksPage() {
  const [books, setBooks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState("");

  // form
  const [title, setTitle] = useState("");
  const [author, setAuthor] = useState("");
  const [available, setAvailable] = useState(true);

  async function load() {
    try {
      setLoading(true);
      setErr("");
      const res = await api.get("/api/books");
      setBooks(res.data ?? res);
    } catch (e) {
      setErr(e.message);
    } finally {
      setLoading(false);
    }
  }
  useEffect(() => {
    load();
  }, []);

  async function createBook(e) {
    e.preventDefault();
    try {
      const created = await api.post("/api/books", {
        title,
        author,
        available,
      });
      const current = Array.isArray(books) ? books : books.data;
      setBooks(Array.isArray(books) ? [...current, created] : { ...(books || {}), data: [...current, created] });
      setTitle("");
      setAuthor("");
      setAvailable(true);
    } catch (e) {
      alert(e.message);
    }
  }

  if (loading) return <p>Chargement…</p>;
  if (err) return <p style={{ color: "crimson" }}>Erreur: {err}</p>;
  const list = Array.isArray(books) ? books : books.data;

  return (
    <div>
      <h2>Books</h2>
      <form onSubmit={createBook} style={{ display: "flex", gap: 8, marginBottom: 16 }}>
        <input placeholder="title" value={title} onChange={(e) => setTitle(e.target.value)} required />
        <input placeholder="author" value={author} onChange={(e) => setAuthor(e.target.value)} required />
        <label style={{ display: "flex", alignItems: "center", gap: 4 }}>
          <input type="checkbox" checked={available} onChange={(e) => setAvailable(e.target.checked)} />
          available
        </label>
        <button>Ajouter</button>
      </form>

      <table width="100%" cellPadding="8" style={{ borderCollapse: "collapse" }}>
        <thead>
          <tr>
            <th align="left">ID</th>
            <th align="left">Title</th>
            <th align="left">Author</th>
            <th align="left">Available</th>
          </tr>
        </thead>
        <tbody>
          {list.map((b) => (
            <tr key={b.id} style={{ borderTop: "1px solid #ddd" }}>
              <td>{b.id}</td>
              <td>{b.title}</td>
              <td>{b.author}</td>
              <td>{String(b.available)}</td>
            </tr>
          ))}

          {list.length === 0 && (
            <tr>
              <td colSpan="4">Aucun livre pour le moment.</td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}




