import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { Auth0Provider } from "@auth0/auth0-react";
import { auth0ProviderConfig } from "./config/auth0.config";
import "./index.css";
import App from "./App.tsx";

createRoot(document.getElementById("root")!).render(
  <Auth0Provider
    {...auth0ProviderConfig}
    onRedirectCallback={(appState) => {
      window.history.replaceState(
        {},
        document.title,
        appState?.returnTo || window.location.pathname
      );
    }}
  >
    <App />
  </Auth0Provider>
);
