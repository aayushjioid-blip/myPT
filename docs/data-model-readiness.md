# Data Model Readiness & Entity Audit Report

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 1.0  
**Phase:** Stage 1 Prototype Audit & Stage 1.5 Architecture Review  
**Date:** August 31, 2026  
**Status:** Audit Verified  

---

## 1. Executive Summary

This document audits all data models present in the Stage 1 prototype. It evaluates their readiness for production PostgreSQL schema deployment in Supabase, identifying missing attributes (`updated_at`, stable UUIDs, relational foreign keys) and defining the required entity enhancements.

---

## 2. Master Entity Readiness Matrix

| Entity | Current Prototype Key / ID Format | `created_at` Present? | `updated_at` Present? | `status` Field | Ownership / Relational Foreign Keys | Readiness Score |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`users`** | `usr-admin-1`, `usr-client-1` (String) | ❌ Missing | ❌ Missing | `ACTIVE` / `SUSPENDED` | `auth.users.id` (Target PK), `gym_id` (Nullable) | **70% (Needs timestamps & auth sync)** |
| **`trainers`** | `trn-alex`, `trn-maya` (String) | ❌ Missing | ❌ Missing | `verification_status` (`VERIFIED`/`UNVERIFIED`) | `user_id` $\to$ `users.id` | **75% (Needs working hours JSONB & timestamps)** |
| **`gyms`** | `gym-ironcore` (String) | ❌ Missing | ❌ Missing | `ACTIVE` / `INACTIVE` | `owner_id` $\to$ `users.id`, `head_trainer_id` $\to$ `users.id` | **80% (Ready for Postgres)** |
| **`gym_trainer_affiliations`** | `aff-1` (String) | ❌ Missing | ❌ Missing | `ACTIVE` / `TERMINATED` | `gym_id` $\to$ `gyms.id`, `trainer_id` $\to$ `trainers.id` | **85% (Clean Junction Table)** |
| **`packages`** | `pkg-10pt`, `pkg-20pt` (String) | ❌ Missing | ❌ Missing | `ACTIVE` / `ARCHIVED` | `trainer_id` $\to$ `trainers.id` | **80% (Ready for Postgres)** |
| **`relationships`** | `rel-<timestamp>` (String) | ✅ Present | ❌ Missing | `REQUESTED`, `ACCEPTED`, `REJECTED`, `INACTIVE` | `client_id` $\to$ `users.id`, `trainer_id` $\to$ `trainers.id` | **90% (High Readiness)** |
| **`client_packages`** | `cpkg-<timestamp>` (String) | ✅ Present (`purchase_date`) | ❌ Missing | `PENDING_PAYMENT`, `ACTIVE`, `CANCELLED`, `EXPIRED` | `client_id` $\to$ `users.id`, `trainer_id` $\to$ `trainers.id`, `package_id` $\to$ `packages.id` | **85% (Needs Ledger Link)** |
| **`payments`** | `pay-<timestamp>` (String) | ✅ Present | ❌ Missing | `PENDING_VERIFICATION`, `PAID`, `REJECTED` | `client_id` $\to$ `users.id`, `trainer_id` $\to$ `trainers.id`, `package_id` $\to$ `packages.id` | **90% (High Readiness)** |
| **`sessions`** | `sess-<timestamp>` (String) | ✅ Present | ❌ Missing | `REQUESTED`, `CONFIRMED`, `COMPLETED`, `CANCELLED` | `client_id` $\to$ `users.id`, `trainer_id` $\to$ `trainers.id`, `client_package_id` $\to$ `client_packages.id` | **90% (High Readiness)** |
| **`exercises`** | `ex-1`, `ex-custom-<ts>` (String) | ❌ Missing | ❌ Missing | N/A | `trainer_id` (Nullable for global library) | **85% (12 Categories Verified)** |
| **`workout_templates`** | `tmpl-<timestamp>` (String) | ❌ Missing | ❌ Missing | N/A | `trainer_id` $\to$ `trainers.id` | **80% (Exercises JSONB array)** |
| **`workouts`** | `wo-<timestamp>`, `wo-own-<ts>` | ✅ Present (`assigned_date`) | ❌ Missing | `PENDING`, `COMPLETED` | `client_id` $\to$ `users.id`, `trainer_id` (Nullable for Own Workouts) | **85% (High Readiness)** |
| **`progress_measurements`** | `m-1`, `m-<timestamp>` (String) | ✅ Present (`date`) | ❌ Missing | N/A | `client_id` $\to$ `users.id` | **85% (8-Point Metrics & BMI)** |
| **`reviews`** | `rev-1`, `rev-<timestamp>` (String) | ✅ Present (`created_at`) | ❌ Missing | N/A | `trainer_id` $\to$ `trainers.id`, `client_id` $\to$ `users.id` | **90% (High Readiness)** |
| **`feature_flags`** | Key-Value Object | ❌ Missing | ❌ Missing | N/A | Global Super Admin scope | **75% (Needs dedicated DB table)** |
| **`notifications`** | `notif-<timestamp>` (String) | ✅ Present (`timestamp`) | ❌ Missing | `read` (Boolean) | `user_id` $\to$ `users.id` | **90% (High Readiness)** |

---

## 3. Entity-by-Entity Detailed Audit & Schema Adjustments

### 3.1 `users` Table
- **Current Mock Structure:** `{ id, name, email, role, avatar, status, share_personal_info_with_trainer, gym_id, age, height_cm, weight_kg, fitness_goal, injuries, medical_info, emergency_contact }`
- **Required Stage 2 Adjustments:**
  1. Primary Key must link directly to Supabase Auth: `id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE`.
  2. Add `created_at TIMESTAMPTZ DEFAULT NOW()` and `updated_at TIMESTAMPTZ DEFAULT NOW()`.
  3. Extract health/medical data into a distinct `client_health_profiles` table with dedicated Row Level Security (RLS) to enforce privacy boundaries at the database level.

---

### 3.2 `trainers` Table
- **Current Mock Structure:** `{ id, user_id, name, verification_status, bio, experience_years, certifications, specializations, skills, services, languages, location, trainer_code, upi_id, mobile_payment_number, cancellation_policy, custom_cancellation_hours, rating, review_count, trial_days_remaining, working_hours }`
- **Required Stage 2 Adjustments:**
  1. Add `created_at` and `updated_at` timestamps.
  2. Enforce `trainer_code` uniqueness constraint: `trainer_code VARCHAR(10) UNIQUE NOT NULL`.
  3. Store `certifications`, `specializations`, `skills`, and `services` as PostgreSQL `TEXT[]` or `JSONB`.
  4. Store `working_hours` as `JSONB` structure with schema validation.

---

### 3.3 `relationships` (Client-Trainer Connection)
- **Current Mock Structure:** `{ id, client_id, trainer_id, status, goals, notes, approved_for_packages, created_at, accepted_at, reassigned_at, reassignment_reason }`
- **Required Stage 2 Adjustments:**
  1. Add unique constraint: `UNIQUE(client_id, trainer_id)` for active states.
  2. Add `updated_at TIMESTAMPTZ DEFAULT NOW()`.
  3. Status ENUM: `CREATE TYPE relationship_status AS ENUM ('REQUESTED', 'ACCEPTED', 'REJECTED', 'INACTIVE', 'TERMINATED');`.

---

### 3.4 `client_packages` & `payments`
- **Current Mock Structure:**
  - `client_packages`: `{ id, client_id, trainer_id, package_id, total_sessions, completed_sessions, remaining_sessions, validity_days, purchase_date, activation_date, expiry_date, status, payment_id }`
  - `payments`: `{ id, client_id, trainer_id, package_id, amount, payment_method, transaction_reference, payment_status, created_at, verified_at, verified_by }`
- **Required Stage 2 Adjustments:**
  1. Add Foreign Key constraints linking `client_packages.payment_id` $\to$ `payments.id`.
  2. Add `updated_at` timestamps on both tables.
  3. Connect `client_packages` to the immutable `credit_ledger_transactions` table.

---

### 3.5 `sessions` Table
- **Current Mock Structure:** `{ id, client_id, trainer_id, client_package_id, session_type, scheduled_start, status, is_recurring, credit_consumed, created_at, confirmed_at, completed_at, cancelled_at, cancel_reason }`
- **Required Stage 2 Adjustments:**
  1. Check constraint: `CHECK (session_type IN ('PERSONAL_TRAINING', 'OWN_WORKOUT'))`.
  2. Check constraint: `CHECK (session_type != 'OWN_WORKOUT' OR credit_consumed = FALSE)` to guarantee database-level zero credit consumption for client own workouts.
  3. Index on `(trainer_id, scheduled_start)` and `(client_id, scheduled_start)` for calendar queries.

---

### 3.6 `progress_measurements` Table
- **Current Mock Structure:** `{ id, client_id, date, weight, height_cm, bmi, body_fat, chest, waist, hips, biceps, thighs, calves, photos, notes }`
- **Required Stage 2 Adjustments:**
  1. Generated column for BMI: `bmi NUMERIC(4,1) GENERATED ALWAYS AS (weight / ((height_cm / 100.0) * (height_cm / 100.0))) STORED`.
  2. `photos` column converted to `JSONB` array of encrypted storage paths: `{"front_url": "...", "side_url": "...", "back_url": "..."}`.
  3. RLS policy allowing read access to trainer **only if** `users.share_personal_info_with_trainer = TRUE`.

---

## 4. Key Takeaways for Stage 1.5 & Stage 2

1. **UUID Standardization**: All client-side generated IDs (`rel-${Date.now()}`, `sess-${Date.now()}`) must be transitioned to database-generated `gen_random_uuid()` (UUIDv4/v7) in PostgreSQL.
2. **Automatic Timestamp Triggers**: Implement standard PostgreSQL `moddatetime` or custom triggers across all tables for automatic `updated_at = NOW()` maintenance.
3. **Database-Level Integrity Constraints**: Move validation rules (credit balance non-negative, own workout zero-credit constraint, relationship uniqueness) from JavaScript client code into PostgreSQL database constraints.
