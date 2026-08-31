# User Roles & Permissions Matrix

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 1.0  
**Status:** MVP Specification & Authorization Architecture  

This document details the role hierarchies, operational scopes, access control matrices, data privacy boundaries, and transition rules for all platform roles.

---

## 1. Role Definitions & Hierarchy

```
                            ┌────────────────────────┐
                            │      SUPER_ADMIN       │ (Global Scope)
                            └───────────┬────────────┘
                                        │
                         ┌──────────────┴──────────────┐
                         ▼                             ▼
              ┌─────────────────────┐       ┌─────────────────────┐
              │     GYM_MANAGER     │       │ INDEPENDENT TRAINER │ (Trainer-First Autonomy)
              └──────────┬──────────┘       └──────────┬──────────┘
                         ▼                             │
              ┌─────────────────────┐                  │
              │    HEAD_TRAINER     │                  │
              └──────────┬──────────┘                  │
                         ▼                             │
              ┌─────────────────────┐                  │
              │     GYM TRAINER     │                  │
              └──────────┬──────────┘                  │
                         │                             │
                         └──────────────┬──────────────┘
                                        ▼
                            ┌────────────────────────┐
                            │         CLIENT         │ (Self Scope)
                            └────────────────────────┘
```

| Role | Operational Scope | Description |
| :--- | :--- | :--- |
| **`SUPER_ADMIN`** | `GLOBAL` | System administrator with unrestricted platform access, feature flag governance, global user verification, audit logging, and payment oversight. |
| **`GYM_MANAGER`** | `GYM` | Business owner/manager of a gym facility. Manages gym profile, trainer affiliations, memberships, facility settings, and aggregate financial reports. |
| **`HEAD_TRAINER`** | `GYM` | Senior trainer within a gym. Oversees training staff, assigns/reassigns incoming gym clients, creates gym-wide package templates, and monitors workout delivery. |
| **`TRAINER`** | `TRAINER_OR_GYM` | Personal trainer operating independently or affiliated with one or more gyms. Builds custom packages, sets capacity/availability, programs workouts, verifies payments, and logs sessions. |
| **`CLIENT`** | `SELF` | End customer. Discovers trainers, books sessions, executes assigned/own workouts, logs body metrics, purchases packages, and submits reviews. |

---

## 2. Comprehensive Permissions Matrix

| Module / Entity | Action | `SUPER_ADMIN` | `GYM_MANAGER` | `HEAD_TRAINER` | `TRAINER` | `CLIENT` |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **Users / Profiles** | View Profile | Global | Own Gym Staff/Clients | Own Gym Staff/Clients | Assigned Clients | Self Only |
| | Edit Profile | Any | Gym Profile | Own Profile | Own Profile | Self Only |
| | Verify Trainer | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Gym & Staff** | Create Gym | ✅ | ✅ | ❌ | ❌ | ❌ |
| | Invite Trainers | ✅ | ✅ | ✅ | ❌ | ❌ |
| | Assign/Reassign Client | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Trainer Discovery** | View Public Directory | ✅ | ✅ | ✅ | ✅ | ✅ (Verified only) |
| | Access Unverified Trainer | ✅ | Own Gym | Own Gym | Self | Via direct QR/Code |
| **Packages** | Create Package | Global Templates | Gym Templates | Gym Templates | Own Packages | ❌ |
| | View Package | All | Own Gym | Own Gym | Own Packages | Trainer's Packages |
| | Purchase Package | ❌ | ❌ | ❌ | ❌ | ✅ (If Approved) |
| **Payments** | View Payment History | Global | Own Gym | Own Gym | Own Clients | Self Only |
| | Submit Offline Payment | ❌ | ❌ | ❌ | ❌ | ✅ |
| | Verify Offline Payment | ✅ | ✅ | ✅ | ✅ (Own Clients) | ❌ |
| **Bookings & Sessions**| Request Booking | ❌ | ❌ | ❌ | ❌ | ✅ (If Credits > 0) |
| | Accept/Decline Booking | ✅ | ✅ | ✅ | ✅ (Own Schedule) | ❌ |
| | Start/Complete Session | ✅ | ❌ | ✅ | ✅ (Assigned Client)| ❌ |
| | Cancel Session | ✅ | ✅ | ✅ | ✅ | ✅ (Subject to Policy)|
| **Workouts** | Create Custom Exercise | Global Library | Gym Library | Gym Library | Own Library | ❌ |
| | Create Workout Template | Global | Gym-wide | Gym-wide | Own Templates | ❌ |
| | Assign Workout | ✅ | ❌ | ✅ | ✅ (Assigned Client)| ❌ |
| | Execute & Log Assigned | ✅ | ❌ | ✅ | ✅ (During Session)| ✅ (Assigned) |
| | Create & Log "Own Workout"| ❌ | ❌ | ❌ | ❌ | ✅ (0 Credits Used) |
| **Progress & Photos** | Record Measurements | ✅ | ❌ | ✅ | ✅ (Assigned Client)| ✅ (Self) |
| | View Progress Charts | ✅ | ❌ | ✅ | ✅ (Assigned Client)| ✅ (Self) |
| | Upload Progress Photos | ❌ | ❌ | ❌ | ❌ | ✅ (Private to Trainer)|
| **Medical / Personal** | View Client Health Info | ✅ (Audit) | ❌ | ✅ (If Opted-in) | ✅ (If Opted-in) | ✅ (Self) |
| **Reviews** | Submit Review | ❌ | ❌ | ❌ | ❌ | ✅ ($\ge 1$ PT Session) |
| | Moderate / Delete Review | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Feature Flags** | Toggle Global Flags | ✅ | ❌ | ❌ | ❌ | ❌ |

---

## 3. Client-Trainer Relationship Lifecycle & Rules

```
                      ┌──────────────────────┐
                      │  DISCOVERY / QR CODE │
                      └──────────┬───────────┘
                                 │
                                 ▼
                      ┌──────────────────────┐
                      │      REQUESTED       │ ◄── Client clicks "Interested" / Sends Request
                      └──────────┬───────────┘
                                 │
                 ┌───────────────┴───────────────┐
                 ▼                               ▼
      ┌──────────────────────┐       ┌──────────────────────┐
      │       ACCEPTED       │       │       REJECTED       │
      └──────────┬───────────┘       └──────────────────────┘
                 │
       ┌─────────┴─────────┐
       ▼                   ▼
┌──────────────┐    ┌──────────────┐
│  SUSPENDED   │    │  REASSIGNED  │ (Gym Mode: Head Trainer Reassignment)
└──────┬───────┘    └──────┬───────┘
       │                   │
       ▼                   ▼
┌──────────────┐    ┌──────────────┐
│    ENDED     │    │  NEW TRAINER │ (Historical logs preserved)
└──────────────┘    └──────────────┘
```

### 3.1 Reassignment Rules
1. **Independent Trainer Model**:
   - The relationship is direct and exclusive.
   - The client **cannot** self-switch or be unilaterally transferred.
   - If either party ends the relationship, past session and workout history remains locked to that trainer archive.
2. **Gym Model**:
   - Gym Managers and Head Trainers hold explicit reassignment authority.
   - When a client is reassigned from Trainer A to Trainer B:
     - Active package credits remain intact under the gym.
     - Trainer B inherits access to past workout logs and measurement trends.
     - Trainer A loses edit permissions on the client's future schedule.

---

## 4. Data Privacy & Row-Level Security Rules

1. **Client Isolation**: Clients cannot query or view data belonging to other clients under any circumstance.
2. **Opt-In Health & Medical Sharing**:
   - Client medical history, injuries, and emergency contact details are shielded by default.
   - Client must explicitly toggle the `"Share with my trainer"` preference to grant read access to their assigned trainer.
3. **Progress Photos Privacy**:
   - Photos uploaded by clients are stored under private paths (`/clients/{client_id}/progress/{photo_id}`).
   - Accessible strictly by the client and their active trainer.
4. **Financial Data Shielding**:
   - Trainers only see revenue and payments generated from their own packages.
   - Gym Managers view gym-level aggregate financials without exposing trainer bank details.

---

## 5. Test Accounts & Bypasses

For testing, prototyping, and Stage 1 demonstration, the platform provides 5 seeded accounts:

| Role | Test Email | Default Password | Bypass Privileges |
| :--- | :--- | :--- | :--- |
| **`SUPER_ADMIN`** | `admin@test.local` | `testpass123` | Bypasses all restrictions, controls feature flags, accesses all data. |
| **`GYM_MANAGER`** | `gymmanager@test.local` | `testpass123` | Bypasses subscription billing, pre-linked to "IronCore Fitness Gym". |
| **`HEAD_TRAINER`** | `headtrainer@test.local` | `testpass123` | Pre-assigned to "IronCore Fitness Gym", manages gym trainers & clients. |
| **`TRAINER`** | `trainer@test.local` | `testpass123` | Pre-verified, 365-day free trial active, pre-loaded packages & clients. |
| **`CLIENT`** | `client@test.local` | `testpass123` | Pre-connected to trainer, active 10-session package, seed progress data. |

> **Rule**: Test accounts are excluded from public trainer discovery searches to prevent cluttering the directory.
