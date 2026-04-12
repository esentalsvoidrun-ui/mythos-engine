import dotenv from "dotenv";
dotenv.config();

import express from "express";
import OpenAI from "openai";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const app = express();
app.use(express.json());

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const HISTORY_FILE = path.join(__dirname, "history.json");

// ===== LOAD MEMORY =====
let history = [];
try {
  const raw = fs.readFileSync(HISTORY_FILE, "utf-8");
  history = JSON.parse(raw);
} catch {
  history = [];
}

// ===== SAVE MEMORY =====
function saveHistory() {
  fs.writeFileSync(HISTORY_FILE, JSON.stringify(history, null, 2));
}

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

const PORT = process.env.PORT || 3001;

// ===== ALERT STORAGE =====
let alerts = [];

function triggerAlert(message, level = "warning") {
  const alert = {
    message,
    level,
    time: new Date().toISOString()
  };

  alerts.push(alert);
  if (alerts.length > 50) alerts.shift();

  console.log("🚨 ALERT:", alert);
}

// ===== ROUTES =====
app.get("/", (req, res) => {
  res.send("Mythos Core is alive ⚡");
});

app.get("/api/alerts", (req, res) => {
  res.json(alerts);
});

app.get("/api/insights", async (req, res) => {
  const data = {
    users: Math.floor(Math.random() * 1000),
    activeUsers: Math.floor(Math.random() * 800),
    revenue: Math.floor(Math.random() * 5000),
    churnRate: Number(Math.random().toFixed(2)),
    newUsers: Math.floor(Math.random() * 200)
  };

  // ===== MEMORY =====
  history.push({
    ...data,
    timestamp: Date.now()
  });

  if (history.length > 50) history.shift();
  saveHistory();

  // ===== TREND =====
  let trend = "stable";
  if (history.length > 1) {
    const prev = history[history.length - 2];
    if (data.revenue > prev.revenue) trend = "up";
    if (data.revenue < prev.revenue) trend = "down";
  }

  // ===== RISK =====
  let risk = 0;
  if (data.churnRate > 0.3) risk += 40;
  if (data.activeUsers < data.users * 0.5) risk += 30;
  if (data.newUsers < 50) risk += 20;

  const risk_score = Math.min(risk, 100);

  // ===== ALERT LOGIC =====
  if (risk_score > 70) {
    triggerAlert("High risk detected", "critical");
  }

  if (trend === "down") {
    triggerAlert("Revenue trending down", "warning");
  }

  if (data.churnRate > 0.4) {
    triggerAlert("Churn spike detected", "critical");
  }

  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: "You are Mythos, a sharp SaaS risk engine. Be concise."
        },
        {
          role: "user",
          content: `
Data: ${JSON.stringify(data)}
Trend: ${trend}
Risk: ${risk_score}
`
        }
      ]
    });

    const insight = completion.choices[0].message.content;

    res.json({
      data,
      trend,
      risk_score,
      alerts,
      insights: insight.split("\n")
    });

  } catch (err) {
    console.error(err);
    res.json({
      data,
      trend,
      risk_score,
      alerts,
      insights: ["AI failed"]
    });
  }
});

app.listen(PORT, () => {
  console.log(`Mythos Core running on http://localhost:${PORT}`);
});
