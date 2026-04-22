import { getSafeMode } from "./config.js";
import { runSignalDesk } from "../modes/signaldesk.js";
import { runMQC } from "../modes/mqc.js";
import { runShadow } from "../modes/shadow.js";
import { runHybrid } from "../modes/hybrid.js";

export function evaluateEvent(event, requestedMode) {
  const mode = getSafeMode(requestedMode);
  const reasons = [];

if (event.risk >= 70) reasons.push("HIGH_RISK");
if (event.risk >= 90) reasons.push("EXTREME_RISK");

if (event.ip === "unknown") reasons.push("UNSEEN_IP");
if (event.geoMismatch) reasons.push("GEO_MISMATCH");
if (event.velocitySpike) reasons.push("VELOCITY_SPIKE");

if (event.type === "payment" && event.amount >= 500) {
  reasons.push("LARGE_PAYMENT");
}

if (event.type === "payment" && event.amount >= 5000) {
  reasons.push("HIGH_RISK_PAYMENT");
}

if (event.type === "login" && event.attempts >= 3) {
  reasons.push("REPEATED_LOGIN_ATTEMPTS");
}

if (event.type === "login" && event.attempts >= 7) {
  reasons.push("LOGIN_BURST");
}

switch (mode) {
  case "mqc": {
    const result = runMQC(event);
    return { ...result, reasons };
  }

  case "shadow": {
    const result = runShadow(event);
    return { ...result, reasons };
  }

  case "hybrid": {
    const result = runHybrid(event);
    return { ...result, reasons };
  }

  case "signaldesk":
  default: {
    const result = runSignalDesk(event);
    return {
      ...result,
      reasons,
      correlationLabel: "basic",
      summary: `Score ${result.score}. Reasons: ${reasons.join(", ") || "none"}`
    };
  }
}
}
