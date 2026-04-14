import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { getDb } from "./db.js";

const SECRET = process.env.JWT_SECRET;

if (!SECRET) {
  throw new Error("JWT_SECRET is missing");
}

export async function register(email, password) {
  const db = getDb();

  const existing = await db.get(
    "SELECT id, email FROM users WHERE email = ?",
    [email]
  );

  if (existing) {
    throw new Error("User already exists");
  }

  const hash = await bcrypt.hash(password, 10);

  const result = await db.run(
    "INSERT INTO users (email, password) VALUES (?, ?)",
    [email, hash]
  );

  return { id: result.lastID, email };
}

export async function login(email, password) {
  const db = getDb();

  const user = await db.get(
    "SELECT id, email, password FROM users WHERE email = ?",
    [email]
  );

  if (!user) throw new Error("User not found");

  const valid = await bcrypt.compare(password, user.password);
  if (!valid) throw new Error("Wrong password");

  return jwt.sign({ id: user.id, email: user.email }, SECRET);
}

export function verify(token) {
  return jwt.verify(token, SECRET);
}
