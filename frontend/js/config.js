// frontend/js/config.js

window.APP_CONFIG = null;

// Load config.json ONCE and make globally available
async function loadAppConfig() {
    if (window.APP_CONFIG) return window.APP_CONFIG;

    try {
        const res = await fetch("config.json");
        if (!res.ok) throw new Error("config.json missing or invalid");

        const json = await res.json();
        window.APP_CONFIG = json;

        console.log("Loaded config:", json);
        return json;
    } catch (err) {
        console.error("Failed to load config.json:", err);
        return null;
    }
}

// Immediately start loading (but do not use top-level await)
loadAppConfig();
