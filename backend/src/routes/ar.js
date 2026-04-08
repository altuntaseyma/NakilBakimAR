import { Router } from "express";
import { pool } from "../db/pool.js";
import { authRequired } from "../middleware/auth.js";

export const arRouter = Router();
arRouter.use(authRequired);

arRouter.get("/marker/:markerId", async (req, res) => {
  const result = await pool.query(
    "SELECT * FROM ar_content WHERE marker_image_url = $1 LIMIT 1",
    [req.params.markerId]
  );
  if (!result.rows[0]) return res.status(404).json({ message: "AR content not found" });
  res.json(result.rows[0]);
});
