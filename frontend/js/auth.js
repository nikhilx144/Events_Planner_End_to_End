// Dynamically load API base from config.json
let API_BASE = "";

async function loadConfig() {
    const res = await fetch("config.json");
    const cfg = await res.json();
    API_BASE = cfg.API_BASE;
}
loadConfig();

// Wrapper API request
async function apiRequest(endpoint, method, body) {
    const response = await fetch(`${API_BASE}/${endpoint}`, {
        method,
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(body)
    });

    return response.json();
}

// =======================
// SIGNUP FORM HANDLER
// =======================
document.addEventListener("DOMContentLoaded", () => {
    const signupForm = document.getElementById("signupForm");

    if (signupForm) {
        signupForm.addEventListener("submit", async (e) => {
            e.preventDefault();

            const full_name = document.getElementById("name").value;
            const email = document.getElementById("email").value;
            const password = document.getElementById("password").value;
            const confirm_password = document.getElementById("confirmPassword").value;

            const result = await apiRequest("signup", "POST", {
                full_name,
                email,
                password,
                confirm_password
            });

            if (result.error) {
                alert("Signup failed: " + result.error);
            } else {
                alert("Signup successful! Please log in.");
                window.location.href = "login.html";
            }
        });
    }

    // =======================
    // LOGIN FORM HANDLER
    // =======================
    const loginForm = document.getElementById("loginForm");

    if (loginForm) {
        loginForm.addEventListener("submit", async (e) => {
            e.preventDefault();

            const email = document.getElementById("loginEmail").value;
            const password = document.getElementById("loginPassword").value;

            const result = await apiRequest("login", "POST", {
                email,
                password
            });

            if (result.error) {
                alert("Login failed: " + result.error);
            } else {
                localStorage.setItem("token", result.token);
                localStorage.setItem("userEmail", result.email);

                alert("Login successful!");
                window.location.href = "dashboard.html";
            }
        });
    }
});
