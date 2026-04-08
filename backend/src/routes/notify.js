import { Router } from "express";
import nodemailer from "nodemailer";
import { pool } from "../db/pool.js";
import { authRequired } from "../middleware/auth.js";

export const notifyRouter = Router();
notifyRouter.use(authRequired);

notifyRouter.post("/task/:taskId", async (req, res) => {
  if (req.user.role !== "nurse") return res.status(403).json({ message: "Forbidden" });

  const taskResult = await pool.query(
    `SELECT t.*, u.email
     FROM tasks t
     JOIN patient_profiles pp ON pp.id = t.patient_id
     JOIN users u ON u.id = pp.user_id
     WHERE t.id = $1`,
    [req.params.taskId]
  );
  const task = taskResult.rows[0];
  if (!task) return res.status(404).json({ message: "Task not found" });

  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: false,
    auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
  });

  await transporter.sendMail({
    from: process.env.SMTP_FROM,
    to: task.email,
    subject: "NakilBakimAR - Gorev Hatirlatmasi",
    text: `${task.title} gorevi icin hatirlatici.`
  });

  await pool.query(
    "INSERT INTO notifications_log (user_id, channel, content) VALUES ($1, $2, $3)",
    [task.patient_id, "email", `${task.title} hatirlatmasi gonderildi`]
  );

  res.json({ success: true, push: "FCM TODO", email: "sent" });
});
