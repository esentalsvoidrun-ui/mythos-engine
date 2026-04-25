const API_BASE = window.location.origin;
const WS_URL = API_BASE.replace(/^http/, "ws");

const state = {
  incidents: [],
  actions: [],
  feed: []
};

const $ = (id) => document.getElementById(id);

function safeArray(value) {
  return Array.isArray(value) ? value : [];
}

function formatTime(value) {
  if (!value) return "now";
  try {
    return new Date(value).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" });
  } catch {
    return "now";
  }
}

function getRiskScore(items = []) {
  const scores = items
    .map(x => Number(x.riskScore ?? x.risk ?? 0))
    .filter(x => Number.isFinite(x));

  if (!scores.length) return null;

  return Math.round(scores.reduce((a, b) => a + b, 0) / scores.length);
}

function riskLabel(score) {
  if (score === null || score === undefined) return "Awaiting signal";
  if (score >= 90) return "Critical risk";
  if (score >= 72) return "High risk";
  if (score >= 45) return "Medium risk";
  return "Stable";
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function reasonCodesHtml(item) {
  const codes = safeArray(item.reasonCodes || item.reasons || item.reason_codes);
  if (!codes.length) return `<div class="reasons"><span class="reason">NO_REASON_CODES</span></div>`;

  return `
    <div class="reasons">
      ${codes.slice(0, 8).map(code => `<span class="reason">${escapeHtml(code)}</span>`).join("")}
    </div>
  `;
}

function itemHtml(item, mode = "incident") {
  const type = item.type || item.eventType || "signal";
  const user = item.user || item.userId || item.actor || "unknown-user";
  const risk = item.riskScore ?? item.risk ?? "—";
  const action = item.action || item.decision || item.recommendedAction || "log";
  const severity = item.severity || "low";
  const createdAt = item.createdAt || item.timestamp || item.time;

  return `
    <div class="item">
      <div class="item-head">
        <div>
          <div class="item-title">${escapeHtml(type)} · ${escapeHtml(user)}</div>
          <div class="item-meta">
            risk ${escapeHtml(risk)} · 
            <span class="severity ${escapeHtml(severity)}">${escapeHtml(severity)}</span> ·
            ${escapeHtml(formatTime(createdAt))}
          </div>
        </div>
        <div class="decision ${escapeHtml(action)}">${escapeHtml(action)}</div>
      </div>
      ${reasonCodesHtml(item)}
    </div>
  `;
}

function renderList(id, items, emptyText, mode) {
  const el = $(id);
  const list = safeArray(items).slice(0, 12);

  if (!list.length) {
    el.innerHTML = `<div class="empty">${emptyText}</div>`;
    return;
  }

  el.innerHTML = list.map(item => itemHtml(item, mode)).join("");
}

function pushFeed(item) {
  if (!item) return;

  const normalized = {
    ...item,
    createdAt: item.createdAt || item.timestamp || new Date().toISOString()
  };

  state.feed.unshift(normalized);
  state.feed = state.feed.slice(0, 20);
  renderList("liveFeed", state.feed, "No live decisions yet.", "feed");
}

function renderMetrics(summary = {}) {
  const risk = getRiskScore(state.incidents);
  $("riskScore").textContent = risk === null ? "—" : risk;
  $("riskStatus").textContent = riskLabel(risk);

  $("incidentCount").textContent = state.incidents.length;
  $("actionCount").textContent = state.actions.length;

  const drift = summary?.drift || {};
  $("driftScore").textContent = drift.driftScore !== undefined ? Number(drift.driftScore).toFixed(2) : "—";
  $("driftStatus").textContent = drift.status ? `Status: ${drift.status}` : "Monitoring baseline";
}

function renderSummary(data = {}) {
  $("aiSummary").textContent =
    data.summary ||
    "System is waiting for enough events to generate a useful operator summary.";

  $("recommendation").textContent =
    data.recommendation ||
    "Recommended action: keep monitoring until a stronger signal pattern appears.";
}

async function fetchJson(path) {
  const res = await fetch(`${API_BASE}${path}`, { cache: "no-store" });
  if (!res.ok) throw new Error(`${path} returned ${res.status}`);
  return res.json();
}

async function loadDashboard() {
  try {
    const [incidents, actions, summary] = await Promise.all([
      fetchJson("/api/incidents").catch(() => []),
      fetchJson("/api/actions").catch(() => []),
      fetchJson("/api/summary").catch(() => ({}))
    ]);

    state.incidents = safeArray(incidents);
    state.actions = safeArray(actions);

    renderList("incidentList", state.incidents, "No incidents found.", "incident");
    renderList("actionList", state.actions, "No actions found.", "action");

    const combined = [...state.incidents, ...state.actions]
      .sort((a, b) => new Date(b.createdAt || b.timestamp || 0) - new Date(a.createdAt || a.timestamp || 0))
      .slice(0, 12);

    state.feed = combined;
    renderList("liveFeed", state.feed, "No live decisions yet. Send a test event to wake the engine.", "feed");

    renderSummary(summary);
    renderMetrics(summary);

    $("connectionStatus").textContent = "online";
  } catch (err) {
    $("connectionStatus").textContent = "offline";
    $("aiSummary").textContent = `Dashboard could not load API data: ${err.message}`;
  }
}

function connectWs() {
  try {
    const ws = new WebSocket(WS_URL);

    ws.onopen = () => {
      $("connectionStatus").textContent = "online · live";
    };

    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);

        const payload =
          data.incident ||
          data.action ||
          data.event ||
          data.payload ||
          data;

        pushFeed(payload);

        setTimeout(loadDashboard, 350);
      } catch {
        // Ignore malformed websocket packets.
      }
    };

    ws.onclose = () => {
      $("connectionStatus").textContent = "polling";
      setTimeout(connectWs, 2500);
    };

    ws.onerror = () => {
      $("connectionStatus").textContent = "polling";
    };
  } catch {
    $("connectionStatus").textContent = "polling";
  }
}

loadDashboard();
connectWs();
setInterval(loadDashboard, 5000);
