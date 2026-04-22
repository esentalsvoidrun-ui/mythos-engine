import express from "express";
import { APP_CONFIG } from "./core/config.js";
import { state } from "./core/state.js";
import { registerHealthRoute } from "./routes/health.js";
import { registerEventRoute } from "./routes/event.js";
import { registerSummaryRoute } from "./routes/summary.js";

const app = express();
app.use(express.json());
app.use(express.static("public_dashboard"));

registerHealthRoute(app, APP_CONFIG);
registerEventRoute(app, APP_CONFIG, state);
registerSummaryRoute(app, APP_CONFIG, state);

function clamp(n, min, max) {
  return Math.max(min, Math.min(max, n));
}

function buildReasonCodes(event, userEvents = []) {
  const reasons = [];

  const risk = Number(event.risk || 0);
  const amount = Number(event.amount || 0);
  const attempts = Number(event.attempts || 0);

  if (risk <= 20) reasons.push("LOW_BASE_RISK");
  if (risk >= 45) reasons.push("ELEVATED_BASE_RISK");
  if (risk >= 70) reasons.push("HIGH_RISK");
  if (risk >= 90) reasons.push("EXTREME_RISK");

  if (event.ip === "unknown") reasons.push("UNSEEN_IP");
  if (event.geoMismatch) reasons.push("GEO_MISMATCH");
  if (event.velocitySpike) reasons.push("VELOCITY_SPIKE");

  if (event.type === "payment" && amount >= 500) reasons.push("LARGE_PAYMENT");
  if (event.type === "payment" && amount >= 5000) reasons.push("HIGH_RISK_PAYMENT");

  if (event.type === "login" && attempts >= 3) reasons.push("REPEATED_LOGIN_ATTEMPTS");
  if (event.type === "login" && attempts >= 7) reasons.push("LOGIN_BURST");

  const recentLogins = userEvents.filter(e => e.type === "login").length;
  const recentPayments = userEvents.filter(e => e.type === "payment").length;

  if (recentLogins > 0 && event.type === "payment") {
    reasons.push("LOGIN_PAYMENT_SEQUENCE");
  }

  if (
    userEvents.some(e => e.geoMismatch) &&
    userEvents.some(e => e.velocitySpike) &&
    userEvents.some(e => e.type === "payment")
  ) {
    reasons.push("MULTI_SIGNAL_CLUSTER");
  }

  return [...new Set(reasons)];
}

function detectCorrelationLabel(event, userEvents = []) {
  const hasLogin = userEvents.some(e => e.type === "login") || event.type === "login";
  const hasPayment = userEvents.some(e => e.type === "payment") || event.type === "payment";
  const hasGeo = userEvents.some(e => e.geoMismatch) || !!event.geoMismatch;
  const hasVelocity = userEvents.some(e => e.velocitySpike) || !!event.velocitySpike;

  if (hasLogin && hasPayment && hasGeo && hasVelocity) return "login_payment_geo_velocity";
  if (hasLogin && hasPayment && hasGeo) return "login_payment_geo";
  if (hasLogin && hasPayment) return "login_payment_cluster";
  if (hasGeo && hasVelocity) return "geo_velocity_cluster";
  return "none";
}

function computeRiskScore(event, reasonCodes = [], userEvents = []) {
  let score = Number(event.risk || 0);

  if (reasonCodes.includes("UNSEEN_IP")) score += 12;
  if (reasonCodes.includes("GEO_MISMATCH")) score += 15;
  if (reasonCodes.includes("VELOCITY_SPIKE")) score += 20;
  if (reasonCodes.includes("LARGE_PAYMENT")) score += 8;
  if (reasonCodes.includes("HIGH_RISK_PAYMENT")) score += 18;
  if (reasonCodes.includes("REPEATED_LOGIN_ATTEMPTS")) score += 8;
  if (reasonCodes.includes("LOGIN_BURST")) score += 12;
  if (reasonCodes.includes("LOGIN_PAYMENT_SEQUENCE")) score += 10;
  if (reasonCodes.includes("MULTI_SIGNAL_CLUSTER")) score += 20;

  const recentCriticalSignals = userEvents.filter(
    e => e.geoMismatch || e.velocitySpike || (Number(e.risk || 0) >= 70)
  ).length;

  if (recentCriticalSignals >= 2) score += 10;
  if (recentCriticalSignals >= 4) score += 10;

  return clamp(Math.round(score), 0, 100);
}

function decideAction(riskScore) {
  if (riskScore >= 85) return { action: "block", severity: "critical", status: "blocked" };
  if (riskScore >= 70) return { action: "manual_review", severity: "high", status: "pending_review" };
  if (riskScore >= 45) return { action: "rate_limit", severity: "medium", status: "monitoring" };
  return { action: "log", severity: "low", status: "pending_review" };
}

function buildDecisionSummary(event, decision, reasonCodes, correlationLabel) {
  const reasonText = reasonCodes.length ? reasonCodes.join(", ") : "NO_EXPLICIT_REASON_CODES";
  return `Action ${decision.action}. Severity ${decision.severity}. Event ${event.type} for user ${event.user || "unknown"}. Correlation ${correlationLabel}. Reasons: ${reasonText}.`;
}

app.get("/api/incidents", (_req, res) => {
  res.json({ ok: true, items: state.incidents });
});

app.get("/api/actions", (_req, res) => {
  res.json({ ok: true, items: state.actions });
});

app.get("/api/modes", (_req, res) => {
  res.json({
    ok: true,
    current: APP_CONFIG.engineMode,
    available: ["signaldesk", "mqc", "shadow", "hybrid"]
  });
});

app.listen(APP_CONFIG.port, () => {
  console.log(`SignalDesk listening on http://localhost:${APP_CONFIG.port}`);
  console.log(`Engine mode: ${APP_CONFIG.engineMode}`);
});
