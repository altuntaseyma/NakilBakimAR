import { Router } from "express";
import { pool } from "../db/pool.js";
import { authRequired } from "../middleware/auth.js";

export const tasksRouter = Router();
tasksRouter.use(authRequired);

tasksRouter.post("/", async (req, res) => {
  if (req.user.role !== "nurse") return res.status(403).json({ message: "Forbidden" });
  const t = req.body;
  const result = await pool.query(
    `INSERT INTO tasks (
      patient_id, assigned_by, type, title, description, scheduled_time
    ) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [t.patientId, req.user.id, t.type, t.title, t.description, t.scheduledTime || null]
  );
  res.status(201).json(result.rows[0]);
});

tasksRouter.get("/", async (req, res) => {
  const result = await pool.query("SELECT * FROM tasks ORDER BY created_at DESC");
  res.json(result.rows);
});

tasksRouter.get("/patient/:id", async (req, res) => {
  const type = req.query.type;
  const params = [req.params.id];
  let sql = "SELECT * FROM tasks WHERE patient_id = $1";
  if (type) {
    params.push(type);
    sql += " AND type = $2";
  }
  sql += " ORDER BY scheduled_time NULLS LAST, created_at DESC";
  const result = await pool.query(sql, params);
  res.json(result.rows);
});

tasksRouter.put("/:id", async (req, res) => {
  const t = req.body;
  const result = await pool.query(
    `UPDATE tasks
     SET title = COALESCE($2, title),
         description = COALESCE($3, description),
         type = COALESCE($4, type),
         scheduled_time = COALESCE($5, scheduled_time),
         is_completed = COALESCE($6, is_completed),
         completed_at = CASE WHEN $6 = true THEN NOW() ELSE completed_at END
     WHERE id = $1
     RETURNING *`,
    [req.params.id, t.title, t.description, t.type, t.scheduledTime, t.isCompleted]
  );
  res.json(result.rows[0] || null);
});

tasksRouter.delete("/:id", async (req, res) => {
  await pool.query("DELETE FROM tasks WHERE id = $1", [req.params.id]);
  res.status(204).send();
});
