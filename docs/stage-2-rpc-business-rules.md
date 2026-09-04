# FitTrainer (myPT) — Stage 2.0 Stored Procedures & Business RPC Specification

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 2.0 Transaction Architecture  
**Database Engine:** PostgreSQL 15+ (Supabase)  
**Date:** August 31, 2026  

---

## 1. RPC Architecture & Atomic Business Operations

All state mutations that affect financial balances, credit entitlements, cancellation penalties, or client assignments are encapsulated in **ACID-compliant PostgreSQL Stored Procedures (`SECURITY DEFINER`)**.

---

## 2. Core RPC Inventory & Business Rules

### 2.1 `verify_and_activate_package_payment(p_payment_id, p_verified_by)`
- **Business Rule:** Offline UPI payments require explicit coach verification before unlocking credits.
- **Atomic Operations:**
  1. Row lock (`SELECT ... FOR UPDATE`) on `payments`.
  2. Creates or activates `client_packages` with `status = 'ACTIVE'`, `remaining_sessions = pkg.sessions`, and `expires_at = NOW() + validity_days`.
  3. Inserts `PACKAGE_ACTIVATION` into `credit_ledger_transactions` with `delta_credits = +sessions` and `balance_after = sessions`.
  4. Dispatches notification to client.

---

### 2.2 `complete_pt_session(p_session_id, p_completed_by)`
- **Business Rule:** A completed 1-on-1 PT session deducts exactly 1 credit. Own Workouts deduct 0 credits.
- **Idempotency Guarantee:**
  ```sql
  IF v_session.credit_consumed = TRUE OR v_session.status = 'COMPLETED' THEN
      RETURN jsonb_build_object('success', true, 'message', 'Session was already completed. No duplicate credit deducted.', 'credit_deducted', 0);
  END IF;
  ```
- **Atomic Operations for PT Session:**
  1. Row lock on `sessions` and `client_packages`.
  2. Decrements `remaining_sessions` by 1.
  3. Inserts `SESSION_COMPLETION` into `credit_ledger_transactions` (`delta_credits = -1`).
  4. Sets `session.credit_consumed = TRUE` and `session.status = 'COMPLETED'`.
  5. Triggers low-credit warning notification if `balance <= 2`.

---

### 2.3 `apply_cancellation_policy(p_session_id, p_cancelled_by, p_reason)`
- **Business Rule:** Configurable 4-hour cancellation grace window.
  - Cancelled by Trainer $\to$ 0 penalty.
  - Cancelled by Client $\ge 4$ hours before start $\to$ 0 penalty.
  - Cancelled by Client $< 4$ hours before start $\to$ 1 credit penalty deducted via `CANCELLATION_PENALTY` in ledger.
- **Atomic Operations:**
  1. Evaluates difference in hours between `NOW()` and `scheduled_start`.
  2. If penalty applies, decrements package balance by 1 and logs ledger entry.
  3. Updates session status to `'CANCELLED'`.

---

### 2.4 `reassign_client(p_relationship_id, p_from_trainer_id, p_to_trainer_id, p_reason, p_reassigned_by)`
- **Business Rule:** Head Trainer / Gym Manager transfers client between coaches.
- **100% History Preservation Guarantee:**
  1. Updates `relationships` to point to new coach.
  2. Updates `client_packages.trainer_id` to new coach preserving exact `remaining_sessions`.
  3. Inserts `CLIENT_TRANSFER` audit log in credit ledger (`delta_credits = 0`).
  4. Workout history and progress measurement logs remain intact.
  5. Dispatches transfer notice to client.
