# Flutter Foundation & Prototype Migration Plan (Stage 1.5)

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 1.0  
**Target Platform:** Mobile-First (Android & iOS) with Web Preview  
**Phase:** Stage 1.5 — Flutter Foundation & Clean Architecture Migration  
**Date:** August 31, 2026  

---

## 1. Executive Summary & Objective

FitTrainer's validated UI/UX and business rules from the Stage 1 web reference prototype are being systematically rebuilt as a **production-grade Flutter/Dart application**.

### Core Tenets:
1. **Target Platforms**: Native Android & iOS with responsive layout capabilities.
2. **Backend-Decoupled Clean Architecture**: Strict 4-layer separation (`core/`, `domain/`, `data/`, `features/`).
3. **Pure Mock Repository Layer**: No external backend (Supabase/Firebase) integrated in Stage 1.5; all repositories implement abstract domain contracts using in-memory reactive state.
4. **Append-Only Credit Ledger Preparation**: Architecture models session credit changes as ledger transactions rather than mutable balance integers.
5. **Configurable Cancellation Engine**: Domain logic supports dynamic grace hours, penalty toggles, and deduction amounts.
6. **Demo Mode Role Switcher**: Interactive 5-role persona switcher (`CLIENT`, `TRAINER`, `HEAD_TRAINER`, `GYM_MANAGER`, `SUPER_ADMIN`) built as a development overlay.

---

## 2. Phase-by-Phase Migration Sequence

```
PHASE 1: FOUNDATION (Current Focus)
  ├── Flutter Project Scaffolding & pubspec.yaml
  ├── Theme Engine (Dark & Light Mode, Fitness Color Palette, Typography)
  ├── Design System (FitnessCard, MetricTile, StatGauge, CustomButton, Inputs, Badges)
  ├── Core Data & Domain Layer (Entities, Abstract Repositories, Mock Fixtures)
  ├── State Management (Provider / ChangeNotifier Clean Architecture)
  └── Demo Role Switcher HUD & App Shell

PHASE 2: CORE E2E PERSONAL TRAINING JOURNEY
  ├── Discovery & Trainer Public Profile
  ├── Consultation Request & Trainer Acceptance
  ├── Package Purchase & Mock Offline Payment Verification
  ├── Session Booking with Zero-Credit Deduction on Booking
  └── Workout Execution & Session Completion with Exactly 1 Credit Deducted

PHASE 3: CLIENT EXPERIENCE MODULES
  ├── Client Dashboard & Progress Metrics (8-Point Circumference & BMI)
  ├── Privacy Shield (Explicit "Share with my trainer" Opt-in)
  ├── Own Workout Builder (Guaranteed 0 PT Credit Deduction)
  └── In-App Notification Center & Review Submission

PHASE 4: TRAINER EXPERIENCE MODULES
  ├── Client Roster & 360 Progress View
  ├── 12-Category Exercise Library & Custom Exercise Creator
  ├── Workout Template Manager (Create, Edit, Assign to Client)
  └── Advanced Calendar (Working Hours, Capacity Limits & Recurring Bookings)

PHASE 5: GYM ORGANIZATION HIERARCHY
  ├── Head Trainer Console & Client Reassignment Engine (Preserving Workout Logs & Credits)
  └── Gym Manager Facility Management & Multi-Gym Affiliations

PHASE 6: SUPER ADMIN & FEATURE FLAGS
  ├── User Directory & Trainer Verification Queue (Gating Public Search)
  └── Runtime Feature Flags (`advanced_trainer_search`, `client_personal_information`)
```

---

## 3. Strict Quality & Business Rule Verification Matrix

| Domain Rule | Enforcement in Flutter Architecture |
| :--- | :--- |
| **Zero-Credit Own Workouts** | Domain service `CreditLedgerService` enforces credit deduction = 0 for `WorkoutType.ownWorkout`. |
| **Credit Consumption on Completion Only** | 0 credits deducted on booking request; exactly 1 credit deducted when session status transitions to `completed`. |
| **Medical & Health Privacy Shield** | `ClientHealthProfile` entity is only exposed to trainer if `user.sharePersonalInfoWithTrainer == true`. |
| **Unverified Trainer Gating** | Discovery repository filters `trainer.verificationStatus == VerificationStatus.verified` for public queries. |
| **Configurable Cancellation Policy** | `CancellationPolicy` model supports `gracePeriodHours`, `penaltyEnabled`, and `creditsDeducted`. |
