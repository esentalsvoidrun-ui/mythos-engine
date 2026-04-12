import OpenAI from "openai";
import dotenv from "dotenv";
dotenv.config();

import express from "express";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

app.use(express.static(path.join(__dirname, "public")));
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});
// 🚨 IMPORTANT: Railway provides PORT
const PORT = process.env.PORT || 3000;

app.use(express.json());

// =========================
// SAFE ROUTES
// =========================
app.get("/api/insights", async (req, res) => {
  const data = {
    users: Math.floor(Math.random() * 1000),
    activeUsers: Math.floor(Math.random() * 800),
    revenue: Math.floor(Math.random() * 5000),
    churnRate: Math.random().toFixed(2),
    newUsers: Math.floor(Math.random() * 200)
  };

  let risk = 0;

  if (data.churnRate > 0.3) risk += 40;
  if (data.activeUsers < data.users * 0.5) risk += 30;
  if (data.newUsers < 50) risk += 20;

  const risk_score = Math.min(risk, 100);

  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: `
You are Mythos, a ruthless SaaS risk engine.

Your job:
- Detect revenue risk
- Identify churn signals
- Spot anomalies

Rules:
- No fluff
- Be direct and confident
- Focus only on risk

Output:
- Bullet points only
- Max 5 lines
`
        },
        {
          role: "user",
          content: `Data: ${JSON.stringify(data)}`
        }
      ]
    });

    const insight = completion.choices[0].message.content;

    res.json({
      data,
      risk_score,
      insights: insight.split("\n")
    });

  } catch (err) {
    console.error(err);
    res.json({
      data,
      risk_score,
      insights: ["AI failed"]
    });
  }
});
// =========================
// STATIC DASHBOARD
// =========================
app.use("/dashboard", express.static(path.join(__dirname, "public_dashboard")));

// =========================
// START SERVER (ONLY ONCE)
// =========================
const server = app.listen(PORT, () => {
  console.log("🚀 Railway Production Running on PORT " + PORT);
});

// =========================
// WEBSOCKET (ATTACHED TO SAME SERVER)
// =========================
const wss = new WebSocketServer({ server });

wss.on("connection", (ws) => {
  console.log("🔌 Client connected");

  ws.send(JSON.stringify({
    type: "connected",
    message: "live system active"
  }));

  const interval = setInterval(() => {
    if (ws.readyState === ws.OPEN) {
      ws.send(JSON.stringify({
        type: "heartbeat",
        time: new Date().toLocaleTimeString()
      }));
    }
  }, 4000);

  ws.on("close", () => {
    clearInterval(interval);
    console.log("🔌 Client disconnected");
  ;
});
app.get("/api/insights", async (req, res) => {
  const data = {
    users: Math.floor(Math.random() * 1000),
    activeUsers: Math.floor(Math.random() * 800),
    revenue: Math.floor(Math.random() * 5000),
    churnRate: Math.random().toFixed(2),
    newUsers: Math.floor(Math.random() * 200)
  };

  let risk = 0;

  if (data.churnRate > 0.3) risk += 40;
  if (data.activeUsers < data.users * 0.5) risk += 30;
  if (data.newUsers < 50) risk += 20;

  const risk_score = Math.min(risk, 100);

  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: `
You are Mythos, a ruthless SaaS risk engine.

Your job:
- Detect revenue risk
- Identify churn signals
- Spot anomalies

Rules:
- No fluff
- Be direct and confident
- Focus only on risk

Output:
- Bullet points only
- Max 5 lines
`
        },
        {
          role: "user",
          content: `Data: ${JSON.stringify(data)}`
        }
      ]
    });

    const insight = completion.choices[0].message.content;

    res.json({
      data,
      risk_score,
      insights: insight.split("\n")
    });

  } catch (err) {
    console.error(err);
    res.json({
      data,
      risk_score,
      insights: ["AI failed"]
    });
  }
});
