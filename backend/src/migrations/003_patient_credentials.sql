ALTER TABLE users
  ADD COLUMN IF NOT EXISTS patient_tc VARCHAR(11),
  ADD COLUMN IF NOT EXISTS patient_pin_hash TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS users_patient_tc_unique_idx
  ON users (patient_tc)
  WHERE patient_tc IS NOT NULL;
