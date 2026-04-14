import sqlite3 from "sqlite3";
import { open } from "sqlite";

let db;

export async function initDb() {
  db = await open({
    filename: "./data/app.sqlite",
    driver: sqlite3.Database,
  });

  await db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL
    );
  `);

  await db.exec(`
    CREATE TABLE IF NOT EXISTS insights_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      revenue REAL NOT NULL,
      previous_revenue REAL NOT NULL,
      churn REAL NOT NULL,
      previous_churn REAL NOT NULL,
      users_count REAL,
      insight TEXT NOT NULL,
      why_it_matters TEXT NOT NULL,
      action TEXT NOT NULL,
      risk TEXT NOT NULL,
      revenue_growth REAL NOT NULL,
      churn_delta REAL NOT NULL,
      human_layer TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
  `);

  return db;
}

export function getDb() {
  if (!db) throw new Error("Database not initialized");
  return db;
}
