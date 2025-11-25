import { apiRequest, loadConfig } from "./api.js";

(async () => {
    await loadConfig();
})();

// SIGNUP
document.getElementById("signupForm")?.addEventListener("submit", async (e) => {
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

    alert(JSON.stringify(result));
});

// LOGIN
document.getElementById("loginForm")?.addEventListener("submit", async (e) => {
    e.preventDefault();

    const email = document.getElementById("loginEmail").value;
    const password = document.getElementById("loginPassword").value;

    const result = await apiRequest("login", "POST", {
        email,
        password
    });

    alert(JSON.stringify(result));
});
