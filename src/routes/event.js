import { normalizeEvent, normalizeDecision } from "../core/normalize.js";
import { evaluateEvent } from "../core/engine.js";

export function registerEventRoute(app, config, state) {
  app.post("/event", (req, res) => {
    try {
      const event = normalizeEvent(req.body || {});
      const requestedMode = req.body?.mode || config.engineMode;
      const result = evaluateEvent(event, requestedMode);

      const decision = normalizeDecision({
        mode: result.mode,
        score: result.score,
        reasons: result.reasons,
        event,
        meta: result
      });

decision.reasonCodes = decision.reasons || result.reasons || [];
decision.correlationLabel = result.correlationLabel || "none";
decision.summary =
  result.summary ||
  `Action ${decision.action}. Severity ${decision.severity}. Event ${event.type} for user ${event.user || "unknown"}. Reasons: ${(decision.reasonCodes || []).join(", ") || "NO_EXPLICIT_REASON_CODES"}.`;
  decision.riskScore = decision.riskScore ?? result.score ?? 0;
decision.type = decision.type || event.type;
decision.status = decision.status || "pending_review";
  state.actions.push({
  id: Date.now() + 1,
  action: decision.action,
  severity: decision.severity,
  user: decision.user,
  mode: decision.mode,
  type: decision.type,
  status: decision.status,
  riskScore: decision.riskScore,
  reasons: decision.reasons || result.reasons || [],
  reasonCodes: decision.reasons || result.reasons || [],
  correlationLabel: result.correlationLabel || "none",
  summary: result.summary || decision.summary || "",
  createdAt: decision.createdAt
});

      res.json({
        ok: true,
        event,
        decision,
        engine: result
      });
    } catch (error) {
      res.status(500).json({
        ok: false,
        error: error.message
      });
    }
  });
}
