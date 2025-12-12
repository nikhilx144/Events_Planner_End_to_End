// frontend/js/auth.js

let AUTH_API_BASE = null;

/**
 * Load config.json once and populate AUTH_API_BASE
 */
async function loadConfig() {
  if (AUTH_API_BASE) return; // already loaded

  try {
    const res = await fetch("config.json");
    if (!res.ok) {
      console.error("Failed to load config.json:", res.status, res.statusText);
      return;
    }

    const cfg = await res.json();
    console.log("Loaded config:", cfg);

    // From Terraform
    AUTH_API_BASE = cfg.auth_base;

    if (!AUTH_API_BASE) {
      console.error("auth_base missing in config.json");
    }
  } catch (err) {
    console.error("Error loading config.json:", err);
  }
}

/**
 * Generic API call
 */
async function apiRequest(endpoint, method, body) {
  // Ensure config is loaded before any API call
  await loadConfig();

  if (!AUTH_API_BASE) {
    throw new Error("Auth API base URL not configured");
  }

  // Remove double slashes
  const url = `${AUTH_API_BASE.replace(/\/$/, "")}/${endpoint}`;

  console.log("Calling API:", url);

  const res = await fetch(url, {
    method,
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify(body)
  });

  const text = await res.text();

  if (!res.ok) {
    try {
      const errJson = JSON.parse(text);
      throw new Error(errJson.error || JSON.stringify(errJson));
    } catch {
      throw new Error(text || `HTTP ${res.status}`);
    }
  }

  if (!text) return {};
  return JSON.parse(text);
}

/**
 * Signup + Login Form bindings
 */
document.addEventListener("DOMContentLoaded", () => {
  const signupForm = document.getElementById("signupForm");
  const loginForm = document.getElementById("loginForm");

  // Signup
  if (signupForm) {
    signupForm.addEventListener("submit", async (e) => {
      e.preventDefault();

      const full_name = document.getElementById("name").value.trim();
      const email = document.getElementById("email").value.trim();
      const password = document.getElementById("password").value;
      const confirm = document.getElementById("confirmPassword").value;

      try {
        const result = await apiRequest("signup", "POST", {
          full_name,
          email,
          password,
          confirm_password: confirm
        });

        alert("Signup successful! Please login.");
        window.location.href = "login.html";
      } catch (err) {
        console.error("Signup error:", err);
        alert("Signup failed: " + err.message);
      }
    });
  }

  // Login
  if (loginForm) {
    loginForm.addEventListener("submit", async (e) => {
      e.preventDefault();

      const email = document.getElementById("loginEmail").value.trim();
      const password = document.getElementById("loginPassword").value;

      try {
        const result = await apiRequest("login", "POST", {
          email,
          password
        });

        // Save token & redirect
        if (result.token) localStorage.setItem("auth_token", result.token);
        if (result.email) localStorage.setItem("user_email", result.email);
        if (result.full_name) localStorage.setItem("user_name", result.full_name);

        window.location.href = "dashboard.html";
      } catch (err) {
        console.error("Login error:", err);
        alert("Login failed: " + err.message);
      }
    });
  }
});
