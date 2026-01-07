import { useEffect, useState } from "react";
import { api } from "../api/client";
export default function UsersPage() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState("");
  
  // form
  const [name, setName] = useState("");
  const [age, setAge] = useState("");

  // édition inline
  const [editingId, setEditingId] = useState(null);
  const [editName, setEditName] = useState("");
  const [editAge, setEditAge] = useState("");

  async function load() {
    try {
      setLoading(true);
      setErr("");
      const res = await api.get("/api/users");
      setUsers(res.data ?? res); // selon ton contrôleur (liste ou {total,data})
    } catch (e) {
      setErr(e.message);
    } finally {
      setLoading(false);
    }
  }
  useEffect(() => {
    load();
  }, []);

  async function createUser(e) {
    e.preventDefault();
    try {
      const created = await api.post("/api/users", { name, age: Number(age) });
      setUsers((u) => [...(Array.isArray(u) ? u : u.data), created]);
      setName("");
      setAge("");
    } catch (e) {
      alert(e.message);
    }
  }

  async function deleteUser(id) {
    if (!confirm("Supprimer cet utilisateur ?")) return;
    const prev = users;
    // Optimistic UI
    setUsers((Array.isArray(users) ? users : users.data).filter((u) => u.id !== id));
    try {
      await api.del(`/api/users/${id}`);
    } catch (e) {
      alert("Suppression échouée, retour état précédent");
      setUsers(prev);
    }
  }

  // ----- ÉDITION INLINE -----
  function startEdit(u) {
    setEditingId(u.id);
    setEditName(u.name);
    setEditAge(String(u.age ?? ""));
  }
  function cancelEdit() {
    setEditingId(null);
  }
  async function saveEdit(id) {
    try {
      const updated = await api.put(`/api/users/${id}`, { name: editName, age: Number(editAge) });
      const current = Array.isArray(users) ? users : users.data;
      const next = current.map((u) => (u.id === id ? updated : u));
      setUsers(Array.isArray(users) ? next : { ...(users || {}), data: next });
      setEditingId(null);
    } catch (e) {
      alert(e.message);
    }
  }
  // --------------------------

  if (loading) return <p>Chargement…</p>;
  if (err) return <p style={{ color: "crimson" }}>Erreur: {err}</p>;
  const list = Array.isArray(users) ? users : users.data;

  return (
    <div>
      <h2>Users</h2>
      <form
        onSubmit={createUser}
        style={{ display: "flex", gap: 8, marginBottom: 16 }}
      >
        <input
          placeholder="name"
          value={name}
          onChange={(e) => setName(e.target.value)}
          required
        />
        <input
          placeholder="age"
          type="number"
          min="0"
          value={age}
          onChange={(e) => setAge(e.target.value)}
          required
        />
        <button>Ajouter</button>
      </form>

      <table
        width="100%"
        cellPadding="8"
        style={{ borderCollapse: "collapse" }}
      >
        <thead>
          <tr>
            <th align="left">ID</th>
            <th align="left">Name</th>
            <th align="left">Age</th>
            <th align="left">Actions</th>
          </tr>
        </thead>
        <tbody>
          {list.map((u) => (
            <tr key={u.id} style={{ borderTop: "1px solid #ddd" }}>
              <td>{u.id}</td>

              {editingId === u.id ? (
                <>
                  <td>
                    <input
                      value={editName}
                      onChange={(e) => setEditName(e.target.value)}
                    />
                  </td>
                  <td>
                    <input
                      type="number"
                      min="0"
                      value={editAge}
                      onChange={(e) => setEditAge(e.target.value)}
                    />
                  </td>
                  <td>
                    <button onClick={() => saveEdit(u.id)}>Sauver</button>
                    <button onClick={cancelEdit}>Annuler</button>
                  </td>
                </>
              ) : (
                <>
                  <td>{u.name}</td>
                  <td>{u.age}</td>
                  <td>
                    <button onClick={() => startEdit(u)}>Éditer</button>
                    <button onClick={() => deleteUser(u.id)}>Supprimer</button>
                  </td>
                </>
              )}
            </tr>
          ))}

          {list.length === 0 && (
            <tr>
              <td colSpan="4">Aucun utilisateur pour le moment.</td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}