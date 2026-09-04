# Flutter Clean Architecture & Technical Blueprint

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 1.0  
**Phase:** Stage 1.5 — Flutter Foundation  
**Date:** August 31, 2026  

---

## 1. High-Level Architecture Overview

The FitTrainer Flutter application follows **Feature-Driven Clean Architecture** combined with reactive State Management. This architecture strictly isolates business rules from external frameworks, rendering Flutter UI widgets completely agnostic of data storage details (enabling an effortless transition from mock repositories to Supabase in Stage 2).

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PRESENTATION LAYER (UI)                           │
│  • Flutter Widgets, Screens, Modals, Bottom Sheets                          │
│  • Theme Engine, Layout Grids, Responsive Breakpoints                       │
│  • ViewModels / ChangeNotifiers (State Presentation Logic)                  │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Calls Domain Contracts / Receives State
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                            DOMAIN LAYER (CORE LOGIC)                        │
│  • Business Entities (Immutable Data Classes)                               │
│  • Abstract Repository Interfaces (e.g. `ITrainerRepository`)               │
│  • Domain Services (e.g. `CreditLedgerService`, `CancellationEvaluator`)    │
└──────────────────────────────────────▲──────────────────────────────────────┘
                                       │ Implemented By
┌──────────────────────────────────────┴──────────────────────────────────────┐
│                             DATA LAYER (ACCESS)                             │
│  • Models (Data Transfer Objects with `toJson` / `fromJson` serialization)  │
│  • [STAGE 1.5]: Mock Repositories (`MockTrainerRepository`, `MockDataStore`)│
│  • [STAGE 2]: Supabase Repositories (`SupabaseTrainerRepository`, PostgreSQL│
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Directory Structure Specification

```
lib/
├── main.dart                          # Application entry point, global error handler
├── app.dart                           # Root MaterialApp, MultiProvider setup, Theme mode
│
├── core/                              # Cross-cutting core infrastructure
│   ├── theme/                         # Light & Dark theme data, color tokens, typography
│   │   ├── app_colors.dart
│   │   ├── app_theme.dart
│   │   └── app_typography.dart
│   ├── routing/                       # Route names, declarative navigation generator
│   │   ├── app_router.dart
│   │   └── app_routes.dart
│   ├── constants/                     # Platform constants, layout dimensions
│   │   └── app_constants.dart
│   ├── utils/                         # Date formatters, BMI calculations, currency helpers
│   │   └── formatters.dart
│   └── widgets/                       # Reusable UI Design System Components
│       ├── fitness_card.dart
│       ├── metric_tile.dart
│       ├── stat_gauge.dart
│       ├── custom_button.dart
│       ├── custom_text_field.dart
│       ├── status_badge.dart
│       ├── app_header.dart
│       └── demo_role_hud.dart
│
├── domain/                            # Abstract contracts & business rules
│   ├── entities/                      # Pure Dart immutable entities
│   │   ├── user_entity.dart
│   │   ├── trainer_entity.dart
│   │   ├── package_entity.dart
│   │   ├── session_entity.dart
│   │   ├── workout_entity.dart
│   │   ├── measurement_entity.dart
│   │   ├── credit_transaction_entity.dart
│   │   └── cancellation_policy_entity.dart
│   ├── repositories/                  # Abstract repository contracts
│   │   ├── i_auth_repository.dart
│   │   ├── i_trainer_repository.dart
│   │   ├── i_package_repository.dart
│   │   ├── i_booking_repository.dart
│   │   ├── i_workout_repository.dart
│   │   ├── i_progress_repository.dart
│   │   └── i_credit_ledger_repository.dart
│   └── services/                      # Domain validation services
│       ├── credit_ledger_service.dart
│       └── cancellation_evaluator.dart
│
├── data/                              # Data implementations & mock fixtures
│   ├── models/                        # Serialized DTOs mapping to domain entities
│   │   ├── user_model.dart
│   │   ├── trainer_model.dart
│   │   ├── package_model.dart
│   │   ├── session_model.dart
│   │   ├── workout_model.dart
│   │   └── measurement_model.dart
│   ├── mock/                          # Seed data fixtures across all 5 roles
│   │   ├── mock_seed_data.dart
│   │   └── mock_data_store.dart
│   └── repositories/                  # Mock implementations of domain contracts
│       ├── mock_auth_repository.dart
│       ├── mock_trainer_repository.dart
│       ├── mock_package_repository.dart
│       ├── mock_booking_repository.dart
│       ├── mock_workout_repository.dart
│       ├── mock_progress_repository.dart
│       └── mock_credit_ledger_repository.dart
│
└── features/                          # Feature modules (UI & Feature ViewModels)
    ├── auth/                          # Login, OTP, Role Selection, Demo HUD Switcher
    ├── discovery/                     # Trainer search, public profiles, QR scanner
    ├── client_home/                   # Client daily hub, today's workout, credit gauge
    ├── trainer_dashboard/             # Command center, pending queues, business KPIs
    ├── packages/                      # Package builder, purchase flow, offline UPI payment
    ├── booking/                       # Calendar, slot capacity, recurring sessions
    ├── workouts/                      # Workout studio, template manager, live logger, own workouts
    ├── progress/                      # 8-point body metrics, BMI, SVG sparkline, privacy toggle
    ├── gym/                           # Head Trainer reassignment & Gym Manager roster
    ├── notifications/                 # In-app notification center drawer
    └── admin/                         # Super Admin console & Feature Flags manager
```
