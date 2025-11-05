const BASE_DEFAULT = import.meta.env.VITE_API_URL || "http://localhost:3000";
const BOOKS_BASE = import.meta.env.VITE_BOOKS_URL || "http://localhost:4000";
function pickBase(path) {
  return (path.startsWith("/api/books") || path.startsWith("/api/profiles")) ? BOOKS_BASE : BASE_DEFAULT;
}
async function request(path, options = {}) {
  const res = await fetch(`${pickBase(path)}${path}`, {
    headers: { "Content-Type": "application/json", ...(options.headers || {}) },
    ...options,
  });
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`HTTP ${res.status} - ${text || res.statusText}`);
  }
  // 204 No Content
  if (res.status === 204) return null;
  return res.json();
}
export const api = {
  get: (p) => request(p),
  post: (p, body) => request(p, { method: "POST", body: JSON.stringify(body) }),
  put: (p, body) => request(p, { method: "PUT", body: JSON.stringify(body) }),
  del: (p) => request(p, { method: "DELETE" }),
};
