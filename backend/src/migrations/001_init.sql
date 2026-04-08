CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(20) CHECK (role IN ('nurse', 'patient')) NOT NULL,
    profile_image_url TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS patient_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    diagnosis TEXT,
    transplant_date DATE,
    is_active BOOLEAN DEFAULT true,
    nurse_id UUID REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS care_modules (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS patient_modules (
    patient_id UUID REFERENCES patient_profiles(id),
    module_id INTEGER REFERENCES care_modules(id),
    is_enabled BOOLEAN DEFAULT true,
    PRIMARY KEY (patient_id, module_id)
);

CREATE TABLE IF NOT EXISTS vital_signs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID REFERENCES patient_profiles(id),
    nurse_id UUID REFERENCES users(id),
    recorded_at TIMESTAMP DEFAULT NOW(),
    body_temperature DECIMAL(3,1),
    blood_pressure_systolic INT,
    blood_pressure_diastolic INT,
    heart_rate INT,
    oxygen_saturation INT,
    notes TEXT,
    shared_with_patient BOOLEAN DEFAULT false
);

CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID REFERENCES patient_profiles(id),
    assigned_by UUID REFERENCES users(id),
    type VARCHAR(30) CHECK (type IN ('medication', 'exercise', 'nutrition', 'wound_care')),
    title VARCHAR(255),
    description TEXT,
    scheduled_time TIMESTAMP,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ar_content (
    id SERIAL PRIMARY KEY,
    marker_image_url TEXT,
    model_url TEXT,
    animation_type VARCHAR(50),
    task_type VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS notifications_log (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    channel VARCHAR(20) CHECK (channel IN ('push', 'email')),
    sent_at TIMESTAMP DEFAULT NOW(),
    content TEXT
);
