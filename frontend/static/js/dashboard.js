function escapeHtml(value) {
    return String(value)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/\"/g, "&quot;")
        .replace(/'/g, "&#39;");
}

function renderStateBadge(stateValue) {
    const normalized = String(stateValue || "pending").toLowerCase();
    const variant = normalized === "running"
        ? "state-running"
        : normalized === "stopped"
            ? "state-stopped"
            : "state-pending";

    return `<span class="state-badge ${variant}"><span class="state-dot"></span>${escapeHtml(normalized)}</span>`;
}

async function loadResources() {
    const response = await fetch("/api/resources");
    const resources = await response.json();

    const tbody = document.querySelector("#resources-table tbody");
    tbody.innerHTML = "";

    let running = 0;
    let stopped = 0;

    resources.forEach((item) => {
        if (item.state === "running") running += 1;
        if (item.state === "stopped") stopped += 1;

        const state = item.state ?? "pending";
        const tr = document.createElement("tr");
        tr.innerHTML = `
            <td>${escapeHtml(item.id ?? "N/A")}</td>
            <td>${escapeHtml(item.name ?? "")}</td>
            <td>${renderStateBadge(state)}</td>
            <td>${escapeHtml(item.region ?? "N/A")}</td>
            <td>${escapeHtml(item.public_ip ?? "N/A")}</td>
            <td>${escapeHtml(item.type ?? "N/A")}</td>
        `;
        tbody.appendChild(tr);
    });

    document.getElementById("total-count").textContent = resources.length;
    document.getElementById("running-count").textContent = running;
    document.getElementById("stopped-count").textContent = stopped;
}

document.getElementById("refresh-btn").addEventListener("click", loadResources);
loadResources();
