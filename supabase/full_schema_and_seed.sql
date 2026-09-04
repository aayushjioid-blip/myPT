-- ============================================================================
-- FitTrainer (myPT) — Complete Consolidated Database Schema & Seed Data
-- Version: 2.0 Production DDL
-- For 1-Click Execution in Supabase Dashboard SQL Editor
-- ============================================================================

-- ============================================================================
-- 1. EXTENSIONS & CUSTOM ENUM TYPES
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

DO $$ BEGIN
    CREATE TYPE user_role_type AS ENUM ('CLIENT', 'TRAINER', 'HEAD_TRAINER', 'GYM_MANAGER', 'SUPER_ADMIN');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE trainer_verification_status AS ENUM ('UNVERIFIED', 'PENDING', 'VERIFIED', 'REJECTED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE relationship_status_type AS ENUM ('REQUESTED', 'ACCEPTED', 'APPROVED_FOR_PURCHASE', 'ACTIVE', 'INACTIVE', 'REASSIGNED', 'TERMINATED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE consultation_status_type AS ENUM ('REQUESTED', 'ACCEPTED', 'DECLINED', 'COMPLETED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE validity_mode_type AS ENUM ('FIXED_WEEKS', 'MONTHLY', 'CUSTOM_DAYS');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE client_package_status_type AS ENUM ('PENDING_PAYMENT', 'ACTIVE', 'EXPIRED', 'EXHAUSTED', 'TRANSFERRED', 'CANCELLED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE payment_status_type AS ENUM ('PENDING_VERIFICATION', 'VERIFIED', 'REJECTED', 'REFUNDED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE payment_method_type AS ENUM ('OFFLINE_MANUAL', 'UPI_QR', 'CASH', 'ONLINE_GATEWAY');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE credit_transaction_type AS ENUM ('PACKAGE_ACTIVATION', 'SESSION_COMPLETION', 'CANCELLATION_PENALTY', 'MANUAL_ADJUSTMENT', 'PACKAGE_EXPIRY', 'CLIENT_TRANSFER', 'REFUND');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE session_status_type AS ENUM ('REQUESTED', 'CONFIRMED', 'DECLINED', 'CANCELLED', 'RESCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'NO_SHOW');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE session_classification_type AS ENUM ('PERSONAL_TRAINING', 'OWN_WORKOUT', 'GROUP_TRAINING');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE exercise_category_type AS ENUM ('CHEST', 'BACK', 'LEGS', 'SHOULDERS', 'BICEPS', 'TRICEPS', 'FOREARMS', 'GLUTES', 'HIPS', 'CORE', 'CALVES', 'FULL_BODY');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE notification_type_enum AS ENUM ('BOOKING', 'PAYMENT', 'WORKOUT', 'CONSULTATION', 'REASSIGNMENT', 'LOW_CREDIT', 'WARNING', 'SYSTEM');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE cancellation_policy_type_enum AS ENUM ('FOUR_HOUR_STANDARD', 'TWENTY_FOUR_HOUR_STRICT', 'CUSTOM_WINDOW', 'NO_PENALTY');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Helper trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 2. CORE APPLICATION TABLES
-- ============================================================================

-- 1. Users
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id UUID UNIQUE,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    role user_role_type NOT NULL DEFAULT 'CLIENT',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Client Health Profiles
CREATE TABLE IF NOT EXISTS client_health_profiles (
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
    share_personal_info_with_trainer BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Gyms
CREATE TABLE IF NOT EXISTS gyms (
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

-- 4. Trainer Profiles
CREATE TABLE IF NOT EXISTS trainer_profiles (
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

-- 5. Gym Memberships
CREATE TABLE IF NOT EXISTS gym_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_in_gym user_role_type NOT NULL DEFAULT 'TRAINER' CHECK (role_in_gym IN ('TRAINER', 'HEAD_TRAINER', 'GYM_MANAGER')),
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (gym_id, trainer_id)
);

-- 6. Trainer Sub-tables
CREATE TABLE IF NOT EXISTS trainer_specializations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    specialization VARCHAR(100) NOT NULL,
    UNIQUE (trainer_id, specialization)
);

CREATE TABLE IF NOT EXISTS trainer_certifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    issuing_organization VARCHAR(255),
    issue_year INT,
    certificate_url TEXT
);

CREATE TABLE IF NOT EXISTS trainer_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    service_name VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(10,2) NOT NULL,
    duration_minutes INT NOT NULL DEFAULT 60
);

CREATE TABLE IF NOT EXISTS trainer_working_hours (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    day_of_week INT NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    slot_capacity INT NOT NULL DEFAULT 1 CHECK (slot_capacity >= 1),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CHECK (start_time < end_time)
);

-- 7. Packages
CREATE TABLE IF NOT EXISTS packages (
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

-- 8. Relationships
CREATE TABLE IF NOT EXISTS relationships (
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

-- 9. Consultation Requests
CREATE TABLE IF NOT EXISTS consultation_requests (
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

-- 10. Client Packages
CREATE TABLE IF NOT EXISTS client_packages (
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

-- 11. Payments
CREATE TABLE IF NOT EXISTS payments (
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

-- 12. Credit Ledger (Append-Only)
CREATE TABLE IF NOT EXISTS credit_ledger_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_package_id UUID NOT NULL REFERENCES client_packages(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id UUID,
    transaction_type credit_transaction_type NOT NULL,
    delta_credits INT NOT NULL,
    balance_after INT NOT NULL CHECK (balance_after >= 0),
    reason TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 13. Sessions
CREATE TABLE IF NOT EXISTS sessions (
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
    recurrence_rule TEXT,
    notes TEXT,
    cancellation_reason TEXT,
    cancelled_by UUID REFERENCES users(id) ON DELETE SET NULL,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (scheduled_start < scheduled_end)
);

-- 14. Exercises
CREATE TABLE IF NOT EXISTS exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    category exercise_category_type NOT NULL,
    equipment VARCHAR(100) NOT NULL DEFAULT 'Bodyweight',
    target_muscles TEXT NOT NULL,
    description TEXT,
    is_custom BOOLEAN NOT NULL DEFAULT FALSE,
    trainer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 15. Workout Templates
CREATE TABLE IF NOT EXISTS workout_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 16. Workouts & Sets
CREATE TABLE IF NOT EXISTS workouts (
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

CREATE TABLE IF NOT EXISTS workout_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE RESTRICT,
    sort_order INT NOT NULL DEFAULT 0,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS workout_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_exercise_id UUID NOT NULL REFERENCES workout_exercises(id) ON DELETE CASCADE,
    set_number INT NOT NULL,
    repetitions INT NOT NULL DEFAULT 10 CHECK (repetitions >= 0),
    weight_kg NUMERIC(6,2) NOT NULL DEFAULT 0 CHECK (weight_kg >= 0),
    rpe NUMERIC(3,1) CHECK (rpe >= 1.0 AND rpe <= 10.0),
    is_completed BOOLEAN NOT NULL DEFAULT FALSE
);

-- 17. Progress Measurements (with Auto-Generated BMI)
CREATE TABLE IF NOT EXISTS progress_measurements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    logged_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    weight_kg NUMERIC(5,2) NOT NULL CHECK (weight_kg > 20 AND weight_kg < 400),
    height_cm NUMERIC(5,2) NOT NULL CHECK (height_cm > 50 AND height_cm < 280),
    bmi NUMERIC(4,1) GENERATED ALWAYS AS (ROUND((weight_kg / ((height_cm / 100.0) * (height_cm / 100.0))), 1)) STORED,
    body_fat_percentage NUMERIC(4,1) CHECK (body_fat_percentage >= 3.0 AND body_fat_percentage <= 60.0),
    chest_cm NUMERIC(5,1),
    waist_cm NUMERIC(5,1),
    hips_cm NUMERIC(5,1),
    biceps_cm NUMERIC(5,1),
    thighs_cm NUMERIC(5,1),
    calves_cm NUMERIC(5,1),
    notes TEXT,
    source VARCHAR(20) NOT NULL DEFAULT 'CLIENT',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS progress_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    measurement_id UUID NOT NULL REFERENCES progress_measurements(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pose_type VARCHAR(20) NOT NULL CHECK (pose_type IN ('FRONT', 'SIDE', 'BACK')),
    storage_path TEXT NOT NULL,
    is_private BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 18. Reviews
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT NOT NULL,
    is_visible BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (trainer_id, client_id)
);

-- 19. Notifications
CREATE TABLE IF NOT EXISTS notifications (
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

-- 20. Feature Flags
CREATE TABLE IF NOT EXISTS feature_flags (
    key VARCHAR(100) PRIMARY KEY,
    description TEXT NOT NULL,
    is_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL
);

-- ============================================================================
-- 3. STORED PROCEDURES (RPCs)
-- ============================================================================

CREATE OR REPLACE FUNCTION verify_and_activate_package_payment(p_payment_id UUID, p_verified_by UUID)
RETURNS JSONB AS $$
DECLARE
    v_payment RECORD;
    v_package RECORD;
    v_client_package_id UUID;
    v_new_balance INT;
BEGIN
    SELECT * INTO v_payment FROM payments WHERE id = p_payment_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Payment % not found', p_payment_id; END IF;
    IF v_payment.status = 'VERIFIED' THEN RETURN jsonb_build_object('success', true, 'message', 'Payment already verified'); END IF;

    SELECT * INTO v_package FROM packages WHERE id = v_payment.package_id;

    IF v_payment.client_package_id IS NOT NULL THEN
        UPDATE client_packages
        SET status = 'ACTIVE',
            total_sessions = v_package.sessions,
            remaining_sessions = v_package.sessions,
            activated_at = NOW(),
            expires_at = NOW() + (v_package.validity_days || ' days')::INTERVAL,
            updated_at = NOW()
        WHERE id = v_payment.client_package_id
        RETURNING id, remaining_sessions INTO v_client_package_id, v_new_balance;
    ELSE
        INSERT INTO client_packages (
            client_id, trainer_id, package_id, total_sessions, remaining_sessions, price_paid, status, activated_at, expires_at
        ) VALUES (
            v_payment.client_id, v_payment.trainer_id, v_payment.package_id, v_package.sessions, v_package.sessions, v_payment.amount, 'ACTIVE', NOW(), NOW() + (v_package.validity_days || ' days')::INTERVAL
        ) RETURNING id, remaining_sessions INTO v_client_package_id, v_new_balance;

        UPDATE payments SET client_package_id = v_client_package_id WHERE id = p_payment_id;
    END IF;

    INSERT INTO credit_ledger_transactions (
        client_package_id, client_id, trainer_id, transaction_type, delta_credits, balance_after, reason, created_by
    ) VALUES (
        v_client_package_id, v_payment.client_id, v_payment.trainer_id, 'PACKAGE_ACTIVATION', v_package.sessions, v_new_balance, 'Payment verified: ' || v_package.name || ' (+' || v_package.sessions || ' credits)', p_verified_by
    );

    UPDATE payments SET status = 'VERIFIED', verified_at = NOW(), verified_by = p_verified_by, updated_at = NOW() WHERE id = p_payment_id;

    INSERT INTO notifications (user_id, title, message, type, reference_id, reference_type)
    VALUES (v_payment.client_id, 'Payment Verified & Package Activated! 🎉', 'Your payment has been verified. ' || v_package.sessions || ' PT sessions are now active.', 'PAYMENT', v_client_package_id, 'CLIENT_PACKAGE');

    RETURN jsonb_build_object('success', true, 'client_package_id', v_client_package_id, 'activated_credits', v_package.sessions, 'balance', v_new_balance);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION complete_pt_session(p_session_id UUID, p_completed_by UUID)
RETURNS JSONB AS $$
DECLARE
    v_session RECORD;
    v_client_pkg RECORD;
    v_new_balance INT;
BEGIN
    SELECT * INTO v_session FROM sessions WHERE id = p_session_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Session % not found', p_session_id; END IF;

    IF v_session.credit_consumed = TRUE OR v_session.status = 'COMPLETED' THEN
        RETURN jsonb_build_object('success', true, 'message', 'Session already completed.', 'credit_deducted', 0);
    END IF;

    IF v_session.session_type = 'OWN_WORKOUT' THEN
        UPDATE sessions SET status = 'COMPLETED', actual_end = NOW(), credit_consumed = FALSE, updated_at = NOW() WHERE id = p_session_id;
        RETURN jsonb_build_object('success', true, 'message', 'Own Workout completed with 0 PT credits consumed.', 'credit_deducted', 0);
    END IF;

    IF v_session.client_package_id IS NULL THEN
        SELECT * INTO v_client_pkg FROM client_packages WHERE client_id = v_session.client_id AND status = 'ACTIVE' AND remaining_sessions > 0 ORDER BY activated_at DESC LIMIT 1 FOR UPDATE;
    ELSE
        SELECT * INTO v_client_pkg FROM client_packages WHERE id = v_session.client_package_id FOR UPDATE;
    END IF;

    IF v_client_pkg IS NULL OR v_client_pkg.remaining_sessions < 1 THEN
        RAISE EXCEPTION 'Client % has no available active PT session credits!', v_session.client_id;
    END IF;

    v_new_balance := v_client_pkg.remaining_sessions - 1;

    UPDATE client_packages
    SET remaining_sessions = v_new_balance,
        status = CASE WHEN v_new_balance = 0 THEN 'EXHAUSTED'::client_package_status_type ELSE 'ACTIVE'::client_package_status_type END,
        updated_at = NOW()
    WHERE id = v_client_pkg.id;

    INSERT INTO credit_ledger_transactions (
        client_package_id, client_id, trainer_id, session_id, transaction_type, delta_credits, balance_after, reason, created_by
    ) VALUES (
        v_client_pkg.id, v_session.client_id, v_session.trainer_id, p_session_id, 'SESSION_COMPLETION', -1, v_new_balance, 'Completed 1-on-1 PT session', p_completed_by
    );

    UPDATE sessions SET status = 'COMPLETED', credit_consumed = TRUE, actual_end = NOW(), updated_at = NOW() WHERE id = p_session_id;

    IF v_new_balance <= 2 THEN
        INSERT INTO notifications (user_id, title, message, type, reference_id, reference_type)
        VALUES (v_session.client_id, 'Low PT Credits Warning ⚠️', 'You have ' || v_new_balance || ' PT session(s) remaining.', 'LOW_CREDIT', v_client_pkg.id, 'CLIENT_PACKAGE');
    END IF;

    RETURN jsonb_build_object('success', true, 'session_id', p_session_id, 'credit_deducted', 1, 'balance_after', v_new_balance);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION apply_cancellation_policy(p_session_id UUID, p_cancelled_by UUID, p_reason TEXT DEFAULT 'Cancelled by participant')
RETURNS JSONB AS $$
DECLARE
    v_session RECORD;
    v_trainer RECORD;
    v_client_pkg RECORD;
    v_hours_until_start NUMERIC;
    v_penalty_applied BOOLEAN := FALSE;
    v_new_balance INT;
BEGIN
    SELECT * INTO v_session FROM sessions WHERE id = p_session_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Session % not found', p_session_id; END IF;

    SELECT * INTO v_trainer FROM trainer_profiles WHERE user_id = v_session.trainer_id;

    v_hours_until_start := EXTRACT(EPOCH FROM (v_session.scheduled_start - NOW())) / 3600.0;

    IF p_cancelled_by = v_session.trainer_id THEN
        v_penalty_applied := FALSE;
    ELSIF v_hours_until_start < COALESCE(v_trainer.cancellation_grace_hours, 4) AND COALESCE(v_trainer.late_cancellation_penalty_enabled, TRUE) THEN
        v_penalty_applied := TRUE;
    ELSE
        v_penalty_applied := FALSE;
    END IF;

    IF v_penalty_applied AND v_session.client_package_id IS NOT NULL THEN
        SELECT * INTO v_client_pkg FROM client_packages WHERE id = v_session.client_package_id FOR UPDATE;
        IF v_client_pkg.remaining_sessions > 0 THEN
            v_new_balance := v_client_pkg.remaining_sessions - COALESCE(v_trainer.late_cancellation_penalty_credits, 1);
            IF v_new_balance < 0 THEN v_new_balance := 0; END IF;

            UPDATE client_packages SET remaining_sessions = v_new_balance, updated_at = NOW() WHERE id = v_client_pkg.id;

            INSERT INTO credit_ledger_transactions (
                client_package_id, client_id, trainer_id, session_id, transaction_type, delta_credits, balance_after, reason, created_by
            ) VALUES (
                v_client_pkg.id, v_session.client_id, v_session.trainer_id, p_session_id, 'CANCELLATION_PENALTY', -COALESCE(v_trainer.late_cancellation_penalty_credits, 1), v_new_balance, 'Late cancellation penalty (< 4h window)', p_cancelled_by
            );
        END IF;
    END IF;

    UPDATE sessions SET status = 'CANCELLED', cancellation_reason = p_reason, cancelled_by = p_cancelled_by, cancelled_at = NOW(), updated_at = NOW() WHERE id = p_session_id;

    RETURN jsonb_build_object('success', true, 'penalty_applied', v_penalty_applied, 'hours_before_start', v_hours_until_start, 'new_balance', v_new_balance);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION reassign_client(p_relationship_id UUID, p_from_trainer_id UUID, p_to_trainer_id UUID, p_reason TEXT, p_reassigned_by UUID)
RETURNS JSONB AS $$
DECLARE
    v_rel RECORD;
BEGIN
    SELECT * INTO v_rel FROM relationships WHERE id = p_relationship_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Relationship % not found', p_relationship_id; END IF;

    UPDATE relationships
    SET trainer_id = p_to_trainer_id, reassigned_from_trainer_id = p_from_trainer_id, reassigned_at = NOW(), reassignment_reason = p_reason, status = 'REASSIGNED', updated_at = NOW()
    WHERE id = p_relationship_id;

    UPDATE client_packages SET trainer_id = p_to_trainer_id, updated_at = NOW() WHERE client_id = v_rel.client_id AND trainer_id = p_from_trainer_id;

    INSERT INTO credit_ledger_transactions (client_package_id, client_id, trainer_id, transaction_type, delta_credits, balance_after, reason, created_by)
    SELECT id, client_id, p_to_trainer_id, 'CLIENT_TRANSFER', 0, remaining_sessions, 'Coach reassigned. History & credits preserved.', p_reassigned_by
    FROM client_packages WHERE client_id = v_rel.client_id AND status = 'ACTIVE';

    INSERT INTO notifications (user_id, title, message, type)
    VALUES (v_rel.client_id, 'Coach Reassignment Notice 🔄', 'You have been transitioned to your new coach. All your active package credits, workout history, and progress logs are preserved.', 'REASSIGNMENT');

    RETURN jsonb_build_object('success', true, 'client_id', v_rel.client_id, 'new_trainer_id', p_to_trainer_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 4. SEED DATA (5 PERSONAS, GYM, EXERCISES, PACKAGES, FLAGS)
-- ============================================================================

INSERT INTO feature_flags (key, description, is_enabled) VALUES
('advanced_trainer_search', 'Enables multi-parameter filters in Client Discovery (Default: FALSE)', FALSE),
('client_personal_information', 'Enables medical/injury intake collection (Default: TRUE)', TRUE),
('online_payments', 'Enables mock online payment gateway vs offline UPI (Default: FALSE)', FALSE),
('trainer_reviews', 'Enables 1-5 star review submission on trainer profiles (Default: TRUE)', TRUE),
('client_upcoming_workout_visibility', 'Displays tomorrow scheduled workout on client hub (Default: TRUE)', TRUE)
ON CONFLICT (key) DO UPDATE SET is_enabled = EXCLUDED.is_enabled;

INSERT INTO users (id, email, phone, name, avatar_url, role, is_active) VALUES
('00000000-0000-0000-0000-000000000001', 'sarah.jenkins@fitapp.dev', '+1555123456', 'Sarah Jenkins', '👩', 'CLIENT', TRUE),
('00000000-0000-0000-0000-000000000002', 'alex.rivera@fitapp.dev', '+1555234567', 'Alex Rivera', '🏋️', 'TRAINER', TRUE),
('00000000-0000-0000-0000-000000000003', 'maya.lin@fitapp.dev', '+1555345678', 'Maya Lin', '🧘', 'TRAINER', TRUE),
('00000000-0000-0000-0000-000000000004', 'leo.novak@fitapp.dev', '+1555456789', 'Leo Novak', '🥊', 'TRAINER', TRUE),
('00000000-0000-0000-0000-000000000005', 'marcus.vance@fitapp.dev', '+1555567890', 'Marcus Vance', '👑', 'HEAD_TRAINER', TRUE),
('00000000-0000-0000-0000-000000000006', 'elena.rostova@fitapp.dev', '+1555678901', 'Elena Rostova', '🏢', 'GYM_MANAGER', TRUE),
('00000000-0000-0000-0000-000000000007', 'admin@fitapp.dev', '+1555789012', 'Demo Super Admin', '🛡️', 'SUPER_ADMIN', TRUE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO client_health_profiles (user_id, age, height_cm, weight_kg, fitness_goal, injuries, medical_info, share_personal_info_with_trainer)
VALUES ('00000000-0000-0000-0000-000000000001', 28, 168.0, 64.5, 'Fat Loss & Hypertrophy', 'Mild left shoulder impingement on overhead presses', 'Asthma', FALSE)
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO gyms (id, name, slug, description, location_address, contact_phone, contact_email, floor_capacity, operating_hours)
VALUES ('10000000-0000-0000-0000-000000000001', 'IronCore Fitness Center', 'ironcore-metro', 'Premier strength and conditioning facility.', '742 Evergreen Blvd, Metro City', '+1-555-IRON-CORE', 'contact@ironcore.fit', 40, '06:00 - 22:00 Daily')
ON CONFLICT (id) DO NOTHING;

INSERT INTO trainer_profiles (user_id, trainer_code, bio, years_experience, rating, review_count, verification_status, is_independent, hourly_rate)
VALUES
('00000000-0000-0000-0000-000000000002', 'TRN001', 'NASM Master Trainer specializing in biomechanics & hypertrophy.', 8, 4.90, 24, 'VERIFIED', FALSE, 75.00),
('00000000-0000-0000-0000-000000000003', 'MAYA02', 'ACE Certified & Yoga Alliance RYT-500. Functional movement patterns & mobility.', 6, 4.95, 19, 'VERIFIED', FALSE, 65.00),
('00000000-0000-0000-0000-000000000004', 'LEO007', 'Boxing coach and high-intensity interval conditioning specialist.', 3, 4.70, 5, 'UNVERIFIED', TRUE, 50.00),
('00000000-0000-0000-0000-000000000005', 'HEAD01', 'Director of Performance & Head Coach at IronCore Fitness.', 12, 5.00, 48, 'VERIFIED', FALSE, 100.00)
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO gym_memberships (gym_id, trainer_id, role_in_gym, is_primary) VALUES
('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000006', 'GYM_MANAGER', TRUE),
('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000005', 'HEAD_TRAINER', TRUE),
('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'TRAINER', TRUE),
('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000003', 'TRAINER', TRUE)
ON CONFLICT (gym_id, trainer_id) DO NOTHING;

INSERT INTO exercises (id, name, category, equipment, target_muscles, description, is_custom) VALUES
('20000000-0000-0000-0000-000000000001', 'Barbell Flat Bench Press', 'CHEST', 'Barbell + Bench', 'Pectoralis Major, Triceps', 'Retract scapulae and press with leg drive.', FALSE),
('20000000-0000-0000-0000-000000000002', 'Incline Dumbbell Press', 'CHEST', 'Dumbbells + Incline Bench', 'Upper Chest, Deltoids', '30-degree incline press.', FALSE),
('20000000-0000-0000-0000-000000000003', 'Lat Pulldown', 'BACK', 'Cable Machine', 'Latissimus Dorsi, Biceps', 'Pull to upper clavicle with chest tall.', FALSE),
('20000000-0000-0000-0000-000000000004', 'Barbell Conventional Deadlift', 'BACK', 'Barbell', 'Erector Spinae, Glutes, Hamstrings', 'Hinge at hips, pull slack out of bar.', FALSE),
('20000000-0000-0000-0000-000000000005', 'Barbell Back Squat', 'LEGS', 'Barbell + Squat Rack', 'Quadriceps, Gluteus Maximus', 'Descend below parallel with neutral spine.', FALSE),
('20000000-0000-0000-0000-000000000006', 'Romanian Deadlift (RDL)', 'LEGS', 'Barbell or Dumbbells', 'Hamstrings, Gluteus Maximus', 'Hip hinge with soft knees.', FALSE),
('20000000-0000-0000-0000-000000000007', 'Overhead Dumbbell Shoulder Press', 'SHOULDERS', 'Dumbbells', 'Deltoids, Triceps', 'Press in scapular plane.', FALSE),
('20000000-0000-0000-0000-000000000008', 'Dumbbell Lateral Raise', 'SHOULDERS', 'Dumbbells', 'Lateral Deltoid', 'Lead with elbows.', FALSE),
('20000000-0000-0000-0000-000000000009', 'Incline Dumbbell Bicep Curl', 'BICEPS', 'Dumbbells + Incline Bench', 'Biceps Brachii', 'Supinate wrists at top.', FALSE),
('20000000-0000-0000-0000-000000000010', 'Triceps Rope Pushdown', 'TRICEPS', 'Cable Machine', 'Triceps Brachii', 'Flare rope apart at bottom.', FALSE),
('20000000-0000-0000-0000-000000000011', 'Barbell Hip Thrust', 'GLUTES', 'Barbell + Hip Thrust Bench', 'Gluteus Maximus', 'Full hip extension at lockout.', FALSE),
('20000000-0000-0000-0000-000000000012', 'Standing Calf Raise', 'CALVES', 'Calf Machine or Step', 'Gastrocnemius, Soleus', 'Full stretch and pause.', FALSE),
('20000000-0000-0000-0000-000000000013', 'Plank with Shoulder Taps', 'CORE', 'Bodyweight', 'Rectus Abdominis, Obliques', 'Maintain anti-rotational core stability.', FALSE),
('20000000-0000-0000-0000-000000000014', 'Barbell Clean and Press', 'FULL_BODY', 'Barbell', 'Full Kinetic Chain', 'Explosive triple extension.', FALSE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO packages (id, trainer_id, gym_id, name, description, sessions, price, validity_days) VALUES
('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '10 PT Sessions Starter Pack', 'Comprehensive 1-on-1 coaching & bi-weekly body scans.', 10, 499.00, 45),
('30000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '20 PT Elite Body Transformation', 'Full transformation program with 3x weekly training.', 20, 899.00, 90)
ON CONFLICT (id) DO NOTHING;
