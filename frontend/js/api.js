let API_BASE = "";

async function loadConfig() {
    const res = await fetch("config.json");
    const cfg = await res.json();
    API_BASE = cfg.API_BASE;
}
loadConfig();

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
