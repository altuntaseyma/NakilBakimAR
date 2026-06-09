import { Router } from "express";
import bcrypt from "bcryptjs";
import { pool } from "../db/pool.js";
import { allowRoles, authRequired } from "../middleware/auth.js";
import { signAccessToken, signRefreshToken, verifyRefreshToken } from "../utils/tokens.js";

export const authRouter = Router();

function buildAuthResponse(user) {
  const payload = { id: user.id, role: user.role, email: user.email };
  return {
    accessToken: signAccessToken(payload),
    refreshToken: signRefreshToken(payload),
    user: { id: user.id, email: user.email, role: user.role, fullName: user.full_name }
  };
}

function isValidTcNo(tcNo) {
  if (!/^\d{11}$/.test(tcNo)) return false;
  if (tcNo[0] === "0") return false;

  const digits = tcNo.split("").map(Number);
  const oddSum = digits[0] + digits[2] + digits[4] + digits[6] + digits[8];
  const evenSum = digits[1] + digits[3] + digits[5] + digits[7];
  const check10 = ((oddSum * 7) - evenSum) % 10;
  const check11 = digits.slice(0, 10).reduce((sum, n) => sum + n, 0) % 10;

  return check10 === digits[9] && check11 === digits[10];
}

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

authRouter.post("/register/patient", authRequired, allowRoles("nurse"), async (req, res) => {
  const client = await pool.connect();
  try {
    const { tcNo, pin, fullName, carePhase, diagnosis, transplantDate } = req.body;
    const normalizedTc = String(tcNo ?? "").replace(/\D/g, "");
    const normalizedPin = String(pin ?? "").replace(/\D/g, "");

    if (!fullName || !isValidTcNo(normalizedTc) || normalizedPin.length !== 4) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    const effectiveTransplantDate =
      transplantDate || (carePhase === "post_op" ? new Date().toISOString() : null);
    const pinHash = await bcrypt.hash(normalizedPin, 10);
    const syntheticEmail = `patient.${normalizedTc}@nakilbakim.local`;

    await client.query("BEGIN");

    const userResult = await client.query(
      `INSERT INTO users (email, password_hash, full_name, role, patient_tc, patient_pin_hash)
       VALUES ($1,$2,$3,'patient',$4,$5)
       RETURNING id, email, full_name, role, patient_tc`,
      [syntheticEmail, pinHash, fullName, normalizedTc, pinHash]
    );
    const user = userResult.rows[0];

    const profileResult = await client.query(
      `INSERT INTO patient_profiles (user_id, diagnosis, transplant_date, nurse_id)
       VALUES ($1,$2,$3,$4)
       RETURNING *,
         CASE WHEN transplant_date IS NOT NULL AND transplant_date <= NOW()
           THEN 'post_op' ELSE 'pre_op' END AS care_phase`,
      [user.id, diagnosis || null, effectiveTransplantDate, req.user.id]
    );

    await client.query("COMMIT");
    return res.status(201).json({
      user,
      profile: profileResult.rows[0]
    });
  } catch (error) {
    await client.query("ROLLBACK");
    return res.status(500).json({ message: "Patient register failed", error: error.message });
  } finally {
    client.release();
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

    res.json(buildAuthResponse(user));
  } catch (error) {
    res.status(500).json({ message: "Login failed", error: error.message });
  }
});

authRouter.post("/login/patient", async (req, res) => {
  try {
    const { tcNo, pin } = req.body;
    const normalizedTc = String(tcNo ?? "").replace(/\D/g, "");
    const normalizedPin = String(pin ?? "").replace(/\D/g, "");

    if (!isValidTcNo(normalizedTc) || normalizedPin.length !== 4) {
      return res.status(400).json({ message: "tcNo and pin are required" });
    }

    const result = await pool.query(
      "SELECT * FROM users WHERE role = 'patient' AND patient_tc = $1",
      [normalizedTc]
    );
    const user = result.rows[0];
    if (!user || !user.patient_pin_hash) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    const ok = await bcrypt.compare(normalizedPin, user.patient_pin_hash);
    if (!ok) return res.status(401).json({ message: "Invalid credentials" });

    res.json(buildAuthResponse(user));
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
