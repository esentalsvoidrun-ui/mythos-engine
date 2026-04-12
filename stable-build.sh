#!/bin/bash

echo "🧼 Building STABLE production core..."

npm install express ws sqlite3 dotenv cors

# =========================
# CLEAN SERVER (NO CHAOS)
# =========================
cat << 'SERVER' > server.js
import dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import path from "path";
import { fileURLToPath } from "url";
import sqlite3 from "sqlite3";
import { WebSocketServer } from "ws";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

// =========================
// DATABASE (STABLE)
// =========================
const db = new sqlite3.Database("./app.db");

db.run(`
CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT,
  value INTEGER,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
`);

// =========================
// STATIC DASHBOARD
// =========================
app.use("/dashboard", express.static(path.join(__dirname, "public_dashboard")));

// =========================
// HEALTH CHECK (IMPORTANT FOR RAILWAY)
// =========================
app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

// =========================
// SIMPLE API
// =========================
app.get("/api/status", (req, res) => {
  res.json({
    service: "stable-saas",
    time: new Date().toISOString()
  });
});

// =========================
// SAVE EVENT (SAFE)
// =========================
app.post("/api/event", (req, res) => {
  const { type, value } = req.body;

  if (!type || value === undefined) {
    return res.status(400).json({ error: "Invalid event" });
  }

  db.run(
    "INSERT INTO events (type, value) VALUES (?, ?)",
    [type, value]
  );

  res.json({ status: "stored" });
});

// =========================
// GET EVENTS
// =========================
app.get("/api/events", (req, res) => {
  db.all(
    "SELECT * FROM events ORDER BY id DESC LIMIT 20",
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ events: rows });
    }
  );
});

// =========================
// START SERVER
// =========================
const server = app.listen(PORT, () => {
  console.log("🚀 STABLE BUILD RUNNING ON PORT " + PORT);
});

// =========================
// WEBSOCKET (SAFE REALTIME)
// =========================
const wss = new WebSocketServer({ server });

wss.on("connection", (ws) => {
  ws.send(JSON.stringify({ type: "connected" }));

  const interval = setInterval(() => {
    ws.send(JSON.stringify({
      type: "heartbeat",
      time: new Date().toLocaleTimeString()
    }));
  }, 5000);

  ws.on("close", () => clearInterval(interval));
});
SERVER

# =========================
# CLEAN FRONTEND
# =========================
mkdir -p public_dashboard

cat << 'HTML' > public_dashboard/index.html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Stable SaaS Dashboard</title>
</head>

<body style="background:#0b1220;color:white;font-family:sans-serif;padding:20px;">

<h1>🧼 Stable SaaS Dashboard</h1>

<div id="status">Connecting...</div>

<div style="margin-top:20px;">
  <h3>📡 Live WebSocket</h3>
  <div id="live"></div>
</div>

<div style="margin-top:20px;">
  <h3>📊 Events</h3>
  <button onclick="loadEvents()">Refresh</button>
  <div id="events"></div>
</div>

<script>
const ws = new WebSocket("ws://localhost:3001");

ws.onmessage = (msg) => {
  const data = JSON.parse(msg.data);
  document.getElementById("status").innerText = "🟢 Connected";
  document.getElementById("live").innerHTML =
    JSON.stringify(data) + "<br>" + document.getElementById("live").innerHTML;
};

async function loadEvents() {
  const res = await fetch("/api/events");
  const data = await res.json();

  document.getElementById("events").innerHTML =
    data.events.map(e => 
      `<div>⚡ ${e.type} → ${e.value}</div>`
    ).join("");
}

loadEvents();
</script>

</body>
</html>
HTML

echo "✅ Stable build ready"
echo "👉 Kör: ./restart.sh"
