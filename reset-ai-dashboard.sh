#!/bin/bash

echo "🧹 Resetting AI dashboard..."

# =========================
# 1. AI PANEL (HTML)
# =========================
cat << 'HTML' > public_dashboard/index.html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Audit Dashboard</title>
</head>
<body style="background:#020617; color:white; font-family:sans-serif; padding:20px;">

<h1>📊 Live Dashboard</h1>

<div id="ai-panel" style="
  background: linear-gradient(135deg, #0f172a, #020617);
  color: #e2e8f0;
  padding: 24px;
  border-radius: 16px;
  margin-top: 20px;
  font-family: monospace;
  box-shadow: 0 0 20px rgba(0,0,0,0.4);
">
  <div style="display:flex; justify-content:space-between;">
    <h2>🤖 AI Insights</h2>
    <span id="ai-status">● live</span>
  </div>

  <div id="ai-box">Booting intelligence...</div>
</div>

<script>
async function loadAI() {
  const box = document.getElementById("ai-box");
  const status = document.getElementById("ai-status");

  status.innerText = "● thinking...";
  
  try {
    const res = await fetch("/api/insights");
    const data = await res.json();

    let text = data.insights || "No insights";

    text = text
      .replace(/\\n/g, "<br>")
      .replace(/Users/g, "👥 Users")
      .replace(/Revenue/g, "💰 Revenue")
      .replace(/Sessions/g, "📊 Sessions");

    box.innerHTML = text;
    status.innerText = "● live";

  } catch (err) {
    box.innerHTML = "⚠️ AI offline";
    status.innerText = "● error";
  }
}

loadAI();
setInterval(loadAI, 5000);
</script>

</body>
</html>
HTML

# =========================
# 2. SERVER (server.js)
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
      input: "Give short SaaS metrics insights (users, revenue, sessions)."
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

# =========================
# 3. RESTART SCRIPT
# =========================
cat << 'RESTART' > restart.sh
#!/bin/bash

echo "🧹 Cleaning port 3001..."
fuser -k 3001/tcp 2>/dev/null

echo "🚀 Starting server..."
npm start
RESTART

chmod +x restart.sh

echo "✅ Done!"
echo "👉 Kör: ./restart.sh"
echo "👉 Öppna: http://localhost:3001/dashboard"
