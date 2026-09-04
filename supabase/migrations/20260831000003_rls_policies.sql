-- ============================================================================
-- FitTrainer (myPT) — Migration 003: Row Level Security (RLS) Policies
-- ============================================================================

-- 1. SECURITY HELPER FUNCTIONS

CREATE OR REPLACE FUNCTION get_current_user_id()
RETURNS UUID AS $$
    SELECT id FROM users WHERE auth_id = auth.uid() LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_current_user_role()
RETURNS user_role_type AS $$
    SELECT role FROM users WHERE auth_id = auth.uid() LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS BOOLEAN AS $$
    SELECT (get_current_user_role() = 'SUPER_ADMIN');
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION has_active_relationship(p_client_id UUID, p_trainer_id UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM relationships
        WHERE client_id = p_client_id
          AND trainer_id = p_trainer_id
          AND status IN ('ACCEPTED', 'APPROVED_FOR_PURCHASE', 'ACTIVE')
    );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

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

-- 2. ENABLE RLS ON ALL TABLES
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_health_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE gyms ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE gym_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_specializations ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_certifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_working_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultation_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_ledger_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY;

-- 3. USERS TABLE POLICIES
CREATE POLICY "Users can view own profile or Super Admin all"
ON users FOR SELECT
USING (auth.uid() = auth_id OR is_super_admin() OR role IN ('TRAINER', 'HEAD_TRAINER'));

CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
USING (auth.uid() = auth_id OR is_super_admin());

-- 4. CLIENT HEALTH PROFILES (STRICT MEDICAL PRIVACY SHIELD)
CREATE POLICY "Clients can view and manage own health profile"
ON client_health_profiles FOR ALL
USING (user_id = get_current_user_id() OR is_super_admin());

CREATE POLICY "Authorized trainers can view health profile ONLY when client opted-in"
ON client_health_profiles FOR SELECT
USING (is_client_sharing_health_with_trainer(user_id, get_current_user_id()));

-- 5. TRAINER PROFILES (PUBLIC DISCOVERY GATING FOR UNVERIFIED)
CREATE POLICY "Verified trainers visible in public discovery"
ON trainer_profiles FOR SELECT
USING (
    verification_status = 'VERIFIED'
    OR user_id = get_current_user_id()
    OR is_super_admin()
);

CREATE POLICY "Trainers can manage own profile"
ON trainer_profiles FOR UPDATE
USING (user_id = get_current_user_id() OR is_super_admin());

-- 6. GYMS & MULTI-GYM MEMBERSHIPS
CREATE POLICY "Gyms are viewable by all authenticated users"
ON gyms FOR SELECT TO authenticated
USING (is_active = TRUE OR is_super_admin());

CREATE POLICY "Gym Managers can update own gym"
ON gyms FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM gym_memberships
        WHERE gym_id = gyms.id
          AND trainer_id = get_current_user_id()
          AND role_in_gym = 'GYM_MANAGER'
    ) OR is_super_admin()
);

CREATE POLICY "Gym memberships viewable by gym staff and super admin"
ON gym_memberships FOR SELECT
USING (
    trainer_id = get_current_user_id()
    OR EXISTS (
        SELECT 1 FROM gym_memberships gm2
        WHERE gm2.gym_id = gym_memberships.gym_id
          AND gm2.trainer_id = get_current_user_id()
          AND gm2.role_in_gym IN ('HEAD_TRAINER', 'GYM_MANAGER')
    )
    OR is_super_admin()
);

-- 7. PACKAGES & CLIENT PACKAGES
CREATE POLICY "Packages are viewable by all authenticated users"
ON packages FOR SELECT TO authenticated
USING (is_active = TRUE OR trainer_id = get_current_user_id() OR is_super_admin());

CREATE POLICY "Trainers can manage own packages"
ON packages FOR ALL
USING (trainer_id = get_current_user_id() OR is_super_admin());

CREATE POLICY "Client packages viewable by client, trainer, and gym manager"
ON client_packages FOR SELECT
USING (
    client_id = get_current_user_id()
    OR trainer_id = get_current_user_id()
    OR is_super_admin()
);

-- 8. RELATIONSHIPS & CONSULTATION REQUESTS
CREATE POLICY "Relationships viewable by client, trainer, head trainer"
ON relationships FOR SELECT
USING (
    client_id = get_current_user_id()
    OR trainer_id = get_current_user_id()
    OR EXISTS (
        SELECT 1 FROM gym_memberships gm
        WHERE gm.gym_id = relationships.gym_id
          AND gm.trainer_id = get_current_user_id()
          AND gm.role_in_gym IN ('HEAD_TRAINER', 'GYM_MANAGER')
    )
    OR is_super_admin()
);

CREATE POLICY "Consultation requests viewable by client and trainer"
ON consultation_requests FOR ALL
USING (
    client_id = get_current_user_id()
    OR trainer_id = get_current_user_id()
    OR is_super_admin()
);

-- 9. PAYMENTS (OFFLINE VERIFICATION QUEUE)
CREATE POLICY "Payments viewable and manageable by client and trainer"
ON payments FOR ALL
USING (
    client_id = get_current_user_id()
    OR trainer_id = get_current_user_id()
    OR is_super_admin()
);

-- 10. CREDIT LEDGER (READ-ONLY FOR USERS, MUTATED ONLY VIA RPC)
CREATE POLICY "Credit ledger viewable by client and trainer"
ON credit_ledger_transactions FOR SELECT
USING (
    client_id = get_current_user_id()
    OR trainer_id = get_current_user_id()
    OR is_super_admin()
);

-- 11. SESSIONS & BOOKINGS
CREATE POLICY "Sessions viewable by client and trainer"
ON sessions FOR SELECT
USING (
    client_id = get_current_user_id()
    OR trainer_id = get_current_user_id()
    OR (session_type = 'OWN_WORKOUT' AND client_id = get_current_user_id())
    OR is_super_admin()
);

CREATE POLICY "Clients and trainers can insert/update own sessions"
ON sessions FOR INSERT
WITH CHECK (
    client_id = get_current_user_id()
    OR trainer_id = get_current_user_id()
    OR is_super_admin()
);

CREATE POLICY "Sessions updates by participants"
ON sessions FOR UPDATE
USING (
    client_id = get_current_user_id()
    OR trainer_id = get_current_user_id()
    OR is_super_admin()
);

-- 12. EXERCISES & WORKOUTS
CREATE POLICY "Exercises viewable by all (global or trainer custom)"
ON exercises FOR SELECT TO authenticated
USING (
    is_custom = FALSE
    OR trainer_id = get_current_user_id()
    OR is_super_admin()
);

CREATE POLICY "Trainers can manage custom exercises"
ON exercises FOR ALL
USING (trainer_id = get_current_user_id() OR is_super_admin());

CREATE POLICY "Workout templates manageable by trainer"
ON workout_templates FOR ALL
USING (trainer_id = get_current_user_id() OR is_super_admin());

CREATE POLICY "Workouts viewable by client and trainer"
ON workouts FOR ALL
USING (
    client_id = get_current_user_id()
    OR trainer_id = get_current_user_id()
    OR (workout_type = 'OWN_WORKOUT' AND client_id = get_current_user_id())
    OR is_super_admin()
);

CREATE POLICY "Workout exercises and sets viewable by workout participants"
ON workout_exercises FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM workouts w
        WHERE w.id = workout_exercises.workout_id
          AND (w.client_id = get_current_user_id() OR w.trainer_id = get_current_user_id() OR is_super_admin())
    )
);

CREATE POLICY "Workout sets viewable by workout participants"
ON workout_sets FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM workout_exercises we
        JOIN workouts w ON w.id = we.workout_id
        WHERE we.id = workout_sets.workout_exercise_id
          AND (w.client_id = get_current_user_id() OR w.trainer_id = get_current_user_id() OR is_super_admin())
    )
);

-- 13. PROGRESS MEASUREMENTS & PHOTOS (PRIVACY SHIELD PROTECTED)
CREATE POLICY "Clients can manage own progress measurements"
ON progress_measurements FOR ALL
USING (client_id = get_current_user_id() OR is_super_admin());

CREATE POLICY "Trainers can view client progress ONLY when opted-in"
ON progress_measurements FOR SELECT
USING (is_client_sharing_health_with_trainer(client_id, get_current_user_id()));

CREATE POLICY "Progress photos private to client"
ON progress_photos FOR ALL
USING (client_id = get_current_user_id() OR is_super_admin());

-- 14. REVIEWS & NOTIFICATIONS
CREATE POLICY "Reviews viewable by all authenticated"
ON reviews FOR SELECT TO authenticated
USING (is_visible = TRUE OR is_super_admin());

CREATE POLICY "Clients can submit reviews"
ON reviews FOR INSERT
WITH CHECK (client_id = get_current_user_id());

CREATE POLICY "Users view own notifications"
ON notifications FOR ALL
USING (user_id = get_current_user_id() OR is_super_admin());

-- 15. FEATURE FLAGS
CREATE POLICY "Feature flags viewable by all users"
ON feature_flags FOR SELECT TO authenticated
USING (TRUE);

CREATE POLICY "Feature flags manageable by Super Admin only"
ON feature_flags FOR ALL
USING (is_super_admin());
