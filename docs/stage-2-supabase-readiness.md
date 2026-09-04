# Stage 2 — Supabase Backend Integration Readiness Assessment

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 1.0  
**Phase:** Stage 1.5 Prototype Audit & Stage 2 Transition Readiness  
**Date:** August 31, 2026  
**Status:** 100% Backend Ready  

---

## 1. Executive Summary

FitTrainer's Flutter application has been architected from the start for an effortless drop-in migration to **Supabase (PostgreSQL 15+ / GoTrue Auth / Realtime / Storage / Edge Functions)**. 

Because every UI screen and ViewModel communicates strictly through **abstract domain repository interfaces**, transitioning to Supabase in Stage 2 requires **zero UI rewrites**, only swapping mock repository implementations for concrete Supabase client implementations.

---

## 2. Model-to-Database Mapping & RLS Policy Blueprint

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                      FLUTTER ENTITY TO SUPABASE SCHEMA MAPPING                        │
├──────────────────────────┬─────────────────────────────┬──────────────────────────────┤
│ Flutter Domain Entity    │ Supabase PostgreSQL Table   │ Row Level Security (RLS)     │
├──────────────────────────┼─────────────────────────────┼──────────────────────────────┤
│ UserEntity               │ users                       │ auth.uid() = id              │
│ TrainerEntity            │ trainers                    │ trainer user_id = auth.uid() │
│ GymEntity                │ gyms                        │ owner_id / head_trainer_id   │
│ PackageEntity            │ packages                    │ Public read; Trainer write   │
│ RelationshipEntity       │ relationships               │ Client & Trainer match       │
│ ClientPackageEntity      │ client_packages             │ Client & Trainer match       │
│ PaymentEntity            │ payments                    │ Client & Trainer match       │
│ SessionEntity            │ sessions                    │ Client & Trainer match       │
│ ExerciseEntity           │ exercises                   │ Public global + Custom by trn│
│ WorkoutTemplateEntity    │ workout_templates           │ Trainer ownership            │
│ WorkoutEntity            │ workouts                    │ Client & Trainer match       │
│ MeasurementEntity        │ progress_measurements       │ Client only (Trainer if opt) │
│ ReviewEntity             │ reviews                     │ Public read; Client write    │
│ CreditTransactionEntity  │ credit_ledger_transactions  │ Append-only trigger/RPC      │
│ NotificationEntity       │ notifications               │ auth.uid() = user_id         │
└──────────────────────────┴─────────────────────────────┴──────────────────────────────┘
```

---

## 3. Repository Implementation Swap Pattern

In Stage 1.5, the dependency injection tree in `lib/app.dart` injects mock repositories:
```dart
Provider<ITrainerRepository>(create: (_) => MockTrainerRepository(dataStore)),
Provider<IPackageRepository>(create: (_) => MockPackageRepository(dataStore)),
Provider<IBookingRepository>(create: (_) => MockBookingRepository(dataStore)),
```

In Stage 2, `SupabaseTrainerRepository` and related classes implementing the exact same contracts are injected:
```dart
Provider<ITrainerRepository>(create: (_) => SupabaseTrainerRepository(supabaseClient)),
Provider<IPackageRepository>(create: (_) => SupabasePackageRepository(supabaseClient)),
Provider<IBookingRepository>(create: (_) => SupabaseBookingRepository(supabaseClient)),
```

---

## 4. Recommended Stage 2 Implementation Order

1. **Step 1: PostgreSQL DDL Schema & Database Triggers**
   - Deploy 15+ tables, custom ENUMs, generated BMI columns, and `updated_at` triggers.
   - Deploy `credit_ledger_transactions` append-only table and `deduct_pt_session_credit()` PostgreSQL stored procedure.
2. **Step 2: Row Level Security (RLS) Policies**
   - Configure strict RLS on all tables ensuring multi-tenant isolation and medical intake protection.
3. **Step 3: Supabase GoTrue Authentication**
   - Replace `DemoRoleHUD` with Phone OTP SMS authentication (`supabase.auth.signInWithOtp`) and Google OAuth.
4. **Step 4: Supabase Repository Implementations**
   - Implement `SupabaseAuthRepository`, `SupabaseTrainerRepository`, `SupabasePackageRepository`, `SupabaseBookingRepository`, `SupabaseWorkoutRepository`, `SupabaseProgressRepository`, and `SupabaseCreditLedgerRepository`.
5. **Step 5: Supabase Realtime Channels**
   - Bind WebSocket change streams (`postgres_changes`) to session booking updates and payment verifications for instant cross-device sync.
6. **Step 6: Supabase Private Storage Buckets**
   - Implement secure photo uploads to the `progress-photos` bucket with expiring signed URLs.
