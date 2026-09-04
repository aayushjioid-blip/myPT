# Cancellation Policy & Late Penalty Verification Audit

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 1.0  
**Phase:** Stage 1 Prototype Audit & Stage 1.5 Architecture Review  
**Date:** August 31, 2026  
**Status:** Audit Verified  

---

## 1. Audit Conclusion & Classification

### Audit Determination: **B. Partially Hard-Coded in Business Logic Layer with Static Trainer Defaults**

The current implementation in Stage 1 contains the foundational entity fields for policy types, but the calculation and deduction logic in the action layer is **partially hard-coded**, and **no interactive settings UI** is currently exposed for trainers or gym managers to customize these values dynamically.

---

## 2. Code Inspection & Current Implementation Findings

### 2.1 Entity Model (`app/src/state/seed-data.js`)
```javascript
// Seed Data: Trainer Entity
{
  id: 'trn-alex',
  cancellation_policy: 'FOUR_HOUR_POLICY',  // Static Enum
  custom_cancellation_hours: 4,             // Fixed 4 hours
  // Missing fields:
  // - penalty_enabled (boolean)
  // - late_cancellation_credits_deducted (number)
}
```

### 2.2 Execution Logic (`app/src/state/actions.js:195-224`)
```javascript
cancelSession(sessionId, cancelledBy = 'CLIENT', reason = '') {
  const state = store.getState();
  const session = state.sessions.find(s => s.id === sessionId);
  if (!session) return;

  const trainer = state.trainers.find(t => t.id === session.trainer_id);
  const sessionTime = new Date(session.scheduled_start).getTime();
  const now = new Date().getTime();
  const hoursUntilSession = (sessionTime - now) / (1000 * 60 * 60);

  session.status = 'CANCELLED';
  session.cancelled_at = new Date().toISOString();
  session.cancel_reason = reason;

  // HARD-CODED EVALUATION: Checks string 'FOUR_HOUR_POLICY' and hard-coded literal '4'
  const isPenalty = trainer && trainer.cancellation_policy === 'FOUR_HOUR_POLICY' && hoursUntilSession < 4;

  // HARD-CODED DEDUCTION: Fixed literal 1 credit deduction
  if (isPenalty && session.session_type === 'PERSONAL_TRAINING' && !session.credit_consumed) {
    session.credit_consumed = true;
    const clientPkg = state.client_packages.find(cp => cp.id === session.client_package_id);
    if (clientPkg && clientPkg.remaining_sessions > 0) {
      clientPkg.remaining_sessions -= 1; // Fixed 1 credit
    }
  }
}
```

### 2.3 UI Representation (`app/src/views/trainer/TrainerCalendarView.js`)
- Displays a static badge `<span class="badge badge-primary">4-Hr Policy</span>`.
- Does not provide an editable modal or form to modify cancellation rules.

---

## 3. Required Changes for Full Configurability (Stage 1.5 / Stage 2)

To make the cancellation engine completely configurable across independent trainers and gym organizations, three architectural updates are required:

### Change 1: Extend Data Model Schema

Update the `trainer` and `gym` schema to support granular policy objects:

```json
{
  "cancellation_policy": {
    "policy_type": "CUSTOM",                // "NO_PENALTY" | "STANDARD_4_HOUR" | "CUSTOM"
    "penalty_enabled": true,                // Toggle penalty on/off
    "grace_period_hours": 4,                // Configurable: 2, 4, 8, 12, 24, 48 hours
    "credits_deducted": 1,                  // Number of credits deducted on late cancellation (e.g. 1, 2)
    "allow_client_reschedule_window_hours": 2, // Cutoff before which client can reschedule penalty-free
    "gym_override_allowed": false           // If true, gym policy supersedes individual trainer policy
  }
}
```

### Change 2: Dynamic Action Evaluation Engine (`actions.js`)

Replace hard-coded literals with dynamic policy parameters:

```javascript
evaluateSessionCancellation(sessionId, cancelledByRole, reason) {
  const session = store.getSession(sessionId);
  const trainer = store.getTrainer(session.trainer_id);
  const policy = trainer.cancellation_policy || { penalty_enabled: false, grace_period_hours: 0, credits_deducted: 0 };

  const hoursUntilStart = (new Date(session.scheduled_start) - new Date()) / (1000 * 60 * 60);

  // Dynamic penalty condition
  const isLateCancellation = policy.penalty_enabled && (hoursUntilStart < policy.grace_period_hours);
  const deductionAmount = isLateCancellation ? (policy.credits_deducted || 1) : 0;

  if (deductionAmount > 0 && session.session_type === 'PERSONAL_TRAINING' && !session.credit_consumed) {
    session.credit_consumed = true;
    session.penalty_applied = true;
    session.penalty_credits_deducted = deductionAmount;
    
    // Execute ledger deduction
    CreditLedger.recordDeduction(session.client_package_id, deductionAmount, 'LATE_CANCELLATION_PENALTY', session.id);
  } else {
    session.penalty_applied = false;
    session.penalty_credits_deducted = 0;
  }
}
```

### Change 3: Trainer & Gym Configuration UI

Add a **Cancellation Policy Settings** section inside `TrainerSettings` / `TrainerCalendarView`:
1. **Policy Mode Selector**: Radio cards for *No Penalty (Flexible)*, *Standard 4-Hour*, and *Custom Policy*.
2. **Grace Period Stepper**: Numeric input allowing custom cutoff threshold ($0$ to $72$ hours).
3. **Penalty Deduction Configurator**: Numeric dropdown defining credits consumed on late cancellation ($1$ credit standard, custom integer).
4. **Client-Facing Policy Disclosure**: Automatic preview card shown to clients on the booking confirmation screen informing them of the trainer's active cancellation window.
