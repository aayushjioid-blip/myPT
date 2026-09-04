# Supabase Migration Risk Analysis & Mitigation Report

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 1.0  
**Phase:** Stage 1 Prototype Audit & Stage 1.5 Architecture Review  
**Date:** August 31, 2026  
**Status:** Audit Verified  

---

## 1. Executive Summary

This report provides an in-depth risk analysis of transitioning FitTrainer from the Stage 1 in-memory local prototype to a production **Supabase (PostgreSQL 15+ / GoTrue / Storage / Realtime / Edge Functions)** backend. Every potential point of failure, data inconsistency risk, security vulnerability, and architectural difference is categorized by severity with a detailed mitigation plan.

---

## 2. Risk Classification Matrix

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          MIGRATION RISK SEVERITY MATRIX                         │
├───────────────────┬─────────────────────────────────────────────────────────────┤
│ 🔴 CRITICAL (3)   │ • Client-Side State Tampering & Missing Server-Side RLS     │
│                   │ • Mutable Credit Field vs Append-Only Ledger Concurrency    │
│                   │ • Sensitive Medical & Health Data Stored in Local Plaintext │
├───────────────────┼─────────────────────────────────────────────────────────────┤
│ 🟠 HIGH (4)       │ • Booking Slot Capacity Race Conditions & Overbooking       │
│                   │ • Auth Paradigm Shift (Mock Switcher ➔ Supabase GoTrue Auth)│
│                   │ • Client Clock Tampering on 4-Hour Cancellation Windows     │
│                   │ • Relationship Gating Bypassing at API Layer                │
├───────────────────┼─────────────────────────────────────────────────────────────┤
│ 🟡 MEDIUM (3)     │ • Private Progress Photo Storage & Signed URL Expiration    │
│                   │ • Offline UPI Payment Reconciliation & Edge Webhooks        │
│                   │ • Realtime WebSocket Subscriptions vs In-Memory Pub/Sub     │
├───────────────────┼─────────────────────────────────────────────────────────────┤
│ 🟢 LOW (2)        │ • Runtime Feature Flags Dynamic Caching                     │
│                   │ • Timezone Normalization & UTC Formatting                   │
└───────────────────┴─────────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Risk Analysis by Severity

### 🔴 CRITICAL RISKS

#### Risk 1: Client-Side State Tampering & Missing Server-Side Authorization (RLS)
- **Current Prototype State:** All state mutations occur directly in the browser memory and `localStorage`. Any user can modify JavaScript variables to change their credit balance, mark sessions completed, or view other trainers' clients.
- **Migration Impact:** Without rigorous Row Level Security (RLS) policies in PostgreSQL, exposing Supabase APIs directly to client apps (`@supabase/supabase-js`) allows authenticated users to read or mutate unauthorized rows.
- **Mitigation Strategy:**
  - Enable `ALTER TABLE <table_name> ENABLE ROW LEVEL SECURITY;` on **every** table.
  - Enforce explicit RLS policies:
    ```sql
    -- Example: Clients can only read their own measurements
    CREATE POLICY "Clients read own measurements" ON progress_measurements
      FOR SELECT USING (auth.uid() = client_id);
      
    -- Example: Trainers only read measurements if client opted in
    CREATE POLICY "Trainers read client measurements if opted in" ON progress_measurements
      FOR SELECT USING (
        EXISTS (
          SELECT 1 FROM relationships r
          JOIN users u ON u.id = r.client_id
          WHERE r.trainer_id = auth.uid() 
            AND r.client_id = progress_measurements.client_id 
            AND r.status = 'ACCEPTED' 
            AND u.share_personal_info_with_trainer = TRUE
        )
      );
    ```

---

#### Risk 2: Mutable Credit Balance vs Append-Only Ledger
- **Current Prototype State:** Credits are modified by directly mutating `client_packages.remaining_sessions -= 1`.
- **Migration Impact:** In a multi-user environment, two concurrent requests (e.g. rapid double-tap on session completion or simultaneous API triggers) will cause a race condition, leading to lost updates or incorrect deductions.
- **Mitigation Strategy:**
  - Deprecate mutable in-place integer fields.
  - Implement an **Append-Only `credit_ledger_transactions` Table** with PostgreSQL row-level locks (`SELECT ... FOR UPDATE`) and database stored procedures (`deduct_pt_session_credit()`).

---

#### Risk 3: Sensitive Medical & Health Intake Data Exposure
- **Current Prototype State:** Client injuries, medical notes, and emergency contacts are stored in the shared `users` object in browser memory.
- **Migration Impact:** Medical data subject to compliance (e.g., HIPAA / GDPR) must not reside in public user profile tables or unencrypted browser storage.
- **Mitigation Strategy:**
  - Segregate medical/injury data into a separate `client_health_profiles` table with restricted RLS and encryption at rest.

---

### 🟠 HIGH RISKS

#### Risk 4: Booking Slot Capacity Race Conditions & Overbooking
- **Current Prototype State:** Prototype filters in-memory array `existingInSlot.length >= maxCapacity`.
- **Migration Impact:** If two clients submit booking requests for the last available slot at the same millisecond, both requests will pass if evaluated independently without transactional locking.
- **Mitigation Strategy:**
  - Use a PostgreSQL serializable transaction or advisory lock inside a booking RPC function:
    ```sql
    CREATE OR REPLACE FUNCTION book_training_session(
      p_client_id UUID, p_trainer_id UUID, p_package_id UUID, p_scheduled_start TIMESTAMPTZ
    ) RETURNS UUID ...
    ```

---

#### Risk 5: Authentication Paradigm Shift (Mock Switcher $\to$ Supabase GoTrue Auth)
- **Current Prototype State:** Instant role switching via `store.setCurrentUser(userId)` without credential validation.
- **Migration Impact:** Transitioning to real Phone OTP (`supabase.auth.signInWithOtp({ phone })`) and Google OAuth requires handling auth state listeners (`onAuthStateChange`), token refreshes, JWT expiration, and session storage.
- **Mitigation Strategy:**
  - Create an abstract `AuthRepository` interface in Stage 1.5 that decouples the UI from auth mechanisms, allowing the mock switcher to be replaced by GoTrue without modifying UI screens.

---

#### Risk 6: Client Clock Tampering on 4-Hour Cancellation Cutoff
- **Current Prototype State:** Calculated using client browser `new Date().getTime()`.
- **Migration Impact:** A malicious or erroneous client device clock could bypass the 4-hour cancellation penalty cutoff.
- **Mitigation Strategy:**
  - Perform all cancellation penalty evaluations server-side in PostgreSQL using `NOW()` / `CURRENT_TIMESTAMP`.

---

#### Risk 7: Relationship Gating Bypassing
- **Current Prototype State:** UI prevents package selection if relationship is not `ACCEPTED`.
- **Migration Impact:** Direct API calls could attempt to create bookings or packages with trainers without approval.
- **Mitigation Strategy:**
  - Database-level Foreign Key triggers ensuring `relationships.status = 'ACCEPTED'` before any booking or package record is created.

---

### 🟡 MEDIUM RISKS

#### Risk 8: Progress Photo Storage & Signed URL Expiration
- **Current Prototype State:** Simulated text strings (`"📸 Front View Uploaded"`).
- **Migration Impact:** Storing binary image files requires Supabase Storage buckets, thumbnail generation, and expiring signed URLs for private viewing.
- **Mitigation Strategy:**
  - Create a private bucket `progress-photos` with RLS policies restricting access to the owning client and authorized trainer.

---

#### Risk 9: Offline UPI Payment Reconciliation
- **Current Prototype State:** Instant simulated payment ID with in-memory status toggle.
- **Migration Impact:** Offline payments require manual receipt review, dispute handling, and optional OCR reference number extraction.
- **Mitigation Strategy:**
  - Implement a structured payment verification console with audit log tracking (`verified_by`, `verified_at`, `rejection_reason`).

---

#### Risk 10: Real-Time Cross-Device Synchronization
- **Current Prototype State:** Local JavaScript `store.notify()` listener loop.
- **Migration Impact:** In production, a trainer confirming a session on their phone must instantly notify the client's device without manual page refreshes.
- **Mitigation Strategy:**
  - Subscribe to Supabase Realtime Channels:
    `supabase.channel('sessions').on('postgres_changes', { event: 'UPDATE', table: 'sessions' }, ...)`

---

### 🟢 LOW RISKS

#### Risk 11: Runtime Feature Flags Storage
- **Current Prototype State:** Simple JavaScript object in state store.
- **Migration Impact:** Low risk. Transition to a simple `feature_flags` table queried once on app launch and cached locally.

#### Risk 12: Timezone Normalization
- **Current Prototype State:** Local string timestamps (`2026-09-01T10:00:00`).
- **Migration Impact:** In multi-timezone or daylight-saving scenarios, timezone offsets can cause calendar discrepancies.
- **Mitigation Strategy:**
  - Store all timestamps in PostgreSQL as `TIMESTAMPTZ` (UTC) and convert to client local timezone in the UI.

---

## 4. Recommended Stage 1.5 Architecture Review Roadmap

Before beginning Stage 2 backend coding, execute the following preparatory steps in **Stage 1.5**:

1. **Abstract Repository Interfaces:** Define clear repository contracts (`IAuthRepository`, `ITrainerRepository`, `IBookingRepository`, `ICreditLedgerRepository`) separating business logic from storage implementation.
2. **PostgreSQL DDL Migration Scripts:** Write idempotent `.sql` migration files implementing the 18+ tables, RLS policies, custom types, and stored procedures.
3. **Ledger Concurrency Verification:** Review and test SQL stored procedures for credit deductions under high concurrency simulations.
