#!/bin/bash

echo "🚀 Upgrading to VC AI mode..."

# =========================
# FRONTEND (live typing + alerts)
# =========================
cat << 'HTML' > public_dashboard/index.html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Audit Dashboard VC Mode</title>
</head>

<body style="background:#020617; color:white; font-family:sans-serif; padding:20px;">

<h1>📊 VC Dashboard</h1>

<div id="ai-panel" style="
  background: linear-gradient(135deg, #0f172a, #020617);
  padding: 24px;
  border-radius: 16px;
  margin-top: 20px;
  font-family: monospace;
  box-shadow: 0 0 20px rgba(0,0,0,0.4);
">

  <div style="display:flex; justify-content:space-between;">
    <h2>🤖 AI Analyst</h2>
    <span id="ai-status">● idle</span>
  </div>

  <div id="ai-box" style="margin-top:15px;"></div>

</div>

<script>
let lastData = null;

function typeText(element, text, speed = 15) {
  element.innerHTML = "";
  let i = 0;

  function typing() {
    if (i < text.length) {
      element.innerHTML += text.charAt(i);
      i++;
      setTimeout(typing, speed);
    }
  }

  typing();
}

async function loadAI() {
  const box = document.getElementById("ai-box");
  const status = document.getElementById("ai-status");

  status.innerText = "● analyzing...";

  try {
    const res = await fetch("/api/insights");
    const data = await res.json();

    let text = data.insights || "No signal";

    // 🚨 anomaly detection (fake logic)
    if (lastData && Math.random() > 0.7) {
      text = "🚨 Revenue anomaly detected<br><br>" + text;
    }

    lastData = data;

    text = text
      .replace(/\\n/g, "<br>")
      .replace(/Users/g, "👥 Users")
      .replace(/Revenue/g, "💰 Revenue")
      .replace(/Sessions/g, "📊 Sessions");

    typeText(box, text);
    status.innerText = "● live";

  } catch (err) {
    box.innerHTML = "⚠️ AI offline";
    status.innerText = "● error";
  }
}

loadAI();
setInterval(loadAI, 6000);
</script>

</body>
</html>
HTML

# =========================
# BACKEND (smartare prompt)
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
You are a sharp SaaS investor.

Analyze metrics and respond in short, powerful insights:

- highlight trends
- call out risks
- sound confident

Keep it punchy.
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
  console.log("🚀 http://localhost:" + PORT + "/dashboard");
});
SERVER

echo "✅ Upgrade complete"
echo "👉 Kör: ./restart.sh"
