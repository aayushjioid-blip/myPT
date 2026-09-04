# FitTrainer (myPT) — Stage 2.0 Entity Relationship Diagram (ERD)

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 2.0 Production Schema  
**Date:** August 31, 2026  

---

## 1. High-Level Entity Architecture

```mermaid
erDiagram
    users ||--o| client_health_profiles : "has"
    users ||--o| trainer_profiles : "has"
    users ||--o{ gym_memberships : "affiliated_with"
    gyms ||--o{ gym_memberships : "has_staff"
    
    users ||--o{ relationships : "client_or_trainer"
    users ||--o{ consultation_requests : "requests_or_reviews"
    
    trainer_profiles ||--o{ packages : "creates"
    packages ||--o{ client_packages : "purchased_as"
    users ||--o{ client_packages : "owns"
    
    client_packages ||--o{ payments : "paid_via"
    client_packages ||--o{ credit_ledger_transactions : "tracks_balance"
    
    users ||--o{ sessions : "participates_in"
    client_packages ||--o{ sessions : "consumed_by"
    
    sessions ||--o| workouts : "executes"
    workout_templates ||--o{ workouts : "based_on"
    workouts ||--o{ workout_exercises : "contains"
    workout_exercises ||--o{ workout_sets : "logs"
    exercises ||--o{ workout_exercises : "references"
    
    users ||--o{ progress_measurements : "logs"
    progress_measurements ||--o{ progress_photos : "attaches"
    
    users ||--o{ reviews : "writes_or_receives"
    users ||--o{ notifications : "receives"
```

---

## 2. Detailed Database Relational ERD

```mermaid
erDiagram
    users {
        uuid id PK
        uuid auth_id
        varchar email
        varchar name
        user_role_type role
        boolean is_active
        timestamptz created_at
    }

    client_health_profiles {
        uuid id PK
        uuid user_id FK
        numeric height_cm
        numeric weight_kg
        text fitness_goal
        text injuries
        text medical_info
        boolean share_personal_info_with_trainer
    }

    trainer_profiles {
        uuid id PK
        uuid user_id FK
        varchar trainer_code UK
        int years_experience
        numeric rating
        trainer_verification_status verification_status
        boolean is_independent
        int cancellation_grace_hours
        boolean late_cancellation_penalty_enabled
    }

    gyms {
        uuid id PK
        varchar name
        varchar slug UK
        int floor_capacity
        text operating_hours
        boolean is_active
    }

    gym_memberships {
        uuid id PK
        uuid gym_id FK
        uuid trainer_id FK
        user_role_type role_in_gym
        boolean is_primary
    }

    packages {
        uuid id PK
        uuid trainer_id FK
        uuid gym_id FK
        varchar name
        int sessions
        numeric price
        int validity_days
        boolean is_active
    }

    client_packages {
        uuid id PK
        uuid client_id FK
        uuid trainer_id FK
        uuid package_id FK
        int total_sessions
        int remaining_sessions
        client_package_status_type status
        timestamptz activated_at
        timestamptz expires_at
    }

    credit_ledger_transactions {
        uuid id PK
        uuid client_package_id FK
        uuid client_id FK
        uuid trainer_id FK
        uuid session_id FK
        credit_transaction_type transaction_type
        int delta_credits
        int balance_after
        text reason
        timestamptz created_at
    }

    sessions {
        uuid id PK
        uuid client_id FK
        uuid trainer_id FK
        uuid client_package_id FK
        session_classification_type session_type
        session_status_type status
        timestamptz scheduled_start
        timestamptz scheduled_end
        boolean credit_consumed
        boolean is_recurring
    }

    workouts {
        uuid id PK
        uuid client_id FK
        uuid trainer_id FK
        uuid session_id FK
        varchar name
        session_classification_type workout_type
        varchar status
        timestamptz completed_at
    }

    progress_measurements {
        uuid id PK
        uuid client_id FK
        date date
        numeric weight_kg
        numeric height_cm
        numeric bmi
        numeric body_fat_percentage
        numeric chest_cm
        numeric waist_cm
        numeric hips_cm
        varchar source
    }
```
