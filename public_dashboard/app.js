async function fetchJson(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(url + " failed: " + res.status);
  return res.json();
}

const state = {
  summary: {},
  incidents: [],
  actions: []
};

const el = (id) => document.getElementById(id);
const safeText = (v, d = "—") => (v === undefined || v === null || v === "" ? d : v);

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function latestAction() {
  return state.actions.length ? state.actions[state.actions.length - 1] : null;
}

function renderSummary() {
  const s = state.summary || {};
  const drift = s.drift || {};
  const latest = latestAction();

  if (el("statusValue")) el("statusValue").textContent = safeText(drift.status, "unknown");
  if (el("driftValue")) el("driftValue").textContent = Number(drift.driftScore ?? 0).toFixed(2);
  if (el("baselineRiskValue")) el("baselineRiskValue").textContent = safeText(drift.baselineRisk, 0);
  if (el("eventsLoadedValue")) el("eventsLoadedValue").textContent = safeText(drift.currentVolume, 0);
  if (el("avgRiskValue")) el("avgRiskValue").textContent = Number(drift.currentRisk ?? 0).toFixed(0);
  if (el("topActionValue")) el("topActionValue").textContent = latest?.action || "observe";

  if (el("systemReflection")) {
    el("systemReflection").textContent = s.summary || "No summary available.";
  }

  if (el("serverModeChip")) {
    el("serverModeChip").textContent = `Server mode: ${safeText(latest?.mode || s.mode, "signaldesk")}`;
  }

  if (el("currentDecisionWord")) {
    el("currentDecisionWord").textContent = (latest?.action || "observe").toUpperCase();
  }
  if (el("currentDecisionSub")) {
    el("currentDecisionSub").textContent = latest?.summary || "Awaiting live decision.";
  }

  if (el("signaldeskWord")) {
    el("signaldeskWord").textContent = (latest?.action || "—").toUpperCase();
  }
  if (el("signaldeskSub")) {
    el("signaldeskSub").textContent = latest?.explanation || "SignalDesk weighted rule engine";
  }

  if (el("mqcWord")) el("mqcWord").textContent = "—";
  if (el("mqcSub")) el("mqcSub").textContent = "No comparison yet.";

  if (el("nextActionWord")) {
    el("nextActionWord").textContent =
      latest?.action === "block"
        ? "Block"
        : latest?.action === "manual_review"
        ? "Review"
        : "Observe";
  }
  if (el("nextActionSub")) {
    el("nextActionSub").textContent =
      latest?.severity ? `${latest.severity} severity` : "Need more live data.";
  }

  if (el("divergenceWord")) el("divergenceWord").textContent = "Aligned";
  if (el("divergenceSub")) el("divergenceSub").textContent = "No shadow comparison yet.";

  renderLists(latest);
}

function renderLists(latest) {
  const reasons = latest?.reasonCodes || latest?.reasons || [];
  const reasonList = el("reasonList");
  const memoryList = el("memoryList");
  const runtimeList = el("runtimeList");

  if (reasonList) {
    reasonList.innerHTML = reasons.length
      ? reasons.map(r => `<li>${escapeHtml(r)}</li>`).join("")
      : "<li>No explicit reason codes.</li>";
  }

  if (el("decisionReasoning")) {
    el("decisionReasoning").textContent = reasons.length
      ? reasons.join(" • ")
      : "No comparison data yet";
  }

  if (memoryList) {
    memoryList.innerHTML = latest?.user
      ? `<li>User: ${escapeHtml(latest.user)}</li><li>Mode: ${escapeHtml(latest.mode || "signaldesk")}</li>`
      : "<li>No memory factors loaded.</li>";
  }

  if (runtimeList) {
    runtimeList.innerHTML = latest
      ? `<li>Latest event type: ${escapeHtml(latest.type || "event")}</li><li>Severity: ${escapeHtml(latest.severity || "unknown")}</li>`
      : "<li>Waiting for scenario injection.</li>";
  }
}

function renderActions() {
  const container = el("decisionFeed");
  if (!container) return;

  if (!state.actions.length) {
    container.innerHTML = '<div style="opacity:.75;padding:8px;">No decisions yet.</div>';
    return;
  }

  const items = [...state.actions].slice(-8).reverse();

  container.innerHTML = items.map((item) => `
    <div style="padding:10px;border-bottom:1px solid rgba(120,170,255,.15);">
      <div style="display:flex;justify-content:space-between;gap:12px;flex-wrap:wrap;">
        <strong>${escapeHtml((item.action || "observe").toUpperCase())}</strong>
        <span>${escapeHtml(item.severity || "unknown")} • ${escapeHtml(item.type || "event")}</span>
      </div>
      <div style="margin-top:4px;">user: ${escapeHtml(item.user || "unknown")}</div>
      <div style="margin-top:4px;">score: ${escapeHtml(item.riskScore ?? "—")} • mode: ${escapeHtml(item.mode || "signaldesk")}</div>
      <div style="margin-top:4px;opacity:.85;">${escapeHtml(item.summary || "No summary")}</div>
    </div>
  `).join("");
}

function renderIncidents() {
  const liveEvents = el("liveEventsFeed");
  if (liveEvents) {
    const items = (state.incidents.length ? state.incidents : state.actions).slice(-8).reverse();

    liveEvents.innerHTML = items.length
      ? items.map((item) => `
          <div style="padding:10px;border-bottom:1px solid rgba(120,170,255,.15);">
            <div><strong>${escapeHtml(item.type || "event")}</strong> • ${escapeHtml(item.user || "unknown")}</div>
            <div style="margin-top:4px;">severity: ${escapeHtml(item.severity || "—")} • action: ${escapeHtml(item.action || "—")}</div>
            <div style="margin-top:4px;opacity:.85;">${escapeHtml(item.summary || "No summary")}</div>
          </div>
        `).join("")
      : '<div style="opacity:.75;padding:8px;">No live events yet.</div>';
  }

  const mqcFeed = el("mqcFeed");
  const latest = latestAction();

  if (mqcFeed) {
    mqcFeed.innerHTML = latest
      ? `
        <div style="padding:10px;">
          <div><strong>${escapeHtml(latest.type || "event")}</strong> • ${escapeHtml(latest.user || "unknown")}</div>
          <div style="margin-top:6px;">Action: ${escapeHtml(latest.action || "observe")}</div>
          <div style="margin-top:6px;">Reasons: ${escapeHtml((latest.reasonCodes || latest.reasons || []).join(", ") || "none")}</div>
        </div>
      `
      : '<div style="opacity:.75;padding:8px;">No insight yet.</div>';
  }

  renderRiskDistribution();
}

function renderRiskDistribution() {
  const counts = { low: 0, medium: 0, high: 0, critical: 0 };

  for (const item of state.actions) {
    const score = Number(item.riskScore ?? 0);
    if (score <= 44) counts.low++;
    else if (score <= 71) counts.medium++;
    else if (score <= 89) counts.high++;
    else counts.critical++;
  }

  const total = Math.max(state.actions.length, 1);

  const setBar = (barId, countId, count) => {
    const bar = el(barId);
    const countEl = el(countId);
    const pct = Math.round((count / total) * 100);

    if (bar) bar.style.width = `${pct}%`;
    if (countEl) countEl.textContent = String(count);
  };

  setBar("barLow", "countLow", counts.low);
  setBar("barMedium", "countMedium", counts.medium);
  setBar("barHigh", "countHigh", counts.high);
  setBar("barCritical", "countCritical", counts.critical);
}

async function loadAll() {
  try {
    const summary = await fetchJson("/api/summary").catch(() => null);
    const incidentsData = await fetchJson("/api/incidents").catch(() => ({ items: [] }));
    const actionsData = await fetchJson("/api/actions").catch(() => ({ items: [] }));

    state.summary = summary || {};
    state.incidents = Array.isArray(incidentsData.items) ? incidentsData.items : [];
    state.actions = Array.isArray(actionsData.items) ? actionsData.items : [];

    renderSummary();
    renderIncidents();
    renderActions();
  } catch (err) {
    console.error("loadAll total fail:", err);
    if (el("systemReflection")) {
      el("systemReflection").textContent = "Load failed: " + err.message;
    }
  }
}

setInterval(loadAll, 2000);
loadAll();
