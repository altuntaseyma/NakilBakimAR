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
      blood_pressure_diastolic, heart_rate, oxygen_saturation, notes, shared_with_patient
    ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
    [
      v.patientId,
      req.user.id,
      v.bodyTemperature,
      v.bloodPressureSystolic,
      v.bloodPressureDiastolic,
      v.heartRate,
      v.oxygenSaturation,
      v.notes || null,
      Boolean(v.sharedWithPatient)
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
