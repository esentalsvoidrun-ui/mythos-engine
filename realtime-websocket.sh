#!/bin/bash

echo "⚡ Upgrading to REALTIME WebSocket system..."

npm install ws express sqlite3 openai

cat << 'SERVER' > server.js
import dotenv from "dotenv";
dotenv.config();

import express from "express";
import path from "path";
import { fileURLToPath } from "url";
import OpenAI from "openai";
import sqlite3 from "sqlite3";
import { WebSocketServer } from "ws";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = 3001;

app.use(express.json());

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

// =========================
// DB
// =========================
const db = new sqlite3.Database("./realtime.db");

db.run(`
CREATE TABLE IF NOT EXISTS decisions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  message TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
`);

function saveDecision(message) {
  db.run("INSERT INTO decisions (message) VALUES (?)", [message]);
}

// =========================
// HTTP SERVER
// =========================
const server = app.listen(PORT, () => {
  console.log("⚡ Realtime engine running on http://localhost:" + PORT);
});

// =========================
// WEBSOCKET SERVER
// =========================
const wss = new WebSocketServer({ server });

function broadcast(data) {
  wss.clients.forEach(client => {
    if (client.readyState === 1) {
      client.send(JSON.stringify(data));
    }
  });
}

// =========================
// DECISION ENGINE (fake realtime signals)
// =========================
setInterval(async () => {

  const signals = [
    { type: "users", value: Math.floor(Math.random()*900) },
    { type: "revenue", value: Math.floor(Math.random()*9000) },
    { type: "sessions", value: Math.floor(Math.random()*500) }
  ];

  const event = signals[Math.floor(Math.random()*signals.length)];

  let decision = "";

  if (event.type === "revenue" && event.value < 2000) {
    decision = "⚠️ Revenue drop detected";
  } else if (event.type === "users" && event.value > 700) {
    decision = "📈 User spike detected";
  } else if (event.type === "sessions" && event.value < 120) {
    decision = "📉 Engagement drop detected";
  } else {
    decision = "🟢 Stable system";
  }

  saveDecision(decision);

  broadcast({
    event,
    decision,
    time: new Date().toLocaleTimeString()
  });

}, 3000);

// =========================
// STATIC DASHBOARD
// =========================
app.use("/dashboard", express.static(path.join(__dirname, "public_dashboard")));
SERVER

# =========================
# FRONTEND (WEBSOCKET UI)
# =========================
cat << 'HTML' > public_dashboard/index.html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Realtime Mission Control</title>
</head>

<body style="background:#020617; color:white; font-family:sans-serif; padding:25px;">

<h1>⚡ Realtime Mission Control</h1>

<div style="background:#0f172a; padding:15px; border-radius:12px;">
  <h3>🚨 Live Stream</h3>
  <div id="stream">Waiting for signals...</div>
</div>

<div style="margin-top:20px; background:#111b2e; padding:15px; border-radius:12px;">
  <h3>📊 Latest Event</h3>
  <div id="event">--</div>
</div>

<div style="margin-top:20px; background:#111b2e; padding:15px; border-radius:12px;">
  <h3>🧠 Decision Engine</h3>
  <div id="decision">--</div>
</div>

<script>

const ws = new WebSocket("ws://localhost:3001");

ws.onmessage = (msg) => {
  const data = JSON.parse(msg.data);

  document.getElementById("event").innerHTML =
    data.event.type + ": " + data.event.value;

  document.getElementById("decision").innerHTML =
    data.decision;

  const stream = document.getElementById("stream");
  stream.innerHTML =
    "[" + data.time + "] " + data.decision + "<br>" + stream.innerHTML;
};

</script>

</body>
</html>
HTML

echo "✅ Realtime WebSocket system ready"
echo "👉 Kör: ./restart.sh"
