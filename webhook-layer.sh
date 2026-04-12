#!/bin/bash

echo "🌐 Building Webhook Layer..."

npm install sqlite3 express

# =========================
# SERVER UPDATE
# =========================
cat << 'SERVER' > server.js
import dotenv from "dotenv";
dotenv.config();

import express from "express";
import path from "path";
import { fileURLToPath } from "url";
import OpenAI from "openai";
import sqlite3 from "sqlite3";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = 3001;

app.use(express.json()); // 👈 webhook body support

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

// =========================
// DATABASE (AUDIT LOG)
// =========================
const db = new sqlite3.Database("./audit.db");

db.run(`
CREATE TABLE IF NOT EXISTS audit_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT,
  payload TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
`);

// helper log function
function logEvent(type, payload) {
  db.run(
    "INSERT INTO audit_logs (type, payload) VALUES (?, ?)",
    [type, JSON.stringify(payload)]
  );
}

// =========================
// WEBHOOK LAYER 🚨
// =========================
app.post("/webhook/event", (req, res) => {
  const event = req.body;

  console.log("📩 Webhook received:", event.type);

  logEvent("webhook", event);

  res.json({
    status: "received",
    stored: true
  });
});

// =========================
// SIMPLE ANALYTICS ENDPOINT
// =========================
app.get("/api/audit", (req, res) => {
  db.all(
    "SELECT * FROM audit_logs ORDER BY id DESC LIMIT 20",
    (err, rows) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      res.json({ logs: rows });
    }
  );
});

// =========================
// DASHBOARD
// =========================
app.use("/dashboard", express.static(path.join(__dirname, "public_dashboard")));

// =========================
// AI INSIGHTS
// =========================
app.get("/api/insights", async (req, res) => {
  try {
    const response = await client.responses.create({
      model: "gpt-4o-mini",
      input: `
You are a startup AI analyst.

Analyze incoming system activity.

Be short, sharp, investor-style.
Focus on risk, growth, anomalies.
`
    });

    res.json({
      insights: response.output_text
    });

  } catch (err) {
    console.error("AI ERROR:", err);
    res.status(500).json({ error: "AI failed", details: err.message });
  }
});

// =========================
// START SERVER
// =========================
app.listen(PORT, () => {
  console.log("🌐 Webhook Layer running on http://localhost:" + PORT);
});
SERVER

echo "✅ Webhook layer installed"
echo "👉 Kör: ./restart.sh"
