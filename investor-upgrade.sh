#!/bin/bash

echo "💼 Upgrading to INVESTOR MODE..."

# =========================
# FRONTEND
# =========================
cat << 'HTML' > public_dashboard/index.html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Investor Dashboard</title>
</head>

<body style="background:#020617; color:white; font-family:sans-serif; padding:30px;">

<h1>💼 Investor Dashboard</h1>

<!-- KPI CARDS -->
<div style="display:flex; gap:15px; margin-top:20px;">

  <div style="background:#0f172a; padding:15px; border-radius:12px; flex:1;">
    👥 Users<br><h2 id="users">--</h2>
  </div>

  <div style="background:#0f172a; padding:15px; border-radius:12px; flex:1;">
    💰 Revenue<br><h2 id="revenue">--</h2>
  </div>

  <div style="background:#0f172a; padding:15px; border-radius:12px; flex:1;">
    📊 Sessions<br><h2 id="sessions">--</h2>
  </div>

</div>

<!-- AI PANEL -->
<div style="
  background: linear-gradient(135deg, #0f172a, #020617);
  padding: 24px;
  border-radius: 16px;
  margin-top: 25px;
  font-family: monospace;
  box-shadow: 0 0 25px rgba(0,0,0,0.5);
">

  <div style="display:flex; justify-content:space-between;">
    <h2>🧠 Investor AI</h2>
    <span id="status">● live</span>
  </div>

  <div id="ai" style="margin-top:15px; line-height:1.6;"></div>
</div>

<script>

function rand(min,max){return Math.floor(Math.random()*max)+min}

async function load() {
  const res = await fetch("/api/insights");
  const data = await res.json();

  // fake KPI (kan kopplas till DB senare)
  document.getElementById("users").innerText = rand(100,900);
  document.getElementById("revenue").innerText = rand(1000,9000);
  document.getElementById("sessions").innerText = rand(50,500);

  let text = data.insights;

  // investor formatting
  text = text
    .replace(/\\n/g,"<br>")
    .replace(/risk/gi,"⚠️ RISK")
    .replace(/growth/gi,"📈 GROWTH")
    .replace(/revenue/gi,"💰 REVENUE");

  document.getElementById("ai").innerHTML = text;
}

load();
setInterval(load,5000);

</script>

</body>
</html>
HTML

# =========================
# BACKEND (INVESTOR PROMPT)
# =========================
cat << 'SERVER' > server.js
import dotenv from "dotenv";
dotenv.config();

import express from "express";
import path from "path";
import { fileURLToPath } from "url";
import OpenAI from "openai";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = 3001;

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

app.use("/dashboard", express.static(path.join(__dirname, "public_dashboard")));

app.get("/api/insights", async (req, res) => {
  try {

    const response = await client.responses.create({
      model: "gpt-4o-mini",
      input: `
You are a FUNDING INVESTOR.

Write brutally honest startup analysis:

Rules:
- be direct
- mention risk clearly
- focus on money, growth, retention
- no fluff
- 3–5 short lines max

Tone: like a VC deciding whether to invest or not.
`
    });

    res.json({
      insights: response.output_text
    });

  } catch (err) {
    console.error("🔥 FULL AI ERROR:", err);
    res.status(500).json({
      error: "AI failed",
      details: err.message
    });
  }
});

app.listen(PORT, () => {
  console.log("💼 Investor mode running: http://localhost:" + PORT + "/dashboard");
});
SERVER

echo "✅ Investor mode ready"
echo "👉 Kör: ./restart.sh"
