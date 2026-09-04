# Session Credit Architecture & Modification Audit

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 1.0  
**Phase:** Stage 1 Prototype Audit & Stage 1.5 Architecture Review  
**Date:** August 31, 2026  
**Status:** Audit Verified  

---

## 1. Executive Summary

This document performs a comprehensive code-level audit of all paths where personal training (PT) session credits are created, deducted, verified, transferred, or mutated within the FitTrainer codebase. It evaluates concurrency and integrity risks and presents the definitive **Stage 2 Session Credit Ledger Architecture**.

---

## 2. Comprehensive Code Path Audit

### 2.1 Code Path 1: Adding & Activating Credits (Package Purchase Verification)
- **Source File:** [`app/src/state/actions.js`](file:///c:/Users/aayus/OneDrive/Documents/aayushProjectPro/app/src/state/actions.js#L379-L425) (`verifyPayment`)
- **Trigger:** Trainer clicks "Verify Payment" on offline UPI/Cash payment queue.
- **Credit Operation:**
  ```javascript
  if (approve) {
    payment.payment_status = 'PAID';
    clientPkg.status = 'ACTIVE';
    clientPkg.remaining_sessions = clientPkg.total_sessions; // e.g. Sets to 10
    clientPkg.activation_date = new Date().toISOString();
  }
  ```
- **Integrity Status:** ✅ **Protected**. Inactive packages start with `remaining_sessions = 0` during `PENDING_PAYMENT` state. Credits are unlocked only upon explicit trainer verification.

---

### 2.2 Code Path 2: Deducting Credits (Session Completion)
- **Source File:** [`app/src/state/actions.js`](file:///c:/Users/aayus/OneDrive/Documents/aayushProjectPro/app/src/state/actions.js#L427-L466) (`completeSessionAndLogWorkout`)
- **Trigger:** Trainer or Client marks an active PT session as `COMPLETED`.
- **Credit Operation:**
  ```javascript
  if (session.session_type === 'PERSONAL_TRAINING' && !session.credit_consumed) {
    session.credit_consumed = true;
    const clientPkg = state.client_packages.find(cp => cp.id === session.client_package_id);
    if (clientPkg && clientPkg.remaining_sessions > 0) {
      clientPkg.remaining_sessions -= 1;
      clientPkg.completed_sessions += 1;
    }
  }
  ```
- **Integrity Status:** ✅ **Guarded**. Strictly enforces `session.session_type === 'PERSONAL_TRAINING'` and `!session.credit_consumed` check before decrementing.

---

### 2.3 Code Path 3: Deducting Penalty Credits (Late Cancellation)
- **Source File:** [`app/src/state/actions.js`](file:///c:/Users/aayus/OneDrive/Documents/aayushProjectPro/app/src/state/actions.js#L195-L224) (`cancelSession`)
- **Trigger:** Client or Trainer cancels a booked session.
- **Credit Operation:**
  ```javascript
  const isPenalty = trainer && trainer.cancellation_policy === 'FOUR_HOUR_POLICY' && hoursUntilSession < 4;
  if (isPenalty && session.session_type === 'PERSONAL_TRAINING' && !session.credit_consumed) {
    session.credit_consumed = true;
    const clientPkg = state.client_packages.find(cp => cp.id === session.client_package_id);
    if (clientPkg && clientPkg.remaining_sessions > 0) {
      clientPkg.remaining_sessions -= 1;
    }
  }
  ```
- **Integrity Status:** ✅ **Evaluated**. No credit is deducted if cancellation occurs $\ge 4$ hours prior to start.

---

### 2.4 Code Path 4: Booking Precondition Check (Zero Deduction on Booking)
- **Source File:** [`app/src/state/actions.js`](file:///c:/Users/aayus/OneDrive/Documents/aayushProjectPro/app/src/state/actions.js#L115-L162) (`requestSessionBooking`)
- **Trigger:** Client selects date and time slot to book single or recurring sessions.
- **Credit Operation:**
  ```javascript
  if (!clientPkg || clientPkg.remaining_sessions < recurringWeeks) {
    alert('Cannot book session: Insufficient credits.');
    return null;
  }
  // Session created with credit_consumed: false (0 CREDITS DEDUCTED ON BOOKING)
  const session = { status: 'REQUESTED', credit_consumed: false };
  ```
- **Integrity Status:** ✅ **Strict Compliance**. Balances remain unchanged upon booking.

---

### 2.5 Code Path 5: Client "Own Workouts" (Zero PT Credit Guarantee)
- **Source File:** [`app/src/state/actions.js`](file:///c:/Users/aayus/OneDrive/Documents/aayushProjectPro/app/src/state/actions.js#L54-L86) (`createAndLogOwnWorkout`)
- **Trigger:** Client builds and completes an independent workout.
- **Credit Operation:**
  ```javascript
  const ownWorkout = { workout_type: 'OWN_WORKOUT', status: 'COMPLETED' };
  state.sessions.push({ session_type: 'OWN_WORKOUT', credit_consumed: false });
  // client_packages collection is completely untouched!
  ```
- **Integrity Status:** ✅ **Strict Zero Credit Guarantee**. 0 PT credits deducted.

---

### 2.6 Code Path 6: Client Reassignment (Credit & Log Preservation)
- **Source File:** [`app/src/state/actions.js`](file:///c:/Users/aayus/OneDrive/Documents/aayushProjectPro/app/src/state/actions.js#L231-L264) (`reassignClient`)
- **Trigger:** Head Trainer or Gym Manager transfers client to another staff trainer.
- **Credit Operation:**
  ```javascript
  state.client_packages.forEach(cp => {
    if (cp.client_id === rel.client_id && cp.trainer_id === oldTrainer?.id) {
      cp.trainer_id = newTrainerId; // Preserves remaining_sessions exactly as is!
    }
  });
  ```
- **Integrity Status:** ✅ **Preserved**. Balances and completed historical counts remain intact.

---

## 3. Comprehensive Risk Assessment Matrix

| Potential Risk Scenario | Current Prototype Mitigation | Production (Stage 2) Risk Level | Required Stage 2 Architectural Guard |
| :--- | :--- | :--- | :--- |
| **Double Deduction** | In-memory boolean flag `session.credit_consumed` | **HIGH** (Race condition on concurrent API requests) | PostgreSQL row lock (`SELECT ... FOR UPDATE`) + Unique constraint on `(session_id, transaction_type)` in ledger. |
| **Deduction from Own Workouts** | Explicit `session_type === 'PERSONAL_TRAINING'` check | **MEDIUM** (Client API tampering) | Database Check Constraint: `CHECK (session_type = 'OWN_WORKOUT' AND credit_consumed = FALSE)`. |
| **Deduction Before Completion** | Deduction only triggered in `completeSessionAndLogWorkout()` | **MEDIUM** (Premature trigger) | Database trigger enforcing session `status = 'COMPLETED'` before credit transaction record can be inserted. |
| **Reassignment Balance Loss** | Iterates over active packages and updates `trainer_id` | **LOW** (Relational foreign key) | Relational Foreign Key update with transactional integrity in PostgreSQL. |
| **Tampering with Cancellation Time** | Local JS `Date()` timestamp calculation | **HIGH** (Client device clock skew) | Server-side database clock (`CURRENT_TIMESTAMP` / UTC) evaluated in PostgreSQL stored procedure. |
| **Package Expiration Failure** | Implicit expiration string in mock model | **HIGH** (Expired credits remaining usable) | Automated Edge Function cron / SQL scheduled job marking expired packages and logging `EXPIRATION` ledger entry. |

---

## 4. Proposed Session Credit Ledger Architecture (Stage 2)

In Stage 2, mutable in-place integer balance fields (`client_packages.remaining_sessions`) will be superseded by an **Immutable Append-Only Credit Ledger**.

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                           POSTGRESQL CREDIT LEDGER ENGINE                             │
├───────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                       │
│   [Package Purchase]        [Session Completed]      [Late Cancellation]   [Refund]   │
│           │                         │                        │                │       │
│        (+10)                      (-1)                     (-1)             (+1)      │
│           │                         │                        │                │       │
│           ▼                         ▼                        ▼                ▼       │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐  │
│  │                    TABLE: credit_ledger_transactions (Append-Only)               │  │
│  ├─────────────────────────────────────────────────────────────────────────────────┤  │
│  │ • id (UUID PK)                                                                  │  │
│  │ • client_id (UUID FK -> users)                                                  │  │
│  │ • client_package_id (UUID FK -> client_packages)                                │  │
│  │ • session_id (UUID FK -> sessions, NULLABLE)                                    │  │
│  │ • transaction_type (ENUM: ACTIVATION, SESSION_COMPLETE, PENALTY, REFUND, EXPIRE) │  │
│  │ • delta_credits (INTEGER: +10, -1, +1, etc.)                                    │  │
│  │ • balance_after (INTEGER)                                                       │  │
│  │ • idempotency_key (TEXT UNIQUE)                                                 │  │
│  │ • created_at (TIMESTAMPTZ DEFAULT NOW())                                        │  │
│  │ • created_by (UUID FK -> users)                                                 │  │
│  └─────────────────────────────────────────────────────────────────────────────────┘  │
│                                           │                                           │
│                                           ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐  │
│  │                    MATERIALIZED VIEW / COMPUTED BALANCE                         │  │
│  │                    SELECT client_package_id, SUM(delta_credits)                  │  │
│  │                    FROM credit_ledger_transactions GROUP BY client_package_id   │  │
│  └─────────────────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

### Key PostgreSQL Stored Procedure Specification:
```sql
CREATE OR REPLACE FUNCTION deduct_pt_session_credit(
    p_session_id UUID,
    p_trainer_id UUID
) RETURNS INTEGER AS $$
DECLARE
    v_session RECORD;
    v_package RECORD;
    v_new_balance INTEGER;
BEGIN
    -- 1. Lock session row for update to prevent concurrent double deductions
    SELECT * INTO v_session FROM sessions WHERE id = p_session_id FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Session not found: %', p_session_id;
    END IF;
    
    IF v_session.session_type != 'PERSONAL_TRAINING' THEN
        RAISE EXCEPTION 'Cannot deduct credits for non-PT sessions (e.g. Own Workouts)';
    END IF;
    
    IF v_session.credit_consumed THEN
        RAISE EXCEPTION 'Credit already consumed for session %', p_session_id;
    END IF;
    
    -- 2. Lock package row and verify credit balance
    SELECT * INTO v_package FROM client_packages WHERE id = v_session.client_package_id FOR UPDATE;
    
    -- 3. Calculate current balance
    SELECT COALESCE(SUM(delta_credits), 0) - 1 INTO v_new_balance 
    FROM credit_ledger_transactions 
    WHERE client_package_id = v_package.id;
    
    IF v_new_balance < 0 THEN
        RAISE EXCEPTION 'Insufficient credits remaining in package %', v_package.id;
    END IF;
    
    -- 4. Insert immutable ledger entry
    INSERT INTO credit_ledger_transactions (
        client_id, client_package_id, session_id, transaction_type, delta_credits, balance_after, idempotency_key, created_by
    ) VALUES (
        v_session.client_id, v_package.id, v_session.id, 'SESSION_COMPLETION', -1, v_new_balance, 'sess_deduct_' || p_session_id, p_trainer_id
    );
    
    -- 5. Update session flag
    UPDATE sessions SET status = 'COMPLETED', credit_consumed = TRUE, completed_at = NOW() WHERE id = p_session_id;
    
    RETURN v_new_balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```
