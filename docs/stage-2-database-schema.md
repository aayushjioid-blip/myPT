# FitTrainer (myPT) — Stage 2.0 Database Schema Specification

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 2.0 Production DDL  
**Database Engine:** PostgreSQL 15+ (Supabase)  
**Date:** August 31, 2026  
**Status:** Validated & Deployed  

---

## 1. Database Architecture Overview

The FitTrainer backend schema is built on **normalized relational modeling**, strict **referential integrity**, **UUID primary keys**, **timezone-aware timestamps (`TIMESTAMPTZ`)**, **Row Level Security (RLS)**, and an **append-only credit ledger**.

---

## 2. Table Inventory (21 Normalized Tables)

| # | Table Name | Purpose / Business Responsibility | Primary Key | Key Foreign Keys |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `users` | Core user identity (Clients, Trainers, Head Trainers, Gym Managers, Super Admins) | `id` (UUID) | `auth_id` $\to$ `auth.users(id)` |
| 2 | `client_health_profiles` | Client fitness intake, medical notes, injuries, emergency contact & privacy toggle | `id` (UUID) | `user_id` $\to$ `users(id)` |
| 3 | `gyms` | Facility information, occupancy limits (40), operating hours, amenities | `id` (UUID) | None |
| 4 | `trainer_profiles` | Bio, experience, hourly rate, rating, verification status, 4-hour cancellation policy | `id` (UUID) | `user_id` $\to$ `users(id)` |
| 5 | `gym_memberships` | Multi-gym trainer affiliation model (`TRAINER`, `HEAD_TRAINER`, `GYM_MANAGER`) | `id` (UUID) | `gym_id`, `trainer_id` |
| 6 | `trainer_specializations`| Specialization tags (Hypertrophy, Mobility, Boxing, Calisthenics) | `id` (UUID) | `trainer_id` $\to$ `users(id)` |
| 7 | `trainer_certifications` | Professional credentials (NASM-CPT, ACE, RYT-500) | `id` (UUID) | `trainer_id` $\to$ `users(id)` |
| 8 | `trainer_services` | Offered coaching services and durations | `id` (UUID) | `trainer_id` $\to$ `users(id)` |
| 9 | `trainer_working_hours` | Weekly schedule, multiple shifts (morning + evening), slot capacity | `id` (UUID) | `trainer_id` $\to$ `users(id)` |
| 10 | `packages` | Trainer-defined product packages (sessions, price, validity days) | `id` (UUID) | `trainer_id`, `gym_id` |
| 11 | `relationships` | Client-trainer coaching relationship lifecycle | `id` (UUID) | `client_id`, `trainer_id`, `gym_id` |
| 12 | `consultation_requests` | Inbound client consultation intake and trainer response | `id` (UUID) | `client_id`, `trainer_id` |
| 13 | `client_packages` | Purchased active and pending client session packages | `id` (UUID) | `client_id`, `trainer_id`, `package_id` |
| 14 | `payments` | Payment transaction records (Offline UPI reference & Online gateway) | `id` (UUID) | `client_id`, `trainer_id`, `package_id` |
| 15 | `credit_ledger_transactions`| **Immutable Append-Only Source of Truth for all credit movements** | `id` (UUID) | `client_package_id`, `client_id`, `session_id` |
| 16 | `sessions` | Scheduled PT sessions and independent Own Workouts | `id` (UUID) | `client_id`, `trainer_id`, `client_package_id` |
| 17 | `exercises` | 12-category global exercise directory + trainer custom exercises | `id` (UUID) | `trainer_id` (NULL for global) |
| 18 | `workout_templates` | Reusable workout program templates | `id` (UUID) | `trainer_id` $\to$ `users(id)` |
| 19 | `workouts` | Assigned and logged workout routines | `id` (UUID) | `client_id`, `trainer_id`, `session_id` |
| 20 | `workout_exercises` & `workout_sets` | Exercise line items with sets, reps, weight, RPE, and completion status | `id` (UUID) | `workout_id`, `exercise_id` |
| 21 | `progress_measurements` & `progress_photos` | 8-point body circumferences, generated BMI, and pose photos | `id` (UUID) | `client_id`, `logged_by` |
| 22 | `reviews` | Client 1–5 star ratings and written feedback | `id` (UUID) | `trainer_id`, `client_id` |
| 23 | `notifications` | In-app user notifications and event references | `id` (UUID) | `user_id` $\to$ `users(id)` |
| 24 | `feature_flags` | Runtime platform feature flags (`advanced_trainer_search: false`) | `key` (VARCHAR)| None |

---

## 3. Core Column Definitions & Constraints

### 3.1 Generated BMI Calculation
```sql
bmi NUMERIC(4,1) GENERATED ALWAYS AS (
    ROUND((weight_kg / ((height_cm / 100.0) * (height_cm / 100.0))), 1)
) STORED;
```
Ensures zero math discrepancy between server, client, and SQL queries.

### 3.2 Append-Only Credit Ledger Guarantee
The table `credit_ledger_transactions` records every balance alteration with `delta_credits` and `balance_after`. Client packages are updated only via atomic PostgreSQL stored procedures (`verify_and_activate_package_payment`, `complete_pt_session`, `apply_cancellation_policy`).
