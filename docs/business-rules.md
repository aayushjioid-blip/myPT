# Business Rules, Validation Logic & Edge Cases

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 1.0  
**Status:** MVP Specification & Business Logic Reference  

This document serves as the authoritative source for all business rules, domain validation logic, credit consumption mechanics, and identified specification ambiguities with recommended resolutions.

---

## 1. Core Platform Principles

1. **Trainer-First Hierarchy**: The platform is built around the trainer rather than the gym. Independent trainers require zero gym associations to operate fully.
2. **Dual-Affiliation Capabilities**: A trainer can operate independently while maintaining active affiliations with one or more gyms.
3. **Mandatory Relationship for Personal Training**: Clients must have an accepted trainer relationship before purchasing packages, booking sessions, or accessing trainer-assigned workouts.
4. **Client Switching Restrictions**:
   - Clients of independent trainers cannot independently switch trainers.
   - Gym management (Head Trainer / Gym Manager) has exclusive authority to reassign gym-affiliated clients.
5. **Credit Integrity**: Completed PT sessions consume exactly 1 package credit. Client "Own Workouts" **never** consume credits under any circumstance.
6. **Cancellation Grace Periods**: Cancelled sessions do not consume credits unless explicitly mandated by the trainer's active cancellation policy.
7. **Database-Level Enforcement**: Authorization and data privacy rules must be strictly guaranteed at the database / RLS level.
8. **Feature Flag Extensibility**: Future capabilities (online payments, WhatsApp notifications, advanced discovery) are controlled via Super Admin feature flags without requiring structural redesigns.

---

## 2. Role Permissions & Scope Matrix

| Role | Scope | Key Capabilities | Restricted Actions |
| :--- | :--- | :--- | :--- |
| **`SUPER_ADMIN`** | `GLOBAL` | Manage all entities, toggle feature flags, verify trainers, review audit logs. | Cannot take sessions as a client. |
| **`GYM_MANAGER`** | `GYM` | Manage gym profile, invite trainers, reassign clients, view gym financial aggregates. | Cannot view client medical info without consent; cannot log workouts. |
| **`HEAD_TRAINER`** | `GYM` | Oversee gym trainers, assign incoming clients, build gym-wide workout templates. | Cannot reassign clients outside own gym. |
| **`TRAINER`** | `TRAINER_OR_GYM` | Build custom packages, configure capacity & availability, program workouts, log sessions, verify payments. | Cannot access unassigned clients' data. |
| **`CLIENT`** | `SELF` | Discover verified trainers, request consultation, purchase packages, book sessions, log assigned/own workouts, log metrics. | Cannot book PT sessions with zero remaining credits. |

---

## 3. Package & Validity Computation Rules

### 3.1 Package Definition
- Created by: `TRAINER` (custom packages) or `HEAD_TRAINER` (gym packages).
- Statuses: `DRAFT`, `ACTIVE`, `INACTIVE`, `EXPIRED`, `SOLD_OUT`.

### 3.2 Validity Calculation Modes
1. **`SESSIONS_MULTIPLIED_BY_4` (Default)**:
   $$\text{Validity Days} = \text{Number of Sessions} \times 4$$
   *(e.g., 10 sessions = 40 days validity)*
2. **`SESSIONS_MULTIPLIED_BY_3`**:
   $$\text{Validity Days} = \text{Number of Sessions} \times 3$$
   *(e.g., 10 sessions = 30 days validity)*
3. **`FIXED_DAYS`**:
   $$\text{Validity Days} = \text{Explicit Fixed Value (e.g., 30, 60, 90, 180 days)}$$
4. **`CUSTOM`**:
   Trainer specifies an exact expiration date or duration.

### 3.3 Purchase & Activation Preconditions
- Client must have an active relationship (`relationship_status == 'ACCEPTED'`).
- Package must have `status == 'ACTIVE'`.
- Upon offline payment submission, package is in `PENDING_PAYMENT` / `VERIFICATION_REQUIRED`.
- Package activates (`status == 'ACTIVE'`, `remaining_sessions == total_sessions`) immediately upon trainer verification.

---

## 4. Session Booking & Credit Consumption Logic

### 4.1 Booking Preconditions
A booking request can only be submitted if all 5 conditions evaluate to `true`:
1. `ACTIVE_TRAINER_RELATIONSHIP`: Client is assigned to the trainer.
2. `ACTIVE_PACKAGE`: Client has a valid, non-expired package.
3. `REMAINING_SESSIONS > 0`: Credit balance is at least 1.
4. `TRAINER_AVAILABLE`: Slot falls within trainer's working hours and is not blocked.
5. `CAPACITY_AVAILABLE`: Current booked count for the slot < configured slot capacity.

### 4.2 Credit Ledger Matrix
| Event / Outcome | Credit Deducted? | Package Balance Change | Session Status |
| :--- | :---: | :---: | :--- |
| **Session Marked Completed** | **YES** | $\text{Remaining} \leftarrow \text{Remaining} - 1$ | `COMPLETED` |
| **Cancelled within Grace Period** | **NO** | No change | `CANCELLED` |
| **Cancelled Late (Inside Penalty Window)** | **YES** | $\text{Remaining} \leftarrow \text{Remaining} - 1$ | `CANCELLED` (Penalty) |
| **Trainer Cancels Session** | **NO** | No change (Restored if held) | `CANCELLED` |
| **Rescheduled Session** | **NO** | No change | `RESCHEDULED` |
| **Trainer No-Show** | **NO** | No change | `NO_SHOW` (Trainer) |
| **Client "Own Workout" Logged** | **NO** | No change (Strictly 0 credits) | `COMPLETED` (`OWN_WORKOUT`) |

---

## 5. Cancellation Policy Options

Trainers configure one of three cancellation policies:
1. **`NO_PENALTY` (Default)**: Client can cancel at any time prior to session start without losing a credit.
2. **`FOUR_HOUR_POLICY`**:
   - Cancelled $\ge 4$ hours prior to start: **No credit penalty** (`credit_consumed: false`).
   - Cancelled $< 4$ hours prior to start: **1 credit consumed** (`credit_consumed: true`).
3. **`CUSTOM`**: Trainer specifies cutoff threshold (e.g., 2, 8, 12, or 24 hours). Same deduction logic applies relative to the cutoff window.

---

## 6. Workouts & Exercise System Rules

1. **Exercise Database**:
   - Global catalog (`is_global == true`) accessible to all trainers and clients.
   - Trainer-created custom exercises (`is_global == false`) accessible only to the creating trainer and their assigned clients.
2. **Workout Templates**:
   - Reusable templates can be cloned into an assigned workout.
3. **Workout Execution**:
   - Client or trainer can record sets, reps, weight, duration, rest times, and notes.
   - Historical logs are immutable records.
4. **"Own Workouts"**:
   - Clients can independently build and log workouts.
   - Always flagged as `workout_type == 'OWN_WORKOUT'`.
   - Never interacts with PT session packages or credit balances.

---

## 7. Progress Tracking & Privacy Rules

1. **Metrics**: Weight, Height, BMI, Body Fat %, Circumference measurements (Chest, Waist, Hips, Biceps, Thighs, Calves, Neck).
2. **Progress Photos**:
   - Optional, stored in private storage.
   - Accessible only by the client and their active trainer.
3. **Medical & Personal Information Sharing**:
   - Client medical history, injuries, and emergency contact details are **shielded by default**.
   - Only shared if the client explicitly opts in (`share_personal_info_with_trainer == true`).

---

## 8. Trial & Feature Flag Governance

1. **Trial Period**:
   - Free trial duration defaults to 365 days.
   - Payment method is not required upfront by default (`trial_payment_requirement == false`).
2. **Feature Flags**:
   - `advanced_trainer_search`: Default `false`.
   - `online_payments`: Default `false` (MVP relies on offline UPI/Cash verification).
   - `trial_payment_requirement`: Default `false`.
   - `client_personal_information`: Default `true`.
   - `trainer_reviews`: Default `true` (Requires $\ge 1$ completed PT session to submit review).
   - `whatsapp_notifications`: Default `false`.
   - `subscription_enforcement`: Default `false`.

---

## 9. Ambiguities, Contradictions, Edge Cases & Recommendations

Below is a detailed analysis of all identified ambiguities, edge cases, and potential conflicts in the specification, along with possible options and recommended resolutions.

---

### Ambiguity 1: Multiple Gym Affiliations vs Single Primary Relationship
- **Context**: The specification allows a trainer to belong to multiple gyms simultaneously while maintaining independent clients. However, the client relationship model specifies `initial_relationship: "ONE_ACTIVE_TRAINER"`.
- **Conflict/Question**: When a client connects with a trainer who works at Gym A and Gym B and also trains independently, which entity owns the relationship and who has reassignment rights?
- **Options**:
  - *Option A (Recommended)*: Store an optional `gym_id` on the `client_trainer_relationships` record. If `gym_id` is null, it is an **Independent Relationship** (no gym manager can reassign). If `gym_id` is present, it is a **Gym Relationship** (Head Trainer / Gym Manager of that gym can reassign).
  - *Option B*: Force trainers to have separate trainer accounts for each gym.
- **Recommendation**: **Option A**. It preserves trainer-first flexibility without compromising gym management capabilities.

---

### Ambiguity 2: Expired Packages with Remaining Sessions
- **Context**: A client purchases 10 sessions with 40-day validity. On day 41, the client still has 3 remaining sessions.
- **Conflict/Question**: Are the remaining sessions permanently forfeited, or can the trainer extend validity?
- **Options**:
  - *Option A*: Hard expiration — system strictly blocks booking once `expiry_date` passes.
  - *Option B (Recommended)*: Automated expiration blocks new client bookings, but provides the trainer with a **"Grant Validity Extension"** toggle to extend the expiration date by a custom number of days.
  - *Option C*: Sessions never expire.
- **Recommendation**: **Option B**. Prevents disputes, maintains trainer autonomy, and accommodates real-world client circumstances (e.g., illness or travel).

---

### Ambiguity 3: Consultation Request vs Direct Relationship Creation
- **Context**: In `consultation_flow`, the steps are: `CLIENT_CLICKS_INTERESTED -> CONSULTATION_REQUEST_CREATED -> TRAINER_ACCEPTS -> DISCUSS -> APPROVES_CLIENT -> SELECTS_PACKAGE`. In `client_trainer_relationship`, states are `REQUESTED, PENDING, ACCEPTED, REJECTED...`.
- **Conflict/Question**: Is a Consultation Request a separate entity or part of the `client_trainer_relationships` state machine?
- **Options**:
  - *Option A (Recommended)*: Unified model — Requesting a consultation creates a `client_trainer_relationships` record in `REQUESTED` state. When the trainer accepts, it moves to `ACCEPTED`, unlocking package purchases.
  - *Option B*: Create a separate `consultation_requests` table that must be converted into a `client_trainer_relationship` upon approval.
- **Recommendation**: **Option A**. Eliminates redundant tables and state synchronization issues in the MVP.

---

### Ambiguity 4: Late Cancellation Credit Attribution in Financial Reports
- **Context**: When a client cancels $<4$ hours before session start under `FOUR_HOUR_POLICY`, 1 session credit is deducted.
- **Conflict/Question**: Does this count as a `completed_session` in trainer analytics and financial payout dashboards?
- **Options**:
  - *Option A (Recommended)*: Session status is recorded as `CANCELLED` with `credit_consumed = true`. In analytics, it is classified under `"Late Cancelled (Billed)"` so it reflects in earned revenue without skewing workout completion rates.
  - *Option B*: Overwrite status to `COMPLETED`.
- **Recommendation**: **Option A**. Maintains audit accuracy between workout logs and financial ledger.

---

### Ambiguity 5: Offline Payment Rejection Handling
- **Context**: Client submits payment reference (UTR/UPI ID). Trainer reviews and finds payment was not received.
- **Conflict/Question**: What happens to the pending package when a trainer rejects the payment?
- **Options**:
  - *Option A (Recommended)*: Payment status updates to `REJECTED` with an optional trainer rejection reason note. The client receives a notification and can update the transaction reference or retry without having to re-create the package selection.
  - *Option B*: Permanently delete the package and payment records.
- **Recommendation**: **Option A**. Better UX and preserves audit history.

---

### Ambiguity 6: Trainer Capacity Conflicts Across Time Slots
- **Context**: A trainer sets a capacity of 2 clients for the 18:00–19:00 slot.
- **Conflict/Question**: Can 1 slot be booked for an Independent client and 1 slot for a Gym client at the same time?
- **Options**:
  - *Option A (Recommended)*: Unified trainer capacity counter. Total concurrent active sessions across all sources (independent + gym) cannot exceed the trainer's slot capacity.
  - *Option B*: Separate capacity schedules for gym and independent.
- **Recommendation**: **Option A**. Prevents double-booking and physical burnout.
