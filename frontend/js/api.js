let API_BASE = "";

async function loadConfig() {
    const res = await fetch("/frontend/config.json");
    const config = await res.json();
    API_BASE = config.API_BASE;
}

async function apiRequest(endpoint, method, body) {
    if (!API_BASE) await loadConfig();

    const response = await fetch(`${API_BASE}/${endpoint}`, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body)
    });

    return response.json();
}

export { apiRequest, loadConfig };
