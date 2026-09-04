# FitTrainer (myPT) — Stage 2.0 Row Level Security (RLS) & Authorization

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 2.0 Security Architecture  
**Database Engine:** PostgreSQL 15+ (Supabase)  
**Date:** August 31, 2026  

---

## 1. Security Architecture Principles

1. **The Client is Never the Security Boundary**: All access permissions and privacy policies are enforced at the database layer via PostgreSQL Row Level Security (RLS).
2. **Strict Medical & Health Intake Protection**: A coach cannot read a client's health intake, injuries, medical notes, or body scans unless:
   - An active client-trainer relationship exists (`relationships.status = 'ACTIVE'`).
   - The client has explicitly enabled `share_personal_info_with_trainer = TRUE`.
3. **Public Discovery Access Control**: Unverified trainers (e.g. Leo Novak) are completely filtered out from public `SELECT` queries unless directly referenced by their unique `trainer_code`.
4. **Append-Only Ledger Immutability**: `credit_ledger_transactions` is read-only for clients and trainers. Balance alterations are strictly restricted to security definer stored procedures (`verify_and_activate_package_payment`, `complete_pt_session`, `apply_cancellation_policy`).

---

## 2. Role-Based RLS Permission Matrix

| Database Table | `CLIENT` | `TRAINER` | `HEAD_TRAINER` | `GYM_MANAGER` | `SUPER_ADMIN` |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `users` | Own row | Own row + Clients | Own row + Staff | Own row + Staff | ALL |
| `client_health_profiles` | Own row (ALL) | Assigned (IF opted-in) | Assigned (IF opted-in) | No health data | ALL |
| `trainer_profiles` | Verified only | Own row | Own gym staff | Own gym staff | ALL |
| `gyms` | Public active | Public active | Assigned gym | Managed gym | ALL |
| `gym_memberships` | View | Own row | Gym roster | Gym roster | ALL |
| `packages` | Active public | Own packages | Gym packages | Gym packages | ALL |
| `relationships` | Own | Own assigned | Gym clients | Gym clients | ALL |
| `client_packages` | Own | Own clients | Gym clients | Gym clients | ALL |
| `payments` | Own payments | Own receipts | Gym receipts | Gym receipts | ALL |
| `credit_ledger_transactions` | Own balance (Read) | Own clients (Read)| Gym clients (Read) | Gym clients (Read) | ALL |
| `sessions` | Own sessions | Own sessions | Gym sessions | Gym sessions | ALL |
| `exercises` | Global + Own coach| Global + Own custom| Global + Gym staff | Global + Gym staff | ALL |
| `workout_templates` | None | Own templates | Gym templates | Gym templates | ALL |
| `workouts` & `sets` | Own workouts | Own clients | Gym clients | Gym clients | ALL |
| `progress_measurements` | Own (ALL) | Assigned (IF opted-in) | Assigned (IF opted-in) | No health data | ALL |
| `reviews` | Public visible + Submit | Public visible | Public visible | Public visible | ALL |
| `notifications` | Own (ALL) | Own (ALL) | Own (ALL) | Own (ALL) | ALL |
| `feature_flags` | Read (ALL) | Read (ALL) | Read (ALL) | Read (ALL) | Full Manage |

---

## 3. Key RLS Helper Implementations

```sql
-- Health & Medical Privacy Shield
CREATE OR REPLACE FUNCTION is_client_sharing_health_with_trainer(p_client_id UUID, p_trainer_id UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM client_health_profiles chp
        JOIN relationships r ON r.client_id = chp.user_id
        WHERE chp.user_id = p_client_id
          AND r.trainer_id = p_trainer_id
          AND r.status IN ('ACCEPTED', 'APPROVED_FOR_PURCHASE', 'ACTIVE')
          AND chp.share_personal_info_with_trainer = TRUE
    );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Unverified Trainer Public Discovery Gating
CREATE POLICY "Verified trainers visible in public discovery"
ON trainer_profiles FOR SELECT
USING (
    verification_status = 'VERIFIED'
    OR user_id = get_current_user_id()
    OR is_super_admin()
);
```
