# Navigation Flow & Route Hierarchy

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 1.0  
**Status:** MVP Navigation Architecture  

This document outlines the routing structure, role-based entry points, bottom navigation hierarchies, modal flows, and conditional route guards.

---

## 1. Global Navigation Architecture & Routing Graph

```
                                      ┌────────────────────┐
                                      │   /splash (AUTH-01)│
                                      └─────────┬──────────┘
                                                │
                                    ┌───────────┴───────────┐
                                    ▼                       ▼
                           [ Authenticated ]       [ Unauthenticated ]
                                    │                       │
                                    │                       ▼
                                    │              ┌──────────────────┐
                                    │              │  /login (AUTH-02)│
                                    │              └────────┬─────────┘
                                    │                       │
                                    │                       ▼
                                    │              ┌──────────────────┐
                                    │              │   /otp (AUTH-03) │
                                    │              └────────┬─────────┘
                                    │                       │
                                    │                       ▼
                                    │              ┌──────────────────┐
                                    │              │ /role-select     │
                                    │              │     (AUTH-04)    │
                                    │              └────────┬─────────┘
                                    │                       │
                                    └───────────┬───────────┘
                                                │
                 ┌──────────────────────────────┼──────────────────────────────┐
                 ▼                              ▼                              ▼
    ┌─────────────────────────┐    ┌─────────────────────────┐    ┌─────────────────────────┐
    │    TRAINER PORTAL       │    │      CLIENT PORTAL      │    │    GYM / ADMIN PORTAL   │
    │  (Bottom Nav Scaffold)  │    │  (Bottom Nav Scaffold)  │    │  (Bottom Nav Scaffold)  │
    └─────────────────────────┘    └─────────────────────────┘    └─────────────────────────┘
```

---

## 2. Role-Based Navigation Structures

### 2.1 Trainer Navigation (`/trainer/*`)
**Bottom Navigation Tabs:**
1. **`HOME` (`/trainer/home`)**: Today's sessions, pending requests counter, revenue card, credit exhaustion warnings.
2. **`CLIENTS` (`/trainer/clients`)**: Client roster $\to$ Client Detail $\to$ Progress & Medical views.
3. **`CALENDAR` (`/trainer/calendar`)**: Working schedule, slot booking details, slot block/unblock.
4. **`WORKOUTS` (`/trainer/workouts`)**: Workout library, Exercise database, Workout builder.
5. **`MORE` (`/trainer/more`)**: Package manager, Offline payment verification, Availability config, Settings.

```mermaid
graph TD
    THome[/trainer/home] --> TSessionDetail[/trainer/session/:id]
    THome --> TRequests[/trainer/requests]
    TClients[/trainer/clients] --> TClientDetail[/trainer/client/:id]
    TClientDetail --> TClientProgress[/trainer/client/:id/progress]
    TClientDetail --> TClientMedical[/trainer/client/:id/medical]
    TClientDetail --> TAssignWorkout[/trainer/workouts/builder?clientId=:id]
    TCalendar[/trainer/calendar] --> TSessionDetail
    TWorkouts[/trainer/workouts] --> TBuilder[/trainer/workouts/builder]
    TWorkouts --> TExerciseLib[/trainer/exercises]
    TMore[/trainer/more] --> TPackages[/trainer/packages]
    TMore --> TPayments[/trainer/payments/verify]
    TMore --> TAvailability[/trainer/availability]
```

---

### 2.2 Client Navigation (`/client/*`)
**Bottom Navigation Tabs:**
1. **`HOME` (`/client/home`)**: Next session widget, credit balance gauge, today's workout preview, active trainer card.
2. **`WORKOUT` (`/client/workout`)**: Active workout tracker, assigned workouts, "Own Workout" logger, workout history.
3. **`PROGRESS` (`/client/progress`)**: Body weight charts, circumference history, private progress photos.
4. **`CALENDAR` (`/client/calendar`)**: Personal session bookings, slot picker for new bookings.
5. **`PROFILE` (`/client/profile`)**: Package details, payment receipt records, trainer discovery, settings & privacy.

```mermaid
graph TD
    CHome[/client/home] --> CBook[/client/calendar/book]
    CHome --> CActiveWorkout[/client/workout/active/:id]
    CHome --> CPackage[/client/packages/my-package]
    
    CWorkout[/client/workout] --> CActiveWorkout
    CWorkout --> COwnWorkout[/client/workout/own]
    CWorkout --> CHistory[/client/workout/history]
    
    CProgress[/client/progress] --> CLogMetrics[/client/progress/log]
    CProgress --> CPhotos[/client/progress/photos]
    
    CProfile[/client/profile] --> CDiscovery[/client/discovery]
    CDiscovery --> CTrainerProfile[/client/trainer/:id]
    CTrainerProfile --> CConsultation[/client/consultation/:id]
    CTrainerProfile --> CSelectPackage[/client/packages/select/:trainerId]
    CSelectPackage --> CPayment[/client/payments/pay/:packageId]
    CPayment --> CConfirmation[/client/payments/confirmation]
```

---

### 2.3 Gym Manager & Head Trainer Navigation (`/gym/*`)
**Bottom Navigation Tabs:**
1. **`DASHBOARD` (`/gym/dashboard`)**: Aggregate metrics, active trainer counts, today's attendance.
2. **`TRAINERS` (`/gym/trainers`)**: Roster of employed trainers, utilization metrics, performance.
3. **`CLIENTS` (`/gym/clients`)**: Gym-wide client directory, client assignment & reassignment console.
4. **`CALENDAR` (`/gym/calendar`)**: Multi-trainer master facility schedule.
5. **`REPORTS` (`/gym/reports`)**: Financial revenue breakdowns, package sales, trainer payouts.
6. **`SETTINGS` (`/gym/settings`)**: Gym profile, hours, and branding.

---

### 2.4 Super Admin Navigation (`/admin/*`)
1. **`DASHBOARD` (`/admin/dashboard`)**: System health, active users, error rates.
2. **`USERS` (`/admin/users`)**: Search, filter, and moderate all platform users.
3. **`VERIFICATION` (`/admin/verification`)**: Trainer certification verification queue.
4. **`FEATURE_FLAGS` (`/admin/flags`)**: Runtime switches for payments, search, notifications.
5. **`SETTINGS` (`/admin/settings`)**: Trial periods, global exercise directory, test account management.

---

## 3. Conditional Navigation & Guard Logic

```
                                 [ Client Attempts Action ]
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    ▼                         ▼                         ▼
            [ Book PT Session ]       [ Purchase Package ]       [ View Medical Info ]
                    │                         │                         │
                    ▼                         ▼                         ▼
       Has Active Relationship?      Has Accepted Rel.?         Client Opted In?
        ├── NO  ──► Redirect /discovery  ├── NO  ──► Redirect /discovery  ├── NO  ──► Show Locked Card
        └── YES ──► Check Credits       └── YES ──► Open /packages/select └── YES ──► Display Data
                      │
           Remaining Credits > 0?
            ├── NO  ──► Prompt Package Renewal or Log "Own Workout"
            └── YES ──► Open /calendar/book
```

---

## 4. Modal Dialogs & Bottom Sheet Inventory

| Trigger | Modal / Sheet Component | Expected Outcome |
| :--- | :--- | :--- |
| Floating Role Switcher Pill | **Test Account HUD Sheet** | Instantly switches active user session without re-login. |
| QR Scan Icon | **QR Scanner Camera Sheet** | Parses trainer code and routes directly to Trainer Public Profile. |
| Complete Workout Button | **Workout Summary & Rating Dialog** | Prompts for session feedback, saves log, and updates streak. |
| Low Credit Alert | **Package Renewal Prompt Sheet** | Deep links directly to trainer's package catalog. |
| Review Prompt | **Trainer 5-Star Review Sheet** | Opens star rating & text review for completed sessions. |
