import { Router } from "express";
import { pool } from "../db/pool.js";
import { authRequired } from "../middleware/auth.js";

export const vitalsRouter = Router();
vitalsRouter.use(authRequired);

vitalsRouter.post("/", async (req, res) => {
  if (req.user.role !== "nurse") return res.status(403).json({ message: "Forbidden" });
  const v = req.body;
  const result = await pool.query(
    `INSERT INTO vital_signs (
      patient_id, nurse_id, body_temperature, blood_pressure_systolic,
      blood_pressure_diastolic, heart_rate, oxygen_saturation, notes, shared_with_patient, recorded_at
    ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,COALESCE($10, NOW())) RETURNING *`,
    [
      v.patientId,
      req.user.id,
      v.bodyTemperature,
      v.bloodPressureSystolic,
      v.bloodPressureDiastolic,
      v.heartRate,
      v.oxygenSaturation,
      v.notes || null,
      Boolean(v.sharedWithPatient),
      v.recordedAt || null
    ]
  );
  res.status(201).json(result.rows[0]);
});

vitalsRouter.get("/patient/:id", async (req, res) => {
  const patientId = req.params.id;
  let query = "SELECT * FROM vital_signs WHERE patient_id = $1 ORDER BY recorded_at DESC";
  if (req.user.role === "patient") {
    query = "SELECT * FROM vital_signs WHERE patient_id = $1 AND shared_with_patient = true ORDER BY recorded_at DESC";
  }
  const result = await pool.query(query, [patientId]);
  res.json(result.rows);
});

vitalsRouter.put("/share/:id", async (req, res) => {
  if (req.user.role !== "nurse") return res.status(403).json({ message: "Forbidden" });

  const sharedWithPatient = req.body?.sharedWithPatient;
  const shouldUseExplicitValue = typeof sharedWithPatient === "boolean";

  const result = await pool.query(
    `UPDATE vital_signs
     SET shared_with_patient = CASE
       WHEN $2::boolean IS NULL THEN NOT shared_with_patient
       ELSE $2
     END
     WHERE id = $1
     RETURNING *`,
    [req.params.id, shouldUseExplicitValue ? sharedWithPatient : null]
  );

  if (!result.rows[0]) {
    return res.status(404).json({ message: "Vital kaydi bulunamadi" });
  }
  res.json(result.rows[0]);
});

vitalsRouter.delete("/:id", async (req, res) => {
  if (req.user.role !== "nurse") return res.status(403).json({ message: "Forbidden" });
  await pool.query("DELETE FROM vital_signs WHERE id = $1", [req.params.id]);
  res.status(204).send();
});
