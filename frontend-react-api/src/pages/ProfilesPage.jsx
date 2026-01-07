import { useState } from "react";
import { api } from "../api/client";

export default function ProfilesPage() {
  const [userId, setUserId] = useState("");
  const [profile, setProfile] = useState(null);
  const [err, setErr] = useState("");
  const [loading, setLoading] = useState(false);

  // création
  const [newPreferences, setNewPreferences] = useState("");

  // update
  const [editPreferences, setEditPreferences] = useState("");
  const [historyBook, setHistoryBook] = useState("");
  const [historyRating, setHistoryRating] = useState("");
  const [historyComment, setHistoryComment] = useState("");

  async function loadProfile() {
    if (!userId) return;
    try {
      setLoading(true);
      setErr("");
      const res = await api.get(`/api/profiles/${userId}`);
      setProfile(res);
      setEditPreferences((res.preferences || []).join(", "));
    } catch (e) {
      setProfile(null);
      setErr(e.message);
    } finally {
      setLoading(false);
    }
  }

  async function createProfile(e) {
    e.preventDefault();
    try {
      setErr("");
      const preferences = newPreferences
        .split(",")
        .map((s) => s.trim())
        .filter(Boolean);
      const created = await api.post(`/api/profiles`, {
        userId: Number(userId),
        preferences,
      });
      setProfile(created);
      setNewPreferences("");
      setEditPreferences(preferences.join(", "));
    } catch (e) {
      alert(e.message);
    }
  }

  async function updateProfile(e) {
    e.preventDefault();
    try {
      const preferences = editPreferences
        .split(",")
        .map((s) => s.trim())
        .filter(Boolean);
      const historyEntry = historyBook
        ? {
            book: historyBook,
            rating: historyRating ? Number(historyRating) : undefined,
            comment: historyComment || undefined,
          }
        : undefined;
      const updated = await api.put(`/api/profiles/${userId}`, {
        preferences,
        historyEntry,
      });
      setProfile(updated);
      setHistoryBook("");
      setHistoryRating("");
      setHistoryComment("");
    } catch (e) {
      alert(e.message);
    }
  }

  return (
    <div>
      <h2>Profiles (MongoDB)</h2>

      <div style={{ display: "flex", gap: 8, alignItems: "center", marginBottom: 16 }}>
        <input
          placeholder="userId SQL"
          value={userId}
          onChange={(e) => setUserId(e.target.value)}
          style={{ width: 160 }}
        />
        <button onClick={loadProfile} disabled={!userId || loading}>Charger</button>
      </div>

      {loading && <p>Chargement…</p>}
      {err && <p style={{ color: "crimson" }}>Erreur: {err}</p>}

      {!profile && (
        <form onSubmit={createProfile} style={{ display: "flex", gap: 8, marginBottom: 24 }}>
          <input
            placeholder="preferences (séparées par des virgules)"
            value={newPreferences}
            onChange={(e) => setNewPreferences(e.target.value)}
            style={{ flex: 1 }}
          />
          <button disabled={!userId}>Créer le profil</button>
        </form>
      )}

      {profile && (
        <div>
          <h3>Profil de l’utilisateur #{profile.userId}</h3>
          <pre style={{ background: "#f7f7f7", padding: 12, borderRadius: 8 }}>
            {JSON.stringify(profile, null, 2)}
          </pre>

          <form onSubmit={updateProfile} style={{ display: "grid", gap: 8, marginTop: 16 }}>
            <label>
              Préférences (csv)
              <input
                value={editPreferences}
                onChange={(e) => setEditPreferences(e.target.value)}
                style={{ width: "100%" }}
              />
            </label>

            <fieldset style={{ border: "1px solid #ddd", padding: 12 }}>
              <legend>Ajouter une entrée d’historique</legend>
              <input placeholder="book" value={historyBook} onChange={(e) => setHistoryBook(e.target.value)} />
              <input placeholder="rating (0-5)" type="number" min="0" max="5" step="1" value={historyRating} onChange={(e) => setHistoryRating(e.target.value)} />
              <input placeholder="comment" value={historyComment} onChange={(e) => setHistoryComment(e.target.value)} />
            </fieldset>

            <button>Mettre à jour</button>
          </form>
        </div>
      )}
    </div>
  );
}




