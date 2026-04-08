import bcrypt from "bcryptjs";
import { pool } from "../db/pool.js";

const passwordHash = await bcrypt.hash("123456", 10);

try {
  await pool.query(
    `INSERT INTO care_modules (name)
     VALUES ('mobilization'), ('nutrition'), ('wound_care'), ('medication'), ('vital_signs')
     ON CONFLICT (name) DO NOTHING`
  );

  const nurse = await pool.query(
    `INSERT INTO users (email, password_hash, full_name, role)
     VALUES ($1,$2,$3,'nurse')
     ON CONFLICT (email) DO UPDATE SET full_name = EXCLUDED.full_name
     RETURNING id`,
    ["nurse@nakil.com", passwordHash, "Demo Nurse"]
  );

  for (let i = 1; i <= 9; i += 1) {
    const patient = await pool.query(
      `INSERT INTO users (email, password_hash, full_name, role)
       VALUES ($1,$2,$3,'patient')
       ON CONFLICT (email) DO UPDATE SET full_name = EXCLUDED.full_name
       RETURNING id`,
      [`patient${i}@nakil.com`, passwordHash, `Demo Patient ${i}`]
    );

    await pool.query(
      `INSERT INTO patient_profiles (user_id, diagnosis, nurse_id, transplant_date)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT DO NOTHING`,
      [
        patient.rows[0].id,
        i % 2 === 0 ? "Post-op follow-up" : "Pre-op evaluation",
        nurse.rows[0].id,
        i % 2 === 0 ? "2026-01-15" : null
      ]
    );
  }

  await pool.query(
    `INSERT INTO ar_content (marker_image_url, model_url, animation_type, task_type)
     VALUES ('marker_mobilization_v1', 'https://example.com/models/walk.usdz', 'pose', 'exercise')
     ON CONFLICT DO NOTHING`
  );

  console.log("Seed complete.");
} finally {
  await pool.end();
}
