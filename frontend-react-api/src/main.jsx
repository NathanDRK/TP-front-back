import React from "react";
import ReactDOM from "react-dom/client";
import { createBrowserRouter, RouterProvider } from "react-router-dom";
import App from "./App.jsx";
import UsersPage from "./pages/UsersPage.jsx";
import BooksPage from "./pages/BooksPage.jsx";
import ProfilesPage from "./pages/ProfilesPage.jsx";
const router = createBrowserRouter([
  {
    path: "/",
    element: <App />,
    children: [
      { index: true, element: <UsersPage /> },
      { path: "books", element: <BooksPage /> },
      { path: "profiles", element: <ProfilesPage /> }
    ],
  },
]);
ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <RouterProvider router={router} />
  </React.StrictMode>
);
