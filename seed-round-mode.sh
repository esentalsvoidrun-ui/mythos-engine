#!/bin/bash

echo "🚀 Entering SEED ROUND MODE..."

# =========================
# INSTALL DATABASE
# =========================
npm install sqlite3

# =========================
# FRONTEND (clean SaaS UI)
# =========================
cat << 'HTML' > public_dashboard/index.html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Seed Round Dashboard</title>
</head>

<body style="background:#0b1220; color:white; font-family:sans-serif; padding:30px;">

<h1>🚀 Seed Round Dashboard</h1>

<div style="margin-top:20px; padding:15px; background:#111b2e; border-radius:12px;">
  <h3>👤 Login (demo)</h3>
  <input id="user" placeholder="user" style="padding:8px;">
  <input id="pass" type="password" placeholder="pass" style="padding:8px;">
  <button onclick="login()">Enter</button>
</div>

<div id="app" style="display:none;">

  <h2 style="margin-top:30px;">📊 Live Metrics</h2>

  <div style="display:flex; gap:10px;">
    <div style="flex:1; background:#111b2e; padding:10px; border-radius:10px;">
      Users <h3 id="users">--</h3>
    </div>
    <div style="flex:1; background:#111b2e; padding:10px; border-radius:10px;">
      Revenue <h3 id="revenue">--</h3>
    </div>
    <div style="flex:1; background:#111b2e; padding:10px; border-radius:10px;">
      Sessions <h3 id="sessions">--</h3>
    </div>
  </div>

  <div style="margin-top:20px; background:#111b2e; padding:15px; border-radius:12px;">
    <h3>🧠 Investor AI</h3>
    <div id="ai"></div>
  </div>

</div>

<script>
function login(){
  const u = document.getElementById("user").value;
  const p = document.getElementById("pass").value;

  if(u==="admin" && p==="admin"){
    document.getElementById("app").style.display="block";
  } else {
    alert("wrong demo login (admin/admin)");
  }
}

function rand(min,max){return Math.floor(Math.random()*max)+min}

async function load(){
  const res = await fetch("/api/insights");
  const data = await res.json();

  document.getElementById("users").innerText = rand(100,900);
  document.getElementById("revenue").innerText = rand(1000,9000);
  document.getElementById("sessions").innerText = rand(50,500);

  document.getElementById("ai").innerHTML = data.insights;
}

setInterval(load,5000);
</script>

</body>
</html>
HTML

# =========================
# BACKEND (SQLite + AI)
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

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

// DB
const db = new sqlite3.Database("./data.db");

db.run(`
CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT,
  value INTEGER
)
`);

app.use("/dashboard", express.static(path.join(__dirname, "public_dashboard")));

app.get("/api/insights", async (req, res) => {
  try {

    const response = await client.responses.create({
      model: "gpt-4o-mini",
      input: `
You are a SEED STAGE VC.

Analyze startup metrics brutally:
- traction
- risk
- scalability
- investor perspective

Be extremely concise (max 5 lines).
`
    });

    res.json({
      insights: response.output_text
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({
      error: "AI failed",
      details: err.message
    });
  }
});

app.listen(PORT, () => {
  console.log("🚀 Seed round running on http://localhost:" + PORT + "/dashboard");
});
SERVER

echo "✅ Seed round mode ready"
echo "👉 Kör: ./restart.sh"
