import { Router } from "express";
import { pool } from "../db/pool.js";
import { allowRoles, authRequired } from "../middleware/auth.js";

export const patientsRouter = Router();
patientsRouter.use(authRequired);

patientsRouter.get("/me/profile", allowRoles("patient"), async (req, res) => {
  const result = await pool.query(
    `SELECT pp.*, u.full_name, u.email,
            CASE WHEN pp.transplant_date IS NOT NULL AND pp.transplant_date <= NOW()
              THEN 'post_op' ELSE 'pre_op' END AS care_phase
     FROM patient_profiles pp
     JOIN users u ON u.id = pp.user_id
     WHERE pp.user_id = $1
     LIMIT 1`,
    [req.user.id]
  );
  res.json(result.rows[0] || null);
});

patientsRouter.get("/me/modules", allowRoles("patient"), async (req, res) => {
  const profile = await pool.query(
    "SELECT id FROM patient_profiles WHERE user_id = $1 LIMIT 1",
    [req.user.id]
  );
  if (!profile.rows[0]) return res.json([]);

  const patientId = profile.rows[0].id;
  const result = await pool.query(
    `SELECT cm.id, cm.name, COALESCE(pm.is_enabled, false) AS is_enabled
     FROM care_modules cm
     LEFT JOIN patient_modules pm
       ON pm.module_id = cm.id AND pm.patient_id = $1
     ORDER BY cm.id`,
    [patientId]
  );
  res.json(result.rows);
});

patientsRouter.get("/", allowRoles("nurse"), async (req, res) => {
  const result = await pool.query(
    `SELECT pp.*, u.full_name, u.email,
            CASE WHEN pp.transplant_date IS NOT NULL AND pp.transplant_date <= NOW()
              THEN 'post_op' ELSE 'pre_op' END AS care_phase
     FROM patient_profiles pp
     JOIN users u ON u.id = pp.user_id
     WHERE pp.nurse_id = $1
     ORDER BY u.full_name ASC`,
    [req.user.id]
  );
  res.json(result.rows);
});

patientsRouter.post("/", allowRoles("nurse"), async (req, res) => {
  const { userId, diagnosis, transplantDate } = req.body;
  const result = await pool.query(
    `INSERT INTO patient_profiles (user_id, diagnosis, transplant_date, nurse_id)
     VALUES ($1,$2,$3,$4) RETURNING *`,
    [userId, diagnosis || null, transplantDate || null, req.user.id]
  );
  res.status(201).json(result.rows[0]);
});

patientsRouter.put("/:id/operation", allowRoles("nurse"), async (req, res) => {
  const { transplantDate } = req.body;
  const value = transplantDate || null;
  const result = await pool.query(
    `UPDATE patient_profiles pp
     SET transplant_date = $2
     WHERE pp.id = $1 AND pp.nurse_id = $3
     RETURNING pp.*, CASE WHEN pp.transplant_date IS NOT NULL AND pp.transplant_date <= NOW()
       THEN 'post_op' ELSE 'pre_op' END AS care_phase`,
    [req.params.id, value, req.user.id]
  );
  if (!result.rows[0]) return res.status(404).json({ message: "Patient not found" });
  res.json(result.rows[0]);
});

patientsRouter.get("/:id/modules", allowRoles("nurse"), async (req, res) => {
  const result = await pool.query(
    `SELECT cm.id, cm.name, COALESCE(pm.is_enabled, false) AS is_enabled
     FROM care_modules cm
     LEFT JOIN patient_modules pm
       ON pm.module_id = cm.id AND pm.patient_id = $1
     ORDER BY cm.id`,
    [req.params.id]
  );
  res.json(result.rows);
});

patientsRouter.put("/:id/modules", allowRoles("nurse"), async (req, res) => {
  const { modules } = req.body;
  if (!Array.isArray(modules)) return res.status(400).json({ message: "modules array required" });

  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    for (const m of modules) {
      await client.query(
        `INSERT INTO patient_modules (patient_id, module_id, is_enabled)
         VALUES ($1,$2,$3)
         ON CONFLICT (patient_id, module_id) DO UPDATE SET is_enabled = EXCLUDED.is_enabled`,
        [req.params.id, m.moduleId, Boolean(m.isEnabled)]
      );
    }
    await client.query("COMMIT");
    res.json({ success: true });
  } catch (error) {
    await client.query("ROLLBACK");
    res.status(500).json({ message: "Module update failed", error: error.message });
  } finally {
    client.release();
  }
});
