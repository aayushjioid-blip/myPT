# FitTrainer (myPT) — Stage 2 Authentication Architecture

**Project:** FitTrainer (Fitness Trainer Platform)  
**Authentication Engine:** Supabase GoTrue Auth  
**Date:** August 31, 2026  
**Status:** Production Ready  

---

## 1. Authentication Strategy

FitTrainer uses **Supabase GoTrue** providing multi-method authentication:

1. **Phone Number + SMS OTP (`signInWithOtp`, `verifyOTP`)**: Primary mobile authentication method.
2. **Google Sign-In (`OAuthProvider.google`)**: One-tap OAuth login.
3. **Apple Sign-In (`OAuthProvider.apple`)**: Required for iOS App Store compliance.
4. **Development Demo HUD**: In development builds, `AppConfig.isDemoHudEnabled = true` enables quick switching between Sarah Jenkins, Alex Rivera, Marcus Vance, Elena Rostova, and Super Admin. In production builds (`AppEnvironment.production`), the HUD is completely compiled out and disabled.

---

## 2. Onboarding & User Profile Creation Flow

```
[User Authenticates via GoTrue (SMS / Google / Apple)]
                         │
                         ▼
        [Query users table by auth_id]
        ┌────────────────┴────────────────┐
        ▼ (Profile Exists)                ▼ (New User)
[Load User Profile & Role]     [Onboarding Screen]
        │                                 │
        │                                 ▼
        │                      [Insert into users table]
        │                      [Insert client_health_profiles]
        │                      (Role defaults to 'CLIENT')
        │                                 │
        └────────────────┬────────────────┘
                         ▼
           [Mount FitTrainerApp UI]
```

---

## 3. Privilege Escalation Protection

- **Client Self-Assignment Prevention:** New user accounts default to `role = 'CLIENT'`.
- **Administrative Privileges (`SUPER_ADMIN`, `GYM_MANAGER`, `HEAD_TRAINER`):** Must be provisioned by an existing Super Admin or through secure database migrations. RLS strictly rejects unauthorized role modifications.
