# User Flows & System Journeys

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 1.0  
**Status:** MVP Specification  

This document details the primary user journeys, state transitions, and step-by-step interactions across all platform roles.

---

## 1. Authentication & Onboarding Flows

### 1.1 Universal Authentication
```
[ User Lands on App ]
         │
         ▼
[ Choose Auth Method ] ──► (Email + Password / Google OAuth / Apple OAuth / Phone OTP)
         │
         ▼
[ Supabase Auth Verification ]
         │
         ├── New User ────────► [ Role Selection Screen: Trainer | Client ]
         │
         └── Existing User ───► [ Role Profile Check ] ──► [ Appropriate Dashboard ]
```

---

### 1.2 Trainer Onboarding Journey
```
[ Select 'Trainer' Role ]
         │
         ▼
[ Step 1: Basic Profile ] ──► Name, Phone, Bio, Profile Photo, Years of Experience
         │
         ▼
[ Step 2: Specializations ] ─► Weight Loss, Muscle Building, Mobility, Rehab, Strength & Conditioning
         │
         ▼
[ Step 3: Certifications ] ──► Upload Certification Proofs (NASM, ACE, ACSM, etc.)
         │
         ▼
[ Step 4: Availability & Capacity ] ──► Weekly Slot Config, Buffer Time, Max Clients per Slot
         │
         ▼
[ Step 5: Initial Packages ] ─► Create at least one training package (Sessions, Price, Validity)
         │
         ▼
[ Step 6: Cancellation Policy ] ─► Select No Penalty / 4-Hour Cutoff / Custom
         │
         ▼
[ Trainer Dashboard Initialized ] (365-day free trial activated)
```

---

### 1.3 Client Onboarding Journey
```
[ Select 'Client' Role ]
         │
         ▼
[ Step 1: Personal Info ] ──► Age, Gender, Current Weight, Height
         │
         ▼
[ Step 2: Fitness Goals ] ──► Fat Loss, Hypertrophy, Endurance, Mobility, Athletic Performance
         │
         ▼
[ Step 3: Medical / Injury History ] ──► Previous injuries, chronic conditions, physical limitations
         │
         ▼
[ Step 4: Entry Route Choice ]
         ├── Option A: Scan Trainer QR / Referral Link ──► [ Direct Trainer Connection Request ]
         └── Option B: Explore Trainer Discovery ────────► [ Public Trainer Directory ]
```

---

## 2. Trainer Discovery & Consultation Flow

```
[ Client Browses Discovery ]
         │
         ▼
[ Apply Filters ] (Location, Goal Specialization, Price Range, Rating, Experience)
         │
         ▼
[ View Trainer Public Profile ] (Bio, Certifications, Reviews, Available Packages)
         │
         ▼
[ Request Free Consultation / Connect ]
         │
         ▼
[ Trainer Receives In-App / Push Notification ]
         │
         ├── [ Trainer Rejects ] ──► Notification to Client
         │
         └── [ Trainer Accepts ] ──► Relationship Created (Status: ACTIVE)
                                         │
                                         ▼
                                   [ Client Unlocks Package Purchase & Booking ]
```

---

## 3. Package Purchase & Payment Lifecycle

```
[ Active Relationship Established ]
         │
         ▼
[ Client Views Trainer Packages ]
         │
         ▼
[ Client Selects Package ] (e.g., 10 Sessions / 40-day validity)
         │
         ▼
[ Payment Mode (MVP: Manual / Feature Flag: Gateway) ]
         │
         ├── Manual Mode:
         │     ├── Client marks "Paid Offline (Cash/UPI/Bank Transfer)"
         │     └── Trainer confirms receipt on Trainer Dashboard
         │
         └── Online Mode (Feature Flagged):
               └── Instant Payment Gateway Verification
         │
         ▼
[ Package Activated ]
  - Credits incremented: +10 Sessions
  - Expiry date computed and assigned
  - Client unlocked for session booking
```

---

## 4. Session Booking & Credit Consumption Lifecycle

```
[ Client Initiates Booking ]
         │
         ▼
[ Select Date & Time Slot ]
         │
         ▼
[ System Validation Checks ]:
  ├── Active relationship?
  ├── Remaining credits > 0?
  ├── Package unexpired?
  └── Trainer slot available & capacity not exceeded?
         │
         ▼
[ Booking Request Sent to Trainer ] (Status: REQUESTED)
         │
         ├── [ Trainer Declines / Reschedules ] ──► Slot released; credits unchanged
         │
         └── [ Trainer Accepts ] ──► Status: CONFIRMED / SCHEDULED
                                         │
                                         ▼
                                 [ Session Takes Place ]
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼                                               ▼
     [ Marked COMPLETED ]                             [ Session CANCELLED ]
                 │                                               │
                 ▼                                               ▼
    [ 1 Credit Deducted ]                         [ Check Cancellation Policy ]:
                                                   ├── Within Grace Period ──► 0 Credits Deducted
                                                   └── Late Cancellation ────► 1 Credit Deducted
```

---

## 5. Workout Programming & Exercise Logging

### 5.1 Trainer Workout Assignment
```
[ Trainer Dashboard ] ──► [ Client Detail Page ]
         │
         ▼
[ Create Workout ] (Choose Template or Custom Build)
         │
         ▼
[ Add Exercises from Library / Custom Exercises ]
  - Set target Sets, Reps, Weight/RPE, Rest intervals, and form tips
         │
         ▼
[ Assign to Calendar Date ] ──► [ Client receives notification ]
```

### 5.2 Client Workout Execution & Own Workouts
```
[ Client Dashboard: Today's Workout ]
         │
         ├── Mode A: Assigned PT / Program Workout
         └── Mode B: "Own Workout" (Free self-logged session, 0 PT credits consumed)
         │
         ▼
[ Start Workout Session ]
         │
         ▼
[ Log Actual Sets, Reps, Weight Lifted, Rest Timers ]
         │
         ▼
[ Finish Workout ] ──► Data saved to immutable history & Progress Graphs updated
```

---

## 6. Progress Tracking & Body Metrics Flow

```
[ Client / Trainer Opens Progress Tab ]
         │
         ▼
[ Log New Entry ]
  ├── Circumference Metrics (Chest, Waist, Hips, Biceps, Thighs)
  ├── Weight & Calculated BMI
  └── Optional Progress Photos (Front, Side, Back)
         │
         ▼
[ Data Encrypted & Stored ] (RLS: Accessible only by assigned Trainer & Client)
         │
         ▼
[ View Dynamic Historical Progress Charts ]
```

---

## 7. Review & Rating Flow

```
[ Client with Completed Sessions ]
         │
         ▼
[ Prompted to Review Trainer ]
         │
         ▼
[ Submit Star Rating (1-5) + Written Feedback ]
         │
         ▼
[ Trainer Profile Metrics Updated (Average Rating & Review Count) ]
```

---

## 8. Gym Management & Head Trainer Workflow

```
[ Gym Manager Creates Gym Organization ]
         │
         ▼
[ Invite Head Trainer & Personal Trainers ]
         │
         ▼
[ Head Trainer Client Management Console ]:
  ├── View all gym-wide incoming client requests
  ├── Assign Client to designated Trainer
  └── Reassign Client to new Trainer (retains all historical session logs)
         │
         ▼
[ Gym Performance Analytics & Revenue Overview ]
```
