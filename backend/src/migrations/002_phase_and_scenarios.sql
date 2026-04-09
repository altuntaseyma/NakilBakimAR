ALTER TABLE patient_profiles
  ALTER COLUMN transplant_date TYPE TIMESTAMP USING transplant_date::timestamp;

CREATE TABLE IF NOT EXISTS scenario_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID REFERENCES patient_profiles(id) ON DELETE CASCADE,
  scenario_key VARCHAR(50) NOT NULL,
  decision_key VARCHAR(100),
  selected_option VARCHAR(50),
  was_correct BOOLEAN,
  module_duration_sec INT,
  created_at TIMESTAMP DEFAULT NOW()
);
