# Stage 1 Implementation Plan: Interactive High-Fidelity Prototype

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 1.0  
**Phase:** Stage 1 – Interactive Frontend Prototype with In-Memory Mock Data  
**Target Completion:** Ready for Stakeholder Walkthrough & UX Validation  

---

## 1. Scope & Core Constraints for Stage 1

In accordance with solution architecture guidelines, Stage 1 will deliver a **fully functional, interactive mobile-first prototype** running locally without external backend dependencies.

### Strict Boundaries:
- 🚫 **No Supabase / Remote DB**: All data structures live in a reactive in-memory state repository.
- 🚫 **No Live SMS / OAuth Gateways**: Instant simulated OTP verification and one-click role switching.
- 🚫 **No Real Payment Gateways**: Offline payment workflow with simulated transaction IDs and trainer verification.
- 🚫 **No External Push Notification Services**: Interactive in-app notification center and live badge simulation.
- ✅ **Realistic Mock Data**: Pre-seeded with 5 authentic user accounts across all roles, 100+ exercises, sample workout templates, booked sessions, and historical progress charts.
- ✅ **Complete Business Logic Simulation**: Credit deduction upon session completion, 4-hour cancellation rule evaluation, capacity limits, and role permission guards.

---

## 2. Priority Phase: Primary End-to-End Validation Flow

Before implementing secondary screens, the **Primary Core Journey** will be constructed and validated end-to-end:

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

---

## 3. Product Rules & Gating Matrix

1. **Advanced Trainer Search**:
   - Default search: By name, verified trainer list, QR code scanner, 6-character trainer code.
   - Advanced filters (Specialization, Location, Experience, Price, Language, Gender) are gated behind feature flag **`advanced_trainer_search`** (default: `false`).
2. **Client Personal Information**:
   - Health information, injuries, and medical history are strictly **optional** during onboarding.
   - Requires client to explicitly enable **"Share with my trainer"** to grant trainer read access.
   - Respects feature flag **`client_personal_information`** (default: `true`).
3. **Package Validity**:
   - Suggests `sessions * 4` as default calculation.
   - Trainer can freely select preset durations (30, 45, 60, 90 days) or enter any **custom days**.
4. **Package Payment Verification**:
   - No automatic activation upon purchase.
   - Enters `PENDING_VERIFICATION` upon client clicking "I Have Paid".
   - Activated only when Trainer clicks "Verify Payment".
5. **Session Credit Rule**:
   - Deducted **ONLY** upon session completion.
   - 0 credits deducted on booking.
   - "Own Workouts" **never** deduct credits.
   - Cancelled / rescheduled sessions only deduct credit if penalty cancellation policy applies.
6. **Trainer Discovery**:
   - Only **verified trainers** appear in public search and directory.
   - Unverified trainers can access all app features and manage clients via direct QR/code.

---

## 4. Implementation Milestones

### Milestone 1: App Foundation, Design System & Theme Engine
- Scaffolding in `app/` with clean architecture structure.
- Dark and Light theme configurations with dynamic switcher.
- Core UI library: `FitnessCard`, `MetricTile`, `StatGauge`, `WorkoutCard`, `SessionBadge`, `CustomButton`, `CustomTextField`, `PillFilterBar`.
- Floating Role Switcher HUD (`SUPER_ADMIN`, `GYM_MANAGER`, `HEAD_TRAINER`, `TRAINER`, `CLIENT`).

### Milestone 2: Domain Models, Mock Repository & Rich Seed Fixtures
- In-memory reactive state repositories.
- 5 Test Accounts (`admin@test.local`, `gymmanager@test.local`, `headtrainer@test.local`, `trainer@test.local`, `client@test.local`).
- 100+ standard global exercises with categorized muscle groups.
- Seed data fixtures for verified trainers, packages, bookings, and workout routines.

### Milestone 3: Auth, Role Selection & Onboarding Flow Simulator
- Splash screen, test account quick-login, and auto-fill OTP simulator (`123456`).
- Trainer Onboarding Wizard (Bio, Certifications, Specializations, Working Hours, Suggested Validity).
- Client Onboarding Wizard (Fitness Goals, Optional Health Data, Trainer Sharing Toggle).

### Milestone 4: Client Core Experience & Primary Flow
- Trainer Discovery (Name search, QR Scanner, Trainer Code, Verified Badge filter).
- Consultation request flow.
- Package selection with custom validity support & Offline UPI payment modal.
- Calendar session booking with live capacity and credit balance checks.
- Live interactive workout tracker with set/rep/weight logging and rest stopwatch.
- Client "Own Workout" builder with clear 0-credit badges.
- Progress metrics, weight trend charts, and optional photo gallery.

### Milestone 5: Trainer Command Center & Session Execution
- Trainer dashboard with daily briefing, pending request counters, and low-credit alerts.
- Inbound request approval & offline payment verification console.
- Calendar & scheduling manager with session confirmation, rescheduling, and cancellation rules.
- Workout builder & exercise catalog with custom exercise creator.
- Live session execution console (Start Session, Log Exercise Sets/Reps/Weight, Mark Complete).

### Milestone 6: Gym Manager & Head Trainer Console
- Multi-tenant gym dashboard with trainer roster and utilization rates.
- Head Trainer client reassignment console (preserving historical workout logs).
- Facility master calendar and aggregate financial reports.

### Milestone 7: Super Admin & Feature Flag Console
- Global platform health dashboard and trainer verification queue.
- Runtime Feature Flags console (`advanced_trainer_search`, `online_payments`, `client_personal_information`, `trainer_reviews`, `whatsapp_notifications`).

### Milestone 8: Cross-Role E2E Verification & Polish
- Full validation of the primary end-to-end journey.
- Edge case testing (zero credit block, cancellation cutoff, privacy opt-in check).
- Final walkthrough documentation with screenshots and user flows.
