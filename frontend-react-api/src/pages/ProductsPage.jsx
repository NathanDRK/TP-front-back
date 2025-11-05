import { useEffect, useState } from "react";
import { api } from "../api/client";

export default function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState("");

  // form
  const [name, setName] = useState("");
  const [price, setPrice] = useState("");

  // edition inline
  const [editingId, setEditingId] = useState(null);
  const [editName, setEditName] = useState("");
  const [editPrice, setEditPrice] = useState("");

  async function load() {
    try {
      setLoading(true);
      setErr("");
      const res = await api.get("/api/products");
      setProducts(res.data ?? res);
    } catch (e) {
      setErr(e.message);
    } finally {
      setLoading(false);
    }
  }
  useEffect(() => {
    load();
  }, []);

  async function createProduct(e) {
    e.preventDefault();
    try {
      const created = await api.post("/api/products", {
        name,
        price: Number(price),
      });
      const current = Array.isArray(products) ? products : products.data;
      setProducts(Array.isArray(products) ? [...current, created] : { ...(products || {}), data: [...current, created] });
      setName("");
      setPrice("");
    } catch (e) {
      alert(e.message);
    }
  }

  async function deleteProduct(id) {
    if (!confirm("Supprimer ce produit ?")) return;
    const prev = products;
    const current = Array.isArray(products) ? products : products.data;
    setProducts(Array.isArray(products) ? current.filter((p) => p.id !== id) : { ...(products || {}), data: current.filter((p) => p.id !== id) });
    try {
      await api.del(`/api/products/${id}`);
    } catch (e) {
      alert("Suppression échouée, retour état précédent");
      setProducts(prev);
    }
  }

  function startEdit(p) {
    setEditingId(p.id);
    setEditName(p.name);
    setEditPrice(String(p.price));
  }
  function cancelEdit() {
    setEditingId(null);
  }
  async function saveEdit(id) {
    try {
      const updated = await api.put(`/api/products/${id}`, {
        name: editName,
        price: Number(editPrice),
      });
      const current = Array.isArray(products) ? products : products.data;
      const next = current.map((p) => (p.id === id ? updated : p));
      setProducts(Array.isArray(products) ? next : { ...(products || {}), data: next });
      setEditingId(null);
    } catch (e) {
      alert(e.message);
    }
  }

  if (loading) return <p>Chargement…</p>;
  if (err) return <p style={{ color: "crimson" }}>Erreur: {err}</p>;
  const list = Array.isArray(products) ? products : products.data;

  return (
    <div>
      <h2>Products</h2>
      <form onSubmit={createProduct} style={{ display: "flex", gap: 8, marginBottom: 16 }}>
        <input placeholder="name" value={name} onChange={(e) => setName(e.target.value)} required />
        <input placeholder="price" type="number" step="0.01" value={price} onChange={(e) => setPrice(e.target.value)} required />
        <button>Ajouter</button>
      </form>

      <table width="100%" cellPadding="8" style={{ borderCollapse: "collapse" }}>
        <thead>
          <tr>
            <th align="left">ID</th>
            <th align="left">Name</th>
            <th align="left">Price</th>
            <th align="left">Actions</th>
          </tr>
        </thead>
        <tbody>
          {list.map((p) => (
            <tr key={p.id} style={{ borderTop: "1px solid #ddd" }}>
              <td>{p.id}</td>
              {editingId === p.id ? (
                <>
                  <td>
                    <input value={editName} onChange={(e) => setEditName(e.target.value)} />
                  </td>
                  <td>
                    <input type="number" step="0.01" value={editPrice} onChange={(e) => setEditPrice(e.target.value)} />
                  </td>
                  <td>
                    <button onClick={() => saveEdit(p.id)}>Sauver</button>
                    <button onClick={cancelEdit}>Annuler</button>
                  </td>
                </>
              ) : (
                <>
                  <td>{p.name}</td>
                  <td>{p.price}</td>
                  <td>
                    <button onClick={() => startEdit(p)}>Éditer</button>
                    <button onClick={() => deleteProduct(p.id)}>Supprimer</button>
                  </td>
                </>
              )}
            </tr>
          ))}

          {list.length === 0 && (
            <tr>
              <td colSpan="4">Aucun produit pour le moment.</td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}



