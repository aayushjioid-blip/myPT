# Business Rules, Validation Logic & Edge Cases

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 1.0  
**Status:** MVP Specification & Business Logic Reference (Updated with Core Rule Corrections)  

This document serves as the authoritative source for all business rules, domain validation logic, credit consumption mechanics, and identified specification ambiguities with recommended resolutions.

---

## 1. Core Platform Principles

1. **Trainer-First Hierarchy**: The platform is built around the trainer rather than the gym. Independent trainers require zero gym associations to operate fully.
2. **Dual-Affiliation Capabilities**: A trainer can operate independently while maintaining active affiliations with one or more gyms.
3. **Mandatory Relationship for Personal Training**: Clients must have an accepted trainer relationship before purchasing packages, booking sessions, or accessing trainer-assigned workouts.
4. **Client Switching Restrictions**:
   - Clients of independent trainers cannot independently switch trainers.
   - Gym management (Head Trainer / Gym Manager) has exclusive authority to reassign gym-affiliated clients.
5. **Credit Integrity**: Completed PT sessions consume exactly 1 package credit. Client "Own Workouts" **never** consume credits under any circumstance. Credits are never deducted upon booking.
6. **Cancellation Grace Periods**: Cancelled sessions do not consume credits unless explicitly mandated by the trainer's active cancellation policy (e.g. 4-hour cutoff rule).
7. **Database-Level Enforcement**: Authorization and data privacy rules must be strictly guaranteed at the database / RLS level.
8. **Feature Flag Extensibility**: Future capabilities (online payments, WhatsApp notifications, advanced discovery) are controlled via Super Admin feature flags without requiring structural redesigns.

---

## 2. Role Permissions & Scope Matrix

| Role | Scope | Key Capabilities | Restricted Actions |
| :--- | :--- | :--- | :--- |
| **`SUPER_ADMIN`** | `GLOBAL` | Manage all entities, toggle feature flags, verify trainers, review audit logs. | Cannot take sessions as a client. |
| **`GYM_MANAGER`** | `GYM` | Manage gym profile, invite trainers, reassign clients, view gym financial aggregates. | Cannot view client medical info without consent; cannot log workouts. |
| **`HEAD_TRAINER`** | `GYM` | Oversee gym trainers, assign incoming clients, build gym-wide workout templates. | Cannot reassign clients outside own gym. |
| **`TRAINER`** | `TRAINER_OR_GYM` | Build custom packages, configure capacity & availability, program workouts, log sessions, verify payments. | Cannot access unassigned clients' data; cannot appear in public discovery if unverified. |
| **`CLIENT`** | `SELF` | Discover verified trainers, request consultation, purchase packages, book sessions, log assigned/own workouts, log metrics. | Cannot book PT sessions with zero remaining credits. |

---

## 3. Trainer Discovery & Verification Rules

1. **Verified Trainers**:
   - Displayed in public trainer search and public directory.
   - Searchable by name.
   - Can share QR code and unique trainer code.
2. **Unverified Trainers**:
   - Can fully use the application, configure packages, manage workouts, and train clients.
   - **Must NOT appear** in public trainer search or directory.
   - Clients can only connect to unverified trainers via direct QR scan or entering the trainer's unique 6-character code.
3. **Advanced Trainer Search Filter Rule**:
   - **Default discovery methods**: Search by name, Browse verified trainers list, Scan QR code, Enter trainer code.
   - **Advanced filters** (Specialization, Location, Experience, Price range, Language, Gender) are strictly gated behind the feature flag **`advanced_trainer_search`**.
   - Default feature flag state: `false` (Hidden). Only visible when enabled by Super Admin.

---

## 4. Client Personal Information & Privacy

1. **Strictly Optional Onboarding**:
   - Health information, medical history, past injuries, dietary info, and emergency contact are **never mandatory** during onboarding.
   - Clients freely choose whether to fill in any or all optional fields.
2. **Explicit Trainer Sharing Opt-In**:
   - Personal health data remains private to the client by default.
   - Client must explicitly toggle **"Share with my trainer"**.
   - Only when opted-in can the assigned trainer view this information.
   - Controlled globally by the Super Admin feature flag `client_personal_information` (default: `true`).

---

## 5. Package & Validity Computation Rules

### 5.1 Package Definition
- Created by: `TRAINER` (custom packages) or `HEAD_TRAINER` (gym packages).
- Fields: Name, Description, Number of Sessions, Price, Validity Days, Session Duration, Status (`DRAFT`, `ACTIVE`, `INACTIVE`, `EXPIRED`, `SOLD_OUT`).

### 5.2 Validity Calculation & Customization
- **Suggested Default Formula**:
  $$\text{Suggested Validity Days} = \text{Number of Sessions} \times 4$$
  *(e.g., 10 sessions $\to$ Suggested 40 days)*
- **Manual & Custom Overrides**:
  - The formula is a suggestion, **not a forced constraint**.
  - Trainer can manually choose alternative presets (e.g., 30, 45, 60, 90 days) or enter any **custom number of days**.

### 5.3 Package Purchase & Verification Flow (Step-by-Step)
Packages are **never activated immediately** upon clicking purchase:
1. Client views trainer profile and packages.
2. Client sends **Consultation / Interest Request**.
3. Trainer accepts the client and approves client for package purchase.
4. Client selects package.
5. Client views trainer's offline payment details (`UPI ID` / `Mobile Number`).
6. Client makes payment externally (via their UPI/banking app).
7. Client clicks **"I Have Paid"** and submits transaction reference.
8. Payment status becomes **`PENDING_VERIFICATION`** (Package status: `PENDING_PAYMENT`).
9. Trainer verifies the received payment (or rejects with reason).
10. **Only upon trainer verification is the package activated** with `remaining_sessions = total_sessions`.

---

## 6. Session Booking & Credit Consumption Logic

### 6.1 Booking Preconditions
A booking request can only be submitted if:
1. `ACTIVE_TRAINER_RELATIONSHIP`: Client has an accepted trainer.
2. `ACTIVE_PACKAGE`: Client has a verified, non-expired package.
3. `REMAINING_SESSIONS > 0`: Credit balance $\ge 1$.
4. `TRAINER_AVAILABLE`: Slot falls within trainer's working hours and is not blocked.
5. `CAPACITY_AVAILABLE`: Booked count for slot < configured capacity.

### 6.2 Credit Deduction Execution
- **At Booking Request**: **0 credits deducted** (status: `REQUESTED` $\to$ `CONFIRMED`).
- **During Session**: **0 credits deducted** (status: `IN_PROGRESS`).
- **At Session Completion**: **Exactly 1 credit deducted** when trainer or client marks session `COMPLETED`.
- **Own Workouts**: **0 credits deducted** (completely free self-logged workout).
- **Cancellations & Rescheduling**:
  - Rescheduled: 0 credits deducted.
  - Cancelled $\ge 4$ hours (under `FOUR_HOUR_POLICY`): 0 credits deducted.
  - Cancelled $< 4$ hours (under `FOUR_HOUR_POLICY`): 1 credit deducted as penalty.
  - Cancelled under `NO_PENALTY`: 0 credits deducted.

---

## 7. Cancellation Policy Options

Trainers configure one of three cancellation policies:
1. **`NO_PENALTY` (Default)**: Client can cancel at any time prior to session start without credit penalty.
2. **`FOUR_HOUR_POLICY`**:
   - Cancelled $\ge 4$ hours prior to start: **No credit penalty** (`credit_consumed: false`).
   - Cancelled $< 4$ hours prior to start: **1 credit consumed** (`credit_consumed: true`).
3. **`CUSTOM`**: Trainer specifies cutoff threshold (e.g., 2, 8, 12, or 24 hours). Same deduction logic applies relative to the cutoff window.

---

## 8. Prioritized Implementation Sequence

The primary end-to-end user journey is built and verified first before secondary modules:

```
[CLIENT] Discovery & Profile ──► Send Consultation Request
                                         │
                                         ▼
[TRAINER] Inbound Request ──────► Accept & Approve Client
                                         │
                                         ▼
[CLIENT] Select Package ────────► Submit Mock Offline Payment ("I Have Paid")
                                         │
                                         ▼
[TRAINER] Payment Queue ────────► Verify Payment Received
                                         │
                                         ▼
[SYSTEM] Activate Package ──────► Set Remaining Sessions = 10
                                         │
                                         ▼
[CLIENT] Calendar ──────────────► Request Session Booking
                                         │
                                         ▼
[TRAINER] Calendar ─────────────► Accept Booking Request
                                         │
                                         ▼
[TRAINER] Session Live ─────────► Start Session ──► Log Sets, Reps & Weight ──► Complete Session
                                         │
                                         ▼
[SYSTEM] Balance Update ────────► Remaining Sessions decrements: 10 ──► 9
                                         │
                                         ▼
[CLIENT] Dashboard & History ───► Verified updated balance (9) and logged workout details!
```
