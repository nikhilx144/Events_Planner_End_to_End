// let API_BASE = "";
let API_BASE = "https://bcs2hv1dp4.execute-api.ap-south-1.amazonaws.com/prod/auth/";


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
