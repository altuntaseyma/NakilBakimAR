import { Router } from "express";
import bcrypt from "bcryptjs";
import { pool } from "../db/pool.js";
import { signAccessToken, signRefreshToken, verifyRefreshToken } from "../utils/tokens.js";

export const authRouter = Router();

authRouter.post("/register", async (req, res) => {
  try {
    const { email, password, fullName, role } = req.body;
    if (!email || !password || !fullName || !role) {
      return res.status(400).json({ message: "Missing required fields" });
    }
    const hash = await bcrypt.hash(password, 10);
    const userResult = await pool.query(
      "INSERT INTO users (email, password_hash, full_name, role) VALUES ($1,$2,$3,$4) RETURNING id, email, full_name, role",
      [email, hash, fullName, role]
    );
    res.status(201).json(userResult.rows[0]);
  } catch (error) {
    res.status(500).json({ message: "Register failed", error: error.message });
  }
});

authRouter.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    const result = await pool.query("SELECT * FROM users WHERE email = $1", [email]);
    const user = result.rows[0];
    if (!user) return res.status(401).json({ message: "Invalid credentials" });

    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) return res.status(401).json({ message: "Invalid credentials" });

    const payload = { id: user.id, role: user.role, email: user.email };
    res.json({
      accessToken: signAccessToken(payload),
      refreshToken: signRefreshToken(payload),
      user: { id: user.id, email: user.email, role: user.role, fullName: user.full_name }
    });
  } catch (error) {
    res.status(500).json({ message: "Login failed", error: error.message });
  }
});

authRouter.post("/refresh", async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.status(400).json({ message: "refreshToken required" });
    const payload = verifyRefreshToken(refreshToken);
    res.json({ accessToken: signAccessToken(payload) });
  } catch {
    res.status(401).json({ message: "Invalid refresh token" });
  }
});
