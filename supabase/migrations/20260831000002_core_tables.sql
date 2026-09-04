-- ============================================================================
-- FitTrainer (myPT) — Migration 002: Core Application Tables
-- ============================================================================

-- Helper function for auto-updating timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1. USERS & IDENTITIES
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id UUID UNIQUE, -- Maps to Supabase auth.users(id)
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    role user_role_type NOT NULL DEFAULT 'CLIENT',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2. CLIENT HEALTH PROFILES & PRIVACY CONSENT
CREATE TABLE client_health_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    age INT CHECK (age >= 10 AND age <= 120),
    height_cm NUMERIC(5,2) CHECK (height_cm > 50 AND height_cm < 280),
    weight_kg NUMERIC(5,2) CHECK (weight_kg > 20 AND weight_kg < 400),
    fitness_goal TEXT,
    injuries TEXT,
    medical_info TEXT,
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(50),
    -- STRICT PRIVACY CONSENT FLAG (Default FALSE)
    share_personal_info_with_trainer BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_client_health_profiles_updated_at
BEFORE UPDATE ON client_health_profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 3. GYMS & ORGANIZATIONS
CREATE TABLE gyms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    location_address TEXT NOT NULL,
    contact_phone VARCHAR(50),
    contact_email VARCHAR(255),
    floor_capacity INT NOT NULL DEFAULT 40 CHECK (floor_capacity > 0),
    operating_hours TEXT NOT NULL DEFAULT '06:00 - 22:00 Daily',
    amenities TEXT[] DEFAULT ARRAY['Olympic Platforms', 'Sauna & Ice Bath', 'Turf Sprint Track'],
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_gyms_updated_at
BEFORE UPDATE ON gyms
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 4. TRAINER PROFILES
CREATE TABLE trainer_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trainer_code VARCHAR(20) UNIQUE NOT NULL,
    bio TEXT,
    years_experience INT NOT NULL DEFAULT 1 CHECK (years_experience >= 0),
    rating NUMERIC(3,2) NOT NULL DEFAULT 5.00 CHECK (rating >= 1.0 AND rating <= 5.0),
    review_count INT NOT NULL DEFAULT 0 CHECK (review_count >= 0),
    verification_status trainer_verification_status NOT NULL DEFAULT 'UNVERIFIED',
    is_independent BOOLEAN NOT NULL DEFAULT TRUE,
    hourly_rate NUMERIC(10,2) DEFAULT 60.00,
    trial_days_remaining INT DEFAULT 14,
    cancellation_policy cancellation_policy_type_enum NOT NULL DEFAULT 'FOUR_HOUR_STANDARD',
    cancellation_grace_hours INT NOT NULL DEFAULT 4 CHECK (cancellation_grace_hours >= 0),
    late_cancellation_penalty_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    late_cancellation_penalty_credits INT NOT NULL DEFAULT 1 CHECK (late_cancellation_penalty_credits >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_trainer_profiles_updated_at
BEFORE UPDATE ON trainer_profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 5. MULTI-GYM TRAINER ASSOCIATION (MEMBERSHIP MODEL)
CREATE TABLE gym_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_in_gym user_role_type NOT NULL DEFAULT 'TRAINER' CHECK (role_in_gym IN ('TRAINER', 'HEAD_TRAINER', 'GYM_MANAGER')),
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (gym_id, trainer_id)
);

-- 6. TRAINER ATTRIBUTES (Specializations, Certifications, Services, Hours)
CREATE TABLE trainer_specializations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    specialization VARCHAR(100) NOT NULL,
    UNIQUE (trainer_id, specialization)
);

CREATE TABLE trainer_certifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    issuing_organization VARCHAR(255),
    issue_year INT,
    certificate_url TEXT
);

CREATE TABLE trainer_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    service_name VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(10,2) NOT NULL,
    duration_minutes INT NOT NULL DEFAULT 60
);

CREATE TABLE trainer_working_hours (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    day_of_week INT NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6), -- 0=Sun, 6=Sat
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    slot_capacity INT NOT NULL DEFAULT 1 CHECK (slot_capacity >= 1),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CHECK (start_time < end_time)
);

-- 7. TRAINING PACKAGES (TEMPLATES)
CREATE TABLE packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    gym_id UUID REFERENCES gyms(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    sessions INT NOT NULL CHECK (sessions > 0),
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    currency VARCHAR(10) NOT NULL DEFAULT 'USD',
    validity_days INT NOT NULL DEFAULT 45 CHECK (validity_days > 0),
    validity_mode validity_mode_type NOT NULL DEFAULT 'CUSTOM_DAYS',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_packages_updated_at
BEFORE UPDATE ON packages
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 8. CLIENT-TRAINER RELATIONSHIPS
CREATE TABLE relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    gym_id UUID REFERENCES gyms(id) ON DELETE SET NULL,
    status relationship_status_type NOT NULL DEFAULT 'REQUESTED',
    approved_for_packages BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT,
    reassigned_from_trainer_id UUID REFERENCES users(id) ON DELETE SET NULL,
    reassigned_at TIMESTAMPTZ,
    reassignment_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (client_id, trainer_id)
);

CREATE TRIGGER trg_relationships_updated_at
BEFORE UPDATE ON relationships
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 9. CONSULTATION REQUESTS
CREATE TABLE consultation_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    goals TEXT NOT NULL,
    notes TEXT,
    status consultation_status_type NOT NULL DEFAULT 'REQUESTED',
    preferred_time VARCHAR(100),
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at TIMESTAMPTZ
);

-- 10. CLIENT PURCHASED PACKAGES
CREATE TABLE client_packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    package_id UUID NOT NULL REFERENCES packages(id) ON DELETE RESTRICT,
    total_sessions INT NOT NULL CHECK (total_sessions > 0),
    remaining_sessions INT NOT NULL DEFAULT 0 CHECK (remaining_sessions >= 0),
    price_paid NUMERIC(10,2) NOT NULL,
    status client_package_status_type NOT NULL DEFAULT 'PENDING_PAYMENT',
    activated_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_client_packages_updated_at
BEFORE UPDATE ON client_packages
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 11. PAYMENTS (OFFLINE & ONLINE)
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    package_id UUID NOT NULL REFERENCES packages(id) ON DELETE RESTRICT,
    client_package_id UUID REFERENCES client_packages(id) ON DELETE SET NULL,
    amount NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(10) NOT NULL DEFAULT 'USD',
    payment_method payment_method_type NOT NULL DEFAULT 'OFFLINE_MANUAL',
    transaction_ref VARCHAR(255) NOT NULL,
    status payment_status_type NOT NULL DEFAULT 'PENDING_VERIFICATION',
    receipt_url TEXT,
    notes TEXT,
    verified_at TIMESTAMPTZ,
    verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_payments_updated_at
BEFORE UPDATE ON payments
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 12. IMMUTABLE APPEND-ONLY CREDIT LEDGER
CREATE TABLE credit_ledger_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_package_id UUID NOT NULL REFERENCES client_packages(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id UUID, -- References sessions(id) added via FK later
    transaction_type credit_transaction_type NOT NULL,
    delta_credits INT NOT NULL, -- e.g., +10, -1, 0
    balance_after INT NOT NULL CHECK (balance_after >= 0),
    reason TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 13. SESSIONS & BOOKINGS
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trainer_id UUID REFERENCES users(id) ON DELETE SET NULL,
    gym_id UUID REFERENCES gyms(id) ON DELETE SET NULL,
    client_package_id UUID REFERENCES client_packages(id) ON DELETE SET NULL,
    session_type session_classification_type NOT NULL DEFAULT 'PERSONAL_TRAINING',
    status session_status_type NOT NULL DEFAULT 'REQUESTED',
    scheduled_start TIMESTAMPTZ NOT NULL,
    scheduled_end TIMESTAMPTZ NOT NULL,
    actual_start TIMESTAMPTZ,
    actual_end TIMESTAMPTZ,
    credit_consumed BOOLEAN NOT NULL DEFAULT FALSE,
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    recurrence_rule TEXT, -- e.g. "FREQ=WEEKLY;COUNT=4"
    notes TEXT,
    cancellation_reason TEXT,
    cancelled_by UUID REFERENCES users(id) ON DELETE SET NULL,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (scheduled_start < scheduled_end)
);

CREATE TRIGGER trg_sessions_updated_at
BEFORE UPDATE ON sessions
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Add deferred FK from credit ledger to sessions
ALTER TABLE credit_ledger_transactions
ADD CONSTRAINT fk_credit_ledger_session
FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE SET NULL;

-- 14. EXERCISE LIBRARY (12 CATEGORIES + CUSTOM)
CREATE TABLE exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    category exercise_category_type NOT NULL,
    equipment VARCHAR(100) NOT NULL DEFAULT 'Bodyweight',
    target_muscles TEXT NOT NULL,
    description TEXT,
    is_custom BOOLEAN NOT NULL DEFAULT FALSE,
    trainer_id UUID REFERENCES users(id) ON DELETE CASCADE, -- NULL for global exercises
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 15. WORKOUT TEMPLATES
CREATE TABLE workout_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_workout_templates_updated_at
BEFORE UPDATE ON workout_templates
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 16. WORKOUTS (PT & OWN WORKOUTS)
CREATE TABLE workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trainer_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    template_id UUID REFERENCES workout_templates(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    workout_type session_classification_type NOT NULL DEFAULT 'PERSONAL_TRAINING',
    assigned_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'SCHEDULED',
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_workouts_updated_at
BEFORE UPDATE ON workouts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE workout_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE RESTRICT,
    sort_order INT NOT NULL DEFAULT 0,
    notes TEXT
);

CREATE TABLE workout_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_exercise_id UUID NOT NULL REFERENCES workout_exercises(id) ON DELETE CASCADE,
    set_number INT NOT NULL,
    repetitions INT NOT NULL DEFAULT 10 CHECK (repetitions >= 0),
    weight_kg NUMERIC(6,2) NOT NULL DEFAULT 0 CHECK (weight_kg >= 0),
    rpe NUMERIC(3,1) CHECK (rpe >= 1.0 AND rpe <= 10.0),
    is_completed BOOLEAN NOT NULL DEFAULT FALSE
);

-- 17. PROGRESS MEASUREMENTS (8-POINT SCAN + GENERATED BMI)
CREATE TABLE progress_measurements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    logged_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    weight_kg NUMERIC(5,2) NOT NULL CHECK (weight_kg > 20 AND weight_kg < 400),
    height_cm NUMERIC(5,2) NOT NULL CHECK (height_cm > 50 AND height_cm < 280),
    -- GENERATED STORED BMI COLUMN
    bmi NUMERIC(4,1) GENERATED ALWAYS AS (ROUND((weight_kg / ((height_cm / 100.0) * (height_cm / 100.0))), 1)) STORED,
    body_fat_percentage NUMERIC(4,1) CHECK (body_fat_percentage >= 3.0 AND body_fat_percentage <= 60.0),
    chest_cm NUMERIC(5,1),
    waist_cm NUMERIC(5,1),
    hips_cm NUMERIC(5,1),
    biceps_cm NUMERIC(5,1),
    thighs_cm NUMERIC(5,1),
    calves_cm NUMERIC(5,1),
    notes TEXT,
    source VARCHAR(20) NOT NULL DEFAULT 'CLIENT', -- 'CLIENT' or 'TRAINER'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE progress_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    measurement_id UUID NOT NULL REFERENCES progress_measurements(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pose_type VARCHAR(20) NOT NULL CHECK (pose_type IN ('FRONT', 'SIDE', 'BACK')),
    storage_path TEXT NOT NULL,
    is_private BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 18. REVIEWS
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT NOT NULL,
    is_visible BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (trainer_id, client_id)
);

-- 19. NOTIFICATIONS
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type notification_type_enum NOT NULL DEFAULT 'SYSTEM',
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    reference_id UUID,
    reference_type VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 20. RUNTIME FEATURE FLAGS
CREATE TABLE feature_flags (
    key VARCHAR(100) PRIMARY KEY,
    description TEXT NOT NULL,
    is_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL
);

-- 21. PERFORMANCE INDEXES
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_auth_id ON users(auth_id);
CREATE INDEX idx_trainer_profiles_code ON trainer_profiles(trainer_code);
CREATE INDEX idx_trainer_profiles_verification ON trainer_profiles(verification_status);
CREATE INDEX idx_gym_memberships_gym ON gym_memberships(gym_id);
CREATE INDEX idx_gym_memberships_trainer ON gym_memberships(trainer_id);
CREATE INDEX idx_relationships_client ON relationships(client_id);
CREATE INDEX idx_relationships_trainer ON relationships(trainer_id);
CREATE INDEX idx_relationships_status ON relationships(status);
CREATE INDEX idx_client_packages_client ON client_packages(client_id);
CREATE INDEX idx_client_packages_status ON client_packages(status);
CREATE INDEX idx_payments_trainer ON payments(trainer_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_credit_ledger_pkg ON credit_ledger_transactions(client_package_id);
CREATE INDEX idx_credit_ledger_client ON credit_ledger_transactions(client_id);
CREATE INDEX idx_sessions_client ON sessions(client_id);
CREATE INDEX idx_sessions_trainer ON sessions(trainer_id);
CREATE INDEX idx_sessions_scheduled ON sessions(scheduled_start, scheduled_end);
CREATE INDEX idx_sessions_status ON sessions(status);
CREATE INDEX idx_workouts_client ON workouts(client_id);
CREATE INDEX idx_progress_measurements_client ON progress_measurements(client_id, date DESC);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read);
