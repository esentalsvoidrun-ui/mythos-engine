#!/bin/bash

echo "🏗️ Building Production SaaS Base..."

# =========================
# CLEAN INSTALLS
# =========================
npm install express ws sqlite3 dotenv jsonwebtoken bcrypt cors

# =========================
# ENV FILE
# =========================
cat << 'ENV' > .env
PORT=3001
JWT_SECRET=supersecret_dev_key_change_me
OPENAI_API_KEY=your_key_here
ENV=development
ENV

# =========================
# SERVER (PRODUCTION STRUCTURE)
# =========================
cat << 'SERVER' > server.js
import dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";
import sqlite3 from "sqlite3";
import path from "path";
import { fileURLToPath } from "url";
import { WebSocketServer } from "ws";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());
app.use("/dashboard", express.static(path.join(__dirname, "public_dashboard")));

// =========================
// DB
// =========================
const db = new sqlite3.Database("./saas.db");

db.run(`
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE,
  password TEXT
);
`);

db.run(`
CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT,
  value INTEGER
);
`);

// =========================
// AUTH
// =========================
app.post("/auth/register", async (req, res) => {
  const { email, password } = req.body;

  const hashed = await bcrypt.hash(password, 10);

  db.run(
    "INSERT INTO users (email, password) VALUES (?, ?)",
    [email, hashed],
    (err) => {
      if (err) return res.status(400).json({ error: "User exists" });

      res.json({ status: "registered" });
    }
  );
});

app.post("/auth/login", (req, res) => {
  const { email, password } = req.body;

  db.get("SELECT * FROM users WHERE email = ?", [email], async (err, user) => {
    if (!user) return res.status(401).json({ error: "Invalid" });

    const ok = await bcrypt.compare(password, user.password);
    if (!ok) return res.status(401).json({ error: "Invalid" });

    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET);

    res.json({ token });
  });
});

// =========================
// MIDDLEWARE (PROTECT API)
// =========================
function auth(req, res, next) {
  const token = req.headers.authorization;

  if (!token) return res.status(401).json({ error: "No token" });

  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: "Invalid token" });
  }
}

// =========================
// EVENT API (PROTECTED)
// =========================
app.post("/event", auth, (req, res) => {
  const { type, value } = req.body;

  db.run("INSERT INTO events (type, value) VALUES (?, ?)", [type, value]);

  res.json({ status: "stored" });
});

app.get("/events", auth, (req, res) => {
  db.all("SELECT * FROM events ORDER BY id DESC LIMIT 20", (err, rows) => {
    res.json({ events: rows });
  });
});

// =========================
// HTTP SERVER
// =========================
const server = app.listen(PORT, () => {
  console.log("🚀 Production SaaS running on http://localhost:" + PORT);
});

// =========================
// WEBSOCKET (REALTIME LAYER)
// =========================
const wss = new WebSocketServer({ server });

wss.on("connection", ws => {
  ws.send(JSON.stringify({ status: "connected" }));
});

console.log("🧠 SaaS Core Initialized");
SERVER

# =========================
# SIMPLE DASHBOARD (LOGIN READY)
# =========================
mkdir -p public_dashboard

cat << 'HTML' > public_dashboard/index.html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>SaaS Dashboard</title>
</head>

<body style="background:#020617; color:white; font-family:sans-serif; padding:25px;">

<h1>💼 Production SaaS</h1>

<div>
  <input id="email" placeholder="email">
  <input id="password" type="password" placeholder="password">
  <button onclick="register()">Register</button>
  <button onclick="login()">Login</button>
</div>

<div id="status" style="margin-top:20px;"></div>

<script>

let token = null;

async function register() {
  await fetch("/auth/register", {
    method:"POST",
    headers:{ "Content-Type":"application/json" },
    body: JSON.stringify({
      email: email.value,
      password: password.value
    })
  });

  document.getElementById("status").innerText = "Registered";
}

async function login() {
  const res = await fetch("/auth/login", {
    method:"POST",
    headers:{ "Content-Type":"application/json" },
    body: JSON.stringify({
      email: email.value,
      password: password.value
    })
  });

  const data = await res.json();
  token = data.token;

  document.getElementById("status").innerText = "Logged in";
}

</script>

</body>
</html>
HTML

echo "✅ Production SaaS base ready"
echo "👉 Kör: ./restart.sh"
