import { Outlet, NavLink } from "react-router-dom";

export default function App() {
  return (
    <div style={{ maxWidth: 900, margin: "0 auto", padding: 24 }}>
      <h1>Docker frontend et backend</h1>
      <nav style={{ display: "flex", gap: 12, marginBottom: 16 }}>
        <NavLink to="/">Users</NavLink>
        <NavLink to="/products">Products</NavLink>
        <NavLink to="/books">Books</NavLink>
        <NavLink to="/profiles">Profiles</NavLink>
      </nav>
      <Outlet />
    </div>
  );
}