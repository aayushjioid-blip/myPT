# FitTrainer (myPT) — Stage 2 Database Schema Inventory Audit

**Project:** FitTrainer (Fitness Trainer Platform)  
**Audit Date:** August 31, 2026  
**Status:** CANONICAL AUDIT VERIFIED  

---

## 1. Executive Summary & Inventory Correction

During the Stage 1.6 to Stage 2.0 transition, the initial high-level report summarized database entities into 21 logical groupings. This pre-flight audit establishes the **exact physical object count** from the canonical migration files in `supabase/migrations/`:

```
┌────────────────────────────────────────────────────────┐
│             CANONICAL DATABASE OBJECT SUMMARY          │
├─────────────────────────────────────────┬──────────────┤
│ Object Type                             │ Actual Count │
├─────────────────────────────────────────┼──────────────┤
│ Physical PostgreSQL Tables              │ 26           │
│ PostgreSQL ENUM Types                   │ 14           │
│ PostgreSQL Views                        │ 0            │
│ Database Stored Functions & RPCs        │ 10           │
│ Triggers (Auto-Timestamps)              │ 11           │
│ Performance Indexes (Explicit)          │ 21           │
└─────────────────────────────────────────┴──────────────┘
```

---

## 2. Canonical Physical Table Inventory (26 Tables)

| # | Physical Table Name | Purpose / Domain Responsibility | Primary Key | Foreign Keys | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `users` | Core identity & authentication mapping | `id` (UUID) | `auth_id` $\to$ `auth.users` | 5 user roles supported |
| 2 | `client_health_profiles` | Medical intake, injuries, emergency contact | `id` (UUID) | `user_id` $\to$ `users` | Contains `share_personal_info_with_trainer` flag |
| 3 | `gyms` | Facility metadata, occupancy (40), hours | `id` (UUID) | None | Floor capacity tracking |
| 4 | `trainer_profiles` | Bio, experience, rating, verification, 4h policy | `id` (UUID) | `user_id` $\to$ `users` | Unique `trainer_code` |
| 5 | `gym_memberships` | Multi-gym trainer affiliation mapping | `id` (UUID) | `gym_id`, `trainer_id` | Allows trainer in multiple gyms |
| 6 | `trainer_specializations`| Specialization tags (Hypertrophy, Mobility) | `id` (UUID) | `trainer_id` $\to$ `users` | Multi-valued tag table |
| 7 | `trainer_certifications` | Professional credentials (NASM, ACE) | `id` (UUID) | `trainer_id` $\to$ `users` | Title, issuer, certificate URL |
| 8 | `trainer_services` | Coaching services and duration | `id` (UUID) | `trainer_id` $\to$ `users` | Service name, price, duration |
| 9 | `trainer_working_hours` | Shifts per day & slot capacity | `id` (UUID) | `trainer_id` $\to$ `users` | Multiple shifts (morning/evening) |
| 10 | `packages` | Trainer package catalog (sessions, price, days) | `id` (UUID) | `trainer_id`, `gym_id` | Configurable validity |
| 11 | `relationships` | Client-trainer relationship lifecycle | `id` (UUID) | `client_id`, `trainer_id`, `gym_id` | `REQUESTED` $\to$ `ACTIVE` $\to$ `REASSIGNED` |
| 12 | `consultation_requests` | Consultation request intake & coach response | `id` (UUID) | `client_id`, `trainer_id` | Inbound client intake |
| 13 | `client_packages` | Client purchased active & pending packages | `id` (UUID) | `client_id`, `trainer_id`, `package_id` | Tracks `remaining_sessions` |
| 14 | `payments` | Offline UPI receipts & verification queue | `id` (UUID) | `client_id`, `trainer_id`, `package_id` | `PENDING_VERIFICATION` $\to$ `VERIFIED` |
| 15 | `credit_ledger_transactions` | **Append-only ledger (Source of Truth)** | `id` (UUID) | `client_package_id`, `client_id`, `session_id` | Immutable audit log |
| 16 | `sessions` | PT sessions & independent Own Workouts | `id` (UUID) | `client_id`, `trainer_id`, `client_package_id` | `credit_consumed` flag |
| 17 | `exercises` | 12-category global library & custom exercises | `id` (UUID) | `trainer_id` (NULL for global) | 12 anatomical categories |
| 18 | `workout_templates` | Reusable workout templates | `id` (UUID) | `trainer_id` $\to$ `users` | Reusable program blueprints |
| 19 | `workouts` | Assigned and completed workout routines | `id` (UUID) | `client_id`, `trainer_id`, `session_id` | PT vs Own Workout |
| 20 | `workout_exercises` | Exercise items in a workout | `id` (UUID) | `workout_id`, `exercise_id` | Preserves sequence order |
| 21 | `workout_sets` | Live set logs (reps, weight, RPE, completed) | `id` (UUID) | `workout_exercise_id` | Real-time set/rep logger |
| 22 | `progress_measurements` | 8-point body circumferences + generated BMI | `id` (UUID) | `client_id`, `logged_by` | Stored generated `bmi` |
| 23 | `progress_photos` | Front, Side, and Back pose photos | `id` (UUID) | `measurement_id`, `client_id` | Private storage path |
| 24 | `reviews` | Client 1–5 star ratings and reviews | `id` (UUID) | `trainer_id`, `client_id` | Unique 1 review per client/trainer |
| 25 | `notifications` | In-app user notifications & event references | `id` (UUID) | `user_id` $\to$ `users` | Unread badge counter |
| 26 | `feature_flags` | Centralized platform feature flags | `key` (VARCHAR) | None | `advanced_trainer_search: false` |

---

## 3. Physical vs Logical Mapping Clarification

In the high-level domain model, workouts and progress tracking are discussed as unified logical entities. In the physical database schema, they are properly normalized into:
- Logical `Workout` $\to$ Physical `workouts`, `workout_exercises`, `workout_sets` (3 physical tables).
- Logical `Progress` $\to$ Physical `progress_measurements`, `progress_photos` (2 physical tables).
- Logical `Trainer Profile` $\to$ Physical `trainer_profiles`, `trainer_specializations`, `trainer_certifications`, `trainer_services`, `trainer_working_hours` (5 physical tables).

This normalization prevents data duplication, supports arbitrary set counts per exercise, enables multiple shifts per day, and provides clean foreign key referential integrity.
