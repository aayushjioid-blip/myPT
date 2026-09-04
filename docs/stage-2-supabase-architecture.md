# FitTrainer (myPT) — Stage 2 Supabase Architecture Specification

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 2.0 Backend Architecture  
**Date:** August 31, 2026  

---

## 1. End-to-End System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FLUTTER PRESENTATION LAYER                        │
│  • ClientHomeScreen, TrainerDashboardScreen, GymDashboardScreen, etc.       │
│  • ViewModels (ChangeNotifiers: AuthVM, BookingVM, WorkoutVM, etc.)         │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Calls Domain Interfaces
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                              DOMAIN INTERFACES                              │
│  • IAuthRepository, ITrainerRepository, IPackageRepository, etc.           │
│  • CreditLedgerService, CancellationEvaluator                               │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Implemented by
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                         SUPABASE REPOSITORIES LAYER                         │
│  • SupabaseAuthRepository, SupabaseTrainerRepository, etc.                 │
│  • DTO Models (UserModel, SessionModel, WorkoutModel, etc.)                 │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ HTTPS / WebSockets
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                               SUPABASE BACKEND                              │
│  • GoTrue Auth (SMS OTP, Google, Apple)                                     │
│  • PostgreSQL 15+ (26 Physical Tables, RLS, Foreign Keys, Indexes)          │
│  • Atomic Stored Procedures (verify_payment, complete_session, etc.)        │
│  • Realtime WebSockets (postgres_changes streams)                           │
│  • Storage Buckets (progress-photos with expiring signed URLs)              │
└─────────────────────────────────────────────────────────────────────────────┘
```
