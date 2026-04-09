import { Router } from "express";
import { pool } from "../db/pool.js";
import { authRequired } from "../middleware/auth.js";

export const scenariosRouter = Router();
scenariosRouter.use(authRequired);

scenariosRouter.post("/log", async (req, res) => {
  const body = req.body;
  if (!body.patientId || !body.scenarioKey) {
    return res.status(400).json({ message: "patientId and scenarioKey required" });
  }

  if (req.user.role === "patient") {
    const own = await pool.query(
      "SELECT id FROM patient_profiles WHERE id = $1 AND user_id = $2 LIMIT 1",
      [body.patientId, req.user.id]
    );
    if (!own.rows[0]) return res.status(403).json({ message: "Forbidden" });
  }

  const result = await pool.query(
    `INSERT INTO scenario_logs (
      patient_id, scenario_key, decision_key, selected_option,
      was_correct, module_duration_sec
    ) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [
      body.patientId,
      body.scenarioKey,
      body.decisionKey || null,
      body.selectedOption || null,
      body.wasCorrect ?? null,
      body.moduleDurationSec ?? null
    ]
  );
  res.status(201).json(result.rows[0]);
});

scenariosRouter.get("/patient/:id", async (req, res) => {
  if (req.user.role === "patient") {
    const own = await pool.query(
      "SELECT id FROM patient_profiles WHERE id = $1 AND user_id = $2 LIMIT 1",
      [req.params.id, req.user.id]
    );
    if (!own.rows[0]) return res.status(403).json({ message: "Forbidden" });
  }
  const logs = await pool.query(
    "SELECT * FROM scenario_logs WHERE patient_id = $1 ORDER BY created_at DESC LIMIT 100",
    [req.params.id]
  );
  res.json(logs.rows);
});

scenariosRouter.get("/patient/:id/summary", async (req, res) => {
  if (req.user.role === "patient") {
    const own = await pool.query(
      "SELECT id FROM patient_profiles WHERE id = $1 AND user_id = $2 LIMIT 1",
      [req.params.id, req.user.id]
    );
    if (!own.rows[0]) return res.status(403).json({ message: "Forbidden" });
  }

  const summary = await pool.query(
    `SELECT
      COUNT(*)::int AS total_decisions,
      COALESCE(SUM(CASE WHEN was_correct = true THEN 1 ELSE 0 END), 0)::int AS correct_decisions,
      COALESCE(ROUND(AVG(module_duration_sec)), 0)::int AS avg_duration_sec,
      COALESCE(ROUND(100.0 * SUM(CASE WHEN was_correct = true THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0)),0)::int AS success_rate
     FROM scenario_logs
     WHERE patient_id = $1`,
    [req.params.id]
  );
  res.json(summary.rows[0]);
});
