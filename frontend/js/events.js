let EVENTS_API_BASE = null;

// ---------------------------
// Load events API base from config.json
// ---------------------------
async function loadEventsConfig() {
    if (EVENTS_API_BASE) return;

    try {
        const res = await fetch("config.json");
        if (!res.ok) {
            console.error("Failed to load config.json:", res.status);
            return;
        }
        
        const cfg = await res.json();
        console.log("Loaded config:", cfg);
        
        EVENTS_API_BASE = cfg.events_base;
        
        if (!EVENTS_API_BASE) {
            console.error("events_base missing in config.json");
        } else {
            console.log("Events API base:", EVENTS_API_BASE);
        }
    } catch (err) {
        console.error("Error loading config.json:", err);
    }
}

// ---------------------------
// Auth header
// ---------------------------
function getAuthHeader() {
    const token = localStorage.getItem("auth_token");
    return token ? { "Authorization": `Bearer ${token}` } : {};
}

// ---------------------------
// Generic API call to /events
// ---------------------------
async function apiRequestEvents(method, body = null) {
    await loadEventsConfig();

    const opts = {
        method,
        headers: {
            "Content-Type": "application/json",
            ...getAuthHeader()
        }
    };

    if (body) {
        opts.body = JSON.stringify(body);
    }

    const res = await fetch(EVENTS_API_BASE, opts);
    const text = await res.text();

    if (!res.ok) {
        try {
            const errJson = JSON.parse(text);
            throw new Error(errJson.error || text);
        } catch (e) {
            throw new Error(text || `HTTP ${res.status}`);
        }
    }

    return text ? JSON.parse(text) : {};
}

// ======================================================
// RENDER EVENTS INTO DASHBOARD
// ======================================================

function renderEvents(items) {
    const grid = document.getElementById("eventsGrid");
    const emptyState = document.getElementById("emptyState");

    // Clear previous
    grid.innerHTML = "";

    if (!items || items.length === 0) {
        emptyState.style.display = "block";
        grid.appendChild(emptyState);
        return;
    }

    emptyState.style.display = "none";

    items.forEach(ev => {
        const card = document.createElement("div");
        card.className = "event-card";

        card.innerHTML = `
            <h4>${ev.title}</h4>
            <p><strong>Date:</strong> ${ev.date}</p>
            ${ev.time ? `<p><strong>Time:</strong> ${ev.time}</p>` : ""}
            ${ev.venue ? `<p><strong>Venue:</strong> ${ev.venue}</p>` : ""}
            <p>${ev.details}</p>
        `;

        grid.appendChild(card);
    });
}

// ======================================================
// LOAD EVENTS
// ======================================================
async function loadEventsList() {
    await loadEventsConfig();
    try {
        const res = await apiRequestEvents("GET");
        console.log("Fetched events:", res.items);
        renderEvents(res.items);
    } catch (e) {
        console.error("Failed to load events:", e);
    }
}

// ======================================================
// UI HANDLERS
// ======================================================
document.addEventListener("DOMContentLoaded", () => {
    const addEventBtn = document.getElementById("addEventBtn");
    const viewEventsBtn = document.getElementById("viewEventsBtn");
    const addEventSection = document.getElementById("addEventSection");
    const eventsSection = document.getElementById("eventsSection");
    const eventForm = document.getElementById("eventForm");

    // Show Add Event form
    addEventBtn?.addEventListener("click", () => {
        eventsSection.style.display = "none";
        addEventSection.style.display = "block";
    });

    // Back to events list
    viewEventsBtn?.addEventListener("click", () => {
        eventsSection.style.display = "block";
        addEventSection.style.display = "none";
        loadEventsList();  // refresh when switching back
    });

    // Handle form submission
    eventForm?.addEventListener("submit", async (e) => {
        e.preventDefault();

        const payload = {
            title: document.getElementById("eventTitle").value,
            date: document.getElementById("eventDate").value,
            time: document.getElementById("eventTime").value,
            venue: document.getElementById("eventVenue").value,
            details: document.getElementById("eventDetails").value
        };

        try {
            const res = await apiRequestEvents("POST", payload);
            alert("Event created successfully!");

            // Refresh events
            await loadEventsList();

            // Switch view
            viewEventsBtn.click();
        } catch (err) {
            alert("Failed to create event: " + err.message);
            console.error("Create event error:", err);
        }
    });

    // Auto-load on page load
    loadEventsList();
});
