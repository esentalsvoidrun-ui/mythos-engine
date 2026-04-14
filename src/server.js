import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";
import { getInsights } from "./insights.js";
import { register, login, verify } from "./auth.js";
import { initDb, getDb } from "./db.js";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const publicDir = path.join(__dirname, "..", "public_dashboard");

app.use(express.static(publicDir));

function authMiddleware(req, res, next) {
  try {
    const token = req.headers.authorization;
    if (!token) throw new Error("No token");

    const user = verify(token);
    req.user = user;
    next();
  } catch {
    res.status(401).json({ error: "Unauthorized" });
  }
}

app.post("/api/register", async (req, res) => {
  try {
    const user = await register(req.body.email, req.body.password);
    res.json(user);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.post("/api/login", async (req, res) => {
  try {
    const token = await login(req.body.email, req.body.password);
    res.json({ token });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.post("/api/insights", authMiddleware, async (req, res) => {
  try {
    const result = await getInsights(req.body);
    const db = getDb();

    await db.run(
      `INSERT INTO insights_history (
        user_id, revenue, previous_revenue, churn, previous_churn, users_count,
        insight, why_it_matters, action, risk, revenue_growth, churn_delta, human_layer
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        req.user.id,
        Number(req.body.revenue),
        Number(req.body.previousRevenue),
        Number(req.body.churn),
        Number(req.body.previousChurn),
        Number(req.body.users || 0),
        result.insight,
        result.whyItMatters,
        result.action,
        result.risk,
        result.revenueGrowth,
        result.churnDelta,
        result.humanLayer,
      ]
    );

    res.json(result);
  } catch (err) {
    console.error("INSIGHTS ERROR:", err);
    res.status(500).json({ error: "Insight engine failed", details: err.message });
  }
});

app.get("/api/history", authMiddleware, async (req, res) => {
  try {
    const db = getDb();

    const rows = await db.all(
      `SELECT id, revenue, previous_revenue, churn, previous_churn,
              insight, why_it_matters, action, risk, revenue_growth,
              churn_delta, human_layer, created_at
       FROM insights_history
       WHERE user_id = ?
       ORDER BY created_at DESC
       LIMIT 20`,
      [req.user.id]
    );

    res.json(rows);
  } catch (err) {
    console.error("HISTORY ERROR:", err);
    res.status(500).json({ error: "Failed to load history" });
  }
});

app.get("/", (req, res) => {
  res.sendFile(path.join(publicDir, "index.html"));
});

const PORT = process.env.PORT || 3002;

initDb()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`AI Product running on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error("DB INIT ERROR:", err);
    process.exit(1);
  });
