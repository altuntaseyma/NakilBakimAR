import bcrypt from "bcryptjs";
import { pool } from "../db/pool.js";

const passwordHash = await bcrypt.hash("123456", 10);

function generateValidTc(seed) {
  const baseNine = String(100000000 + seed).padStart(9, "0");
  const digits = baseNine.split("").map(Number);
  const oddSum = digits[0] + digits[2] + digits[4] + digits[6] + digits[8];
  const evenSum = digits[1] + digits[3] + digits[5] + digits[7];
  const digit10 = ((oddSum * 7) - evenSum) % 10;
  // digit11: ilk 10 hane (9 baz + digit10) toplamının mod 10'u
  const allTen = [...digits, digit10];
  const digit11 = allTen.reduce((sum, n) => sum + n, 0) % 10;
  return `${baseNine}${digit10}${digit11}`;
}

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
    const patientTc = generateValidTc(i);
    const patientPin = `10${String(i).padStart(2, "0")}`;
    const patientPinHash = await bcrypt.hash(patientPin, 10);
    const patient = await pool.query(
      `INSERT INTO users (email, password_hash, full_name, role, patient_tc, patient_pin_hash)
       VALUES ($1,$2,$3,'patient',$4,$5)
       ON CONFLICT (email) DO UPDATE SET
         full_name = EXCLUDED.full_name,
         patient_tc = EXCLUDED.patient_tc,
         patient_pin_hash = EXCLUDED.patient_pin_hash
       RETURNING id`,
      [`patient${i}@nakil.com`, passwordHash, `Demo Patient ${i}`, patientTc, patientPinHash]
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
