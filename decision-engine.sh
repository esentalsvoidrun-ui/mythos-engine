#!/bin/bash

echo "🧠 Building Decision Engine..."

npm install sqlite3

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

app.use(express.json());

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

// =========================
// DATABASE
// =========================
const db = new sqlite3.Database("./engine.db");

db.run(`
CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT,
  value INTEGER,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
`);

db.run(`
CREATE TABLE IF NOT EXISTS decisions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  trigger TEXT,
  action TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
`);

// =========================
// SAVE EVENT
// =========================
function saveEvent(type, value) {
  db.run("INSERT INTO events (type, value) VALUES (?, ?)", [type, value]);
}

// =========================
// SAVE DECISION
// =========================
function saveDecision(trigger, action) {
  db.run("INSERT INTO decisions (trigger, action) VALUES (?, ?)", [trigger, action]);
}

// =========================
// DECISION RULE ENGINE
// =========================
function evaluate(event) {

  let actions = [];

  // RULE 1 — revenue drop
  if (event.type === "revenue" && event.value < 2000) {
    actions.push("⚠️ Revenue drop detected → alert founders");
  }

  // RULE 2 — user spike
  if (event.type === "users" && event.value > 800) {
    actions.push("📈 User spike → scale infra");
  }

  // RULE 3 — session drop
  if (event.type === "sessions" && event.value < 100) {
    actions.push("📉 Engagement drop → investigate product funnel");
  }

  return actions;
}

// =========================
// WEBHOOK ENTRY (EVENT IN)
// =========================
app.post("/event", async (req, res) => {

  const event = req.body;

  console.log("📥 Event:", event);

  saveEvent(event.type, event.value);

  const actions = evaluate(event);

  let aiInsight = "";

  try {
    const ai = await client.responses.create({
      model: "gpt-4o-mini",
      input: `
You are a startup decision engine.

Event:
${JSON.stringify(event)}

Actions:
${actions.join("\n")}

Explain briefly what is happening and what to do next.
Keep it sharp and investor-like.
`
    });

    aiInsight = ai.output_text;

  } catch (err) {
    aiInsight = "AI unavailable";
  }

  // save decision
  saveDecision(event.type, actions.join(" | "));

  res.json({
    event,
    actions,
    aiInsight
  });
});

// =========================
// VIEW DECISIONS
// =========================
app.get("/decisions", (req, res) => {
  db.all("SELECT * FROM decisions ORDER BY id DESC LIMIT 20", (err, rows) => {
    res.json({ decisions: rows });
  });
});

// =========================
// VIEW EVENTS
// =========================
app.get("/events", (req, res) => {
  db.all("SELECT * FROM events ORDER BY id DESC LIMIT 20", (err, rows) => {
    res.json({ events: rows });
  });
});

// =========================
// DASHBOARD
// =========================
app.use("/dashboard", express.static(path.join(__dirname, "public_dashboard")));

app.listen(PORT, () => {
  console.log("🧠 Decision Engine running on http://localhost:" + PORT);
});
SERVER

echo "✅ Decision Engine ready"
echo "👉 Kör: ./restart.sh"
