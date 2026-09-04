-- ============================================================================
-- FitTrainer (myPT) — Migration 001: Core Enums and Extensions
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Identity and Roles
CREATE TYPE user_role_type AS ENUM (
    'CLIENT',
    'TRAINER',
    'HEAD_TRAINER',
    'GYM_MANAGER',
    'SUPER_ADMIN'
);

-- 2. Trainer Verification Status
CREATE TYPE trainer_verification_status AS ENUM (
    'UNVERIFIED',
    'PENDING',
    'VERIFIED',
    'REJECTED'
);

-- 3. Relationship Lifecycle
CREATE TYPE relationship_status_type AS ENUM (
    'REQUESTED',
    'ACCEPTED',
    'APPROVED_FOR_PURCHASE',
    'ACTIVE',
    'INACTIVE',
    'REASSIGNED',
    'TERMINATED'
);

-- 4. Consultation Status
CREATE TYPE consultation_status_type AS ENUM (
    'REQUESTED',
    'ACCEPTED',
    'DECLINED',
    'COMPLETED'
);

-- 5. Package Validity Mode
CREATE TYPE validity_mode_type AS ENUM (
    'FIXED_WEEKS',
    'MONTHLY',
    'CUSTOM_DAYS'
);

-- 6. Client Package Status
CREATE TYPE client_package_status_type AS ENUM (
    'PENDING_PAYMENT',
    'ACTIVE',
    'EXPIRED',
    'EXHAUSTED',
    'TRANSFERRED',
    'CANCELLED'
);

-- 7. Payment Status & Method
CREATE TYPE payment_status_type AS ENUM (
    'PENDING_VERIFICATION',
    'VERIFIED',
    'REJECTED',
    'REFUNDED'
);

CREATE TYPE payment_method_type AS ENUM (
    'OFFLINE_MANUAL',
    'UPI_QR',
    'CASH',
    'ONLINE_GATEWAY'
);

-- 8. Credit Transaction Type (Append-Only Ledger)
CREATE TYPE credit_transaction_type AS ENUM (
    'PACKAGE_ACTIVATION',
    'SESSION_COMPLETION',
    'CANCELLATION_PENALTY',
    'MANUAL_ADJUSTMENT',
    'PACKAGE_EXPIRY',
    'CLIENT_TRANSFER',
    'REFUND'
);

-- 9. Session / Booking Status
CREATE TYPE session_status_type AS ENUM (
    'REQUESTED',
    'CONFIRMED',
    'DECLINED',
    'CANCELLED',
    'RESCHEDULED',
    'IN_PROGRESS',
    'COMPLETED',
    'NO_SHOW'
);

-- 10. Session Type (1-on-1 PT vs Independent Own Workout)
CREATE TYPE session_classification_type AS ENUM (
    'PERSONAL_TRAINING',
    'OWN_WORKOUT',
    'GROUP_TRAINING'
);

-- 11. Exercise Categories (12 Standard Anatomical Categories)
CREATE TYPE exercise_category_type AS ENUM (
    'CHEST',
    'BACK',
    'LEGS',
    'SHOULDERS',
    'BICEPS',
    'TRICEPS',
    'FOREARMS',
    'GLUTES',
    'HIPS',
    'CORE',
    'CALVES',
    'FULL_BODY'
);

-- 12. Notification Type
CREATE TYPE notification_type_enum AS ENUM (
    'BOOKING',
    'PAYMENT',
    'WORKOUT',
    'CONSULTATION',
    'REASSIGNMENT',
    'LOW_CREDIT',
    'WARNING',
    'SYSTEM'
);

-- 13. Cancellation Policy Type
CREATE TYPE cancellation_policy_type_enum AS ENUM (
    'FOUR_HOUR_STANDARD',
    'TWENTY_FOUR_HOUR_STRICT',
    'CUSTOM_WINDOW',
    'NO_PENALTY'
);
