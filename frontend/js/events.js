let EVENTS_API_BASE = null;
let currentEditingEvent = null; // Track which event is being edited

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
async function apiRequestEvents(method, body = null, eventId = null) {
    await loadEventsConfig();

    let url = EVENTS_API_BASE;
    
    // For DELETE, add eventId as query parameter
    if (method === 'DELETE' && eventId) {
        url += `?eventId=${eventId}`;
    }

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

    const res = await fetch(url, opts);
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

    // Sort events by date (most recent first)
    items.sort((a, b) => new Date(b.date) - new Date(a.date));

    items.forEach(ev => {
        const card = document.createElement("div");
        card.className = "event-card";

        // Format date nicely
        const eventDate = new Date(ev.date);
        const formattedDate = eventDate.toLocaleDateString('en-US', { 
            weekday: 'long', 
            year: 'numeric', 
            month: 'long', 
            day: 'numeric' 
        });

        card.innerHTML = `
            <h3>${ev.title}</h3>
            <p><strong>📅 Date:</strong> ${formattedDate}</p>
            <p><strong>🕐 Time:</strong> ${ev.time}</p>
            <p><strong>📍 Venue:</strong> ${ev.venue}</p>
            <p><strong>📝 Details:</strong> ${ev.details}</p>
            
            <div class="event-actions">
                <button class="btn-small btn-edit" onclick="editEvent('${ev.eventId}')">
                    ✏️ Edit
                </button>
                <button class="btn-small btn-delete" onclick="deleteEvent('${ev.eventId}', '${ev.title}')">
                    🗑️ Delete
                </button>
            </div>
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
        showAlert("Failed to load events: " + e.message, "error");
    }
}

// ======================================================
// EDIT EVENT
// ======================================================
async function editEvent(eventId) {
    try {
        // Get all events and find the one to edit
        const res = await apiRequestEvents("GET");
        const event = res.items.find(e => e.eventId === eventId);
        
        if (!event) {
            showAlert("Event not found", "error");
            return;
        }

        // Store current editing event
        currentEditingEvent = event;

        // Populate form with event data
        document.getElementById("eventDate").value = event.date;
        document.getElementById("eventTitle").value = event.title;
        document.getElementById("eventTime").value = event.time !== "Not specified" ? event.time : "";
        document.getElementById("eventVenue").value = event.venue !== "Not specified" ? event.venue : "";
        document.getElementById("eventDetails").value = event.details;

        // Change button text to "Update Event"
        const submitBtn = document.getElementById("saveEventBtn");
        submitBtn.textContent = "💾 Update Event";
        submitBtn.classList.add("btn-update");

        // Show the form
        document.getElementById("eventsSection").style.display = "none";
        document.getElementById("addEventSection").style.display = "block";
        document.getElementById("addEventBtn").classList.add("active");
        document.getElementById("viewEventsBtn").classList.remove("active");

        // Scroll to top
        window.scrollTo({ top: 0, behavior: 'smooth' });

    } catch (err) {
        console.error("Edit event error:", err);
        showAlert("Failed to load event: " + err.message, "error");
    }
}

// ======================================================
// DELETE EVENT
// ======================================================
async function deleteEvent(eventId, eventTitle) {
    // Confirm before deleting
    if (!confirm(`Are you sure you want to delete "${eventTitle}"?`)) {
        return;
    }

    try {
        showAlert("Deleting event...", "info");
        
        await apiRequestEvents("DELETE", null, eventId);
        
        showAlert("Event deleted successfully! 🗑️", "success");
        
        // Refresh events list
        await loadEventsList();
        
    } catch (err) {
        console.error("Delete event error:", err);
        showAlert("Failed to delete event: " + err.message, "error");
    }
}

// ======================================================
// SHOW ALERT MESSAGE
// ======================================================
function showAlert(message, type) {
    const alertDiv = document.createElement("div");
    alertDiv.className = `alert alert-${type}`;
    alertDiv.textContent = message;
    
    // Insert at top of dashboard
    const container = document.querySelector(".dashboard-container");
    container.insertBefore(alertDiv, container.firstChild);
    
    // Remove after 3 seconds
    setTimeout(() => {
        alertDiv.remove();
    }, 3000);
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
    const cancelBtn = document.getElementById("cancelBtn");

    // Show Add Event form
    addEventBtn?.addEventListener("click", () => {
        // Reset form and editing state
        eventForm.reset();
        currentEditingEvent = null;
        
        // Reset button text
        const submitBtn = document.getElementById("saveEventBtn");
        submitBtn.textContent = "💾 Save Event";
        submitBtn.classList.remove("btn-update");
        
        // Show form
        eventsSection.style.display = "none";
        addEventSection.style.display = "block";
        addEventBtn.classList.add("active");
        viewEventsBtn.classList.remove("active");
    });

    // Back to events list
    viewEventsBtn?.addEventListener("click", () => {
        // Reset editing state
        currentEditingEvent = null;
        eventForm.reset();
        
        // Reset button text
        const submitBtn = document.getElementById("saveEventBtn");
        submitBtn.textContent = "💾 Save Event";
        submitBtn.classList.remove("btn-update");
        
        // Show events list
        eventsSection.style.display = "block";
        addEventSection.style.display = "none";
        viewEventsBtn.classList.add("active");
        addEventBtn.classList.remove("active");
        
        loadEventsList();  // refresh when switching back
    });

    // Cancel button
    cancelBtn?.addEventListener("click", () => {
        viewEventsBtn.click(); // Trigger view events
    });

    // Handle form submission (Create OR Update)
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
            if (currentEditingEvent) {
                // UPDATE existing event
                payload.eventId = currentEditingEvent.eventId;
                
                await apiRequestEvents("PUT", payload);
                showAlert("Event updated successfully! ✏️", "success");
                
            } else {
                // CREATE new event
                await apiRequestEvents("POST", payload);
                showAlert("Event created successfully! 🎉", "success");
            }

            // Reset form and editing state
            eventForm.reset();
            currentEditingEvent = null;
            
            // Reset button text
            const submitBtn = document.getElementById("saveEventBtn");
            submitBtn.textContent = "💾 Save Event";
            submitBtn.classList.remove("btn-update");

            // Refresh events
            await loadEventsList();

            // Switch to events view
            setTimeout(() => {
                viewEventsBtn.click();
            }, 500);
            
        } catch (err) {
            showAlert("Failed to save event: " + err.message, "error");
            console.error("Save event error:", err);
        }
    });

    // Auto-load events on page load
    loadEventsList();
});

// Make functions globally accessible for onclick handlers
window.editEvent = editEvent;
window.deleteEvent = deleteEvent;