# System Architecture & Technical Blueprint

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 1.0  
**Status:** MVP Architectural Specification & Stage 1 Blueprint  
**Primary Target:** Cross-Platform Mobile Application (Flutter) & Web Management Portal  

---

## 1. Executive Summary & Architectural Goals

FitTrainer is engineered as a **trainer-first, multi-tenant mobile and web platform** designed for independent personal trainers, with structural foundations for gym organizations, head trainers, trainers, and clients.

### Key Architectural Pillars
1. **Trainer-First Autonomy**: Independent trainers operate as autonomous business units with their own client rosters, custom packages, availability calendars, and workout programming.
2. **Multi-Tenant Scalability**: Future-ready organizational hierarchy supporting single-gym and multi-gym associations for trainers and head trainers without breaking independent workflows.
3. **Strict Data Isolation (RLS)**: Row-Level Security at the database layer enforcing explicit access boundaries for personal health data, body measurements, progress photos, and financial records.
4. **Offline-Tolerant & Mobile-Centric UX**: Fluid mobile performance prioritizing quick in-gym workout logging, session tracking, and instant scheduling.
5. **Decoupled Architecture (Stage 1 Simulation $\to$ Stage 2 Supabase Target)**: Modular layered structure allowing Stage 1 mock state repositories to be replaced seamlessly with live Supabase client implementations.

---

## 2. High-Level System Architecture

```
                                  ┌─────────────────────────────────────────────────────────┐
                                  │                  CLIENT LAYER (UI / UX)                 │
                                  ├────────────────────────────┬────────────────────────────┤
                                  │   Flutter Mobile App       │    Next.js Web Portal      │
                                  │   (iOS & Android)          │    (Admin & Gym Analytics) │
                                  └─────────────┬──────────────┴─────────────┬──────────────┘
                                                │                            │
                                                │                            │
                     ┌──────────────────────────▼────────────────────────────▼──────────────────────────┐
                     │                           DOMAIN & BUSINESS LOGIC LAYER                          │
                     ├──────────────────────────────────────────────────────────────────────────────────┤
                     │  • Auth & Session Context Service    • Workout & Exercise Engine                │
                     │  • Relationship & Consultation State • Booking & Capacity Validator             │
                     │  • Package & Credit Ledger           • Progress & Metrics Calculator            │
                     │  • Cancellation Policy Evaluator     • Feature Flag & Permission Guard          │
                     └──────────────────────────┬────────────────────────────┬──────────────────────────┘
                                                │                            │
         ┌──────────────────────────────────────┴──────────────┐             │
         │ STAGE 1: MOCK IMPLEMENTATION                        │             │ STAGE 2: PRODUCTION TARGET
         ▼                                                     │             ▼
┌──────────────────────────────────────────────┐               │    ┌───────────────────────────────────────────┐
│   IN-MEMORY / LOCAL REPOSITORY LAYER         │               │    │       SUPABASE PRODUCTION BACKEND         │
├──────────────────────────────────────────────┤               │    ├───────────────────────────────────────────┤
│ • MockAuthRepository (5 Test Profiles)       │               └───►│ • Supabase GoTrue Auth (OTP / OAuth)      │
│ • MockTrainerRepository                      │                    │ • PostgreSQL with Row-Level Security      │
│ • MockClientRepository                       │                    │ • Supabase Storage (Buckets for Photos)   │
│ • MockPackageRepository                      │                    │ • Realtime WebSocket Subscriptions        │
│ • MockBookingRepository                      │                    │ • Edge Functions (Payment Webhooks)       │
│ • MockWorkoutRepository & Exercise Seeds     │                    └───────────────────────────────────────────┘
│ • MockProgressRepository                     │
│ • MockFeatureFlagStore                       │
└──────────────────────────────────────────────┘
```

---

## 3. Frontend Architecture (Flutter Application)

The Flutter mobile application follows **Feature-Driven Clean Architecture** combined with reactive state management (Provider / Riverpod patterns).

### 3.1 Directory Structure
```
app/
├── lib/
│   ├── main.dart                          # Application entry point & theme initialization
│   ├── app.dart                           # Root MaterialApp, router configuration, global providers
│   │
│   ├── core/                              # Cross-cutting core infrastructure
│   │   ├── constants/                     # App constants, asset paths, layout constants
│   │   ├── theme/                         # Light & Dark theme data, typography, color tokens
│   │   ├── utils/                         # Date formatters, validators, calculations
│   │   ├── widgets/                       # Shared UI components (Cards, Buttons, Inputs, Loaders)
│   │   └── errors/                        # Exception definitions & failure handlers
│   │
│   ├── data/                              # Data access, mock stores & data sources
│   │   ├── models/                        # Immutable data transfer objects & domain entities
│   │   ├── datasources/                   # In-memory mock databases & seed data fixtures
│   │   │   ├── seed_users.dart            # Test accounts for all 5 roles
│   │   │   ├── seed_trainers.dart         # Verified/unverified trainers, bios, packages
│   │   │   ├── seed_exercises.dart        # 100+ global & custom exercise library
│   │   │   ├── seed_workouts.dart         # Sample assigned workouts & templates
│   │   │   ├── seed_bookings.dart         # Calendar sessions & capacity fixtures
│   │   │   ├── seed_progress.dart         # Measurement histories & photo records
│   │   │   └── seed_feature_flags.dart    # Super admin feature flag states
│   │   └── repositories/                  # Repository implementations (Mock for Stage 1)
│   │       ├── auth_repository.dart
│   │       ├── trainer_repository.dart
│   │       ├── client_repository.dart
│   │       ├── package_repository.dart
│   │       ├── booking_repository.dart
│   │       ├── workout_repository.dart
│   │       ├── progress_repository.dart
│   │       └── feature_flag_repository.dart
│   │
│   ├── domain/                            # Abstract contracts, domain rules & use cases
│   │   ├── entities/                      # Business entity definitions
│   │   └── repositories/                  # Abstract repository contracts
│   │
│   └── features/                          # Feature modules (UI & Feature-level state)
│       ├── auth/                          # Splash, Login, OTP, Role Selection, Test Account Switcher
│       ├── trainer_dashboard/             # Trainer Home, Client Roster, Stats, Pending Actions
│       ├── client_dashboard/              # Client Home, Today's Workout, Progress Snippet, Packages
│       ├── gym_dashboard/                 # Gym Manager & Head Trainer Console, Reassignments
│       ├── super_admin/                   # Feature Flags, Verification, Test Account Manager
│       ├── discovery/                     # Trainer search, public profiles, QR scanner simulator
│       ├── packages/                      # Package creation, purchase flow, manual payment review
│       ├── booking/                       # Calendar, slot booking, capacity checks, acceptance
│       ├── workout/                       # Workout builder, template manager, live workout logger, own workouts
│       ├── progress/                      # Metric history charts, circumference logs, photo gallery
│       └── notifications/                 # In-app notification center & event simulation
```

---

## 4. Stage 1 Mock Architecture & Simulator Design

In Stage 1, all network calls and persistent databases are bypassed using a **Reactive In-Memory State Store**.

### 4.1 Test Account Switcher & Simulator HUD
To allow seamless evaluation across all 5 user roles without needing SMS gateways or real logins, a floating **Development & Role Switcher HUD** is built into the prototype:
- Instant one-tap switching between:
  1. `SUPER_ADMIN` (`admin@test.local`)
  2. `GYM_MANAGER` (`gymmanager@test.local`)
  3. `HEAD_TRAINER` (`headtrainer@test.local`)
  4. `TRAINER` (`trainer@test.local`)
  5. `CLIENT` (`client@test.local`)
- Seed data reset button.
- Feature Flag quick toggle panel.

### 4.2 Reactive State Synchronization
- State updates (such as a trainer accepting a booking or verifying a payment) immediately update the shared mock state repository.
- Switching to the Client profile immediately reflects the newly confirmed session or active package credit balance without page reloads.

---

## 5. Production Target Backend Architecture (Stage 2 Blueprint)

When transitioning to production, the abstract repository layer connects directly to **Supabase (PostgreSQL 15+)**.

```
                           ┌───────────────────────────────────────────────┐
                           │            Supabase Backend Cloud             │
                           ├───────────────────────────────────────────────┤
                           │  • PostgreSQL 15+ DB (18+ relational tables)  │
                           │  • Row Level Security (RLS) policies          │
                           │  • Auth Service (JWT + Refresh Tokens)        │
                           │  • Storage S3 (Buckets: avatars, photos)      │
                           │  • Realtime Engine (Postgres Changes via WS)  │
                           │  • Edge Functions (Deno TypeScript)           │
                           └───────────────────────────────────────────────┘
```

### 5.1 Production Database Security (RLS Model)
- **Multi-Tenancy Guard**: Every table contains explicit ownership identifiers (`user_id`, `trainer_id`, `client_id`, or `gym_id`).
- **Private Data Protection**: Client medical/personal information is only readable if `client_opt_in_required` is true and an `ACCEPTED` relationship exists.
- **Progress Photos**: Encrypted URLs with expiring signed tokens via Supabase Storage.

---

## 6. Design System & Theming Architecture

1. **Theme Engine**:
   - Supports dynamic **Dark Mode** and **Light Mode** switching.
   - Tailored fitness palette: Energetic accents (Emerald Green / Neon Lime / Electric Cobalt), deep slate backgrounds (`#0F172A`), high-contrast typography, and glassmorphism card surfaces.
2. **Typography**: Clean, geometric sans-serif (Inter / Outfit) optimized for readability in gym environments.
3. **Micro-Interactions**: Haptic feedback on workout set completion, smooth animated progress bars, intuitive swipe-to-complete actions.

---

## 7. Migration Roadmap from Stage 1 to Production

| Component | Stage 1 (Mock Interactive Prototype) | Stage 2 (Production Live Backend) |
| :--- | :--- | :--- |
| **Authentication** | In-Memory Role Switcher + Mock OTP Generator | Supabase Auth (Phone SMS OTP + Google OAuth) |
| **Database** | In-Memory Collections with Seed Fixtures | PostgreSQL with Schema Migrations & RLS |
| **Storage** | Local Asset Bundles / Placeholder URLs | Supabase Storage with Private Access Policies |
| **Payments** | Simulated UPI / Cash Offline Confirmation Flow | Integrated Gateway (Razorpay/Stripe) + Webhooks |
| **Notifications** | In-App Mock Notification Center | Firebase Cloud Messaging (FCM) + WhatsApp Cloud API |
| **Feature Flags** | In-Memory Dynamic Store with Super Admin UI | Supabase `feature_flags` Table + Remote Config |
