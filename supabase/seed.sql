-- ============================================================================
-- FitTrainer (myPT) — Production Seed Data
-- Matches the Stage 1.5 5-Role Demo Personas & Business Entities
-- ============================================================================

-- 1. SEED RUNTIME FEATURE FLAGS
INSERT INTO feature_flags (key, description, is_enabled) VALUES
('advanced_trainer_search', 'Enables multi-parameter filters in Client Discovery (Default: FALSE)', FALSE),
('client_personal_information', 'Enables medical/injury intake collection (Default: TRUE)', TRUE),
('online_payments', 'Enables mock online payment gateway vs offline UPI (Default: FALSE)', FALSE),
('trainer_reviews', 'Enables 1-5 star review submission on trainer profiles (Default: TRUE)', TRUE),
('client_upcoming_workout_visibility', 'Displays tomorrow scheduled workout on client hub (Default: TRUE)', TRUE)
ON CONFLICT (key) DO UPDATE SET is_enabled = EXCLUDED.is_enabled;

-- 2. SEED CORE USERS (5 ROLES + DEMO PERSONAS)
INSERT INTO users (id, email, phone, name, avatar_url, role, is_active) VALUES
('00000000-0000-0000-0000-000000000001', 'sarah.jenkins@fitapp.dev', '+1555123456', 'Sarah Jenkins', '👩', 'CLIENT', TRUE),
('00000000-0000-0000-0000-000000000002', 'alex.rivera@fitapp.dev', '+1555234567', 'Alex Rivera', '🏋️', 'TRAINER', TRUE),
('00000000-0000-0000-0000-000000000003', 'maya.lin@fitapp.dev', '+1555345678', 'Maya Lin', '🧘', 'TRAINER', TRUE),
('00000000-0000-0000-0000-000000000004', 'leo.novak@fitapp.dev', '+1555456789', 'Leo Novak', '🥊', 'TRAINER', TRUE),
('00000000-0000-0000-0000-000000000005', 'marcus.vance@fitapp.dev', '+1555567890', 'Marcus Vance', '👑', 'HEAD_TRAINER', TRUE),
('00000000-0000-0000-0000-000000000006', 'elena.rostova@fitapp.dev', '+1555678901', 'Elena Rostova', '🏢', 'GYM_MANAGER', TRUE),
('00000000-0000-0000-0000-000000000007', 'admin@fitapp.dev', '+1555789012', 'Demo Super Admin', '🛡️', 'SUPER_ADMIN', TRUE)
ON CONFLICT (id) DO NOTHING;

-- 3. SEED CLIENT HEALTH PROFILE (DEFAULT SHARING = FALSE)
INSERT INTO client_health_profiles (
    user_id, age, height_cm, weight_kg, fitness_goal, injuries, medical_info, share_personal_info_with_trainer
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    28,
    168.0,
    64.5,
    'Fat Loss & Hypertrophy',
    'Mild left shoulder impingement on overhead presses',
    'Asthma (carries inhaler during high intensity sessions)',
    FALSE -- Strict privacy consent default
) ON CONFLICT (user_id) DO NOTHING;

-- 4. SEED GYM FACILITY
INSERT INTO gyms (
    id, name, slug, description, location_address, contact_phone, contact_email, floor_capacity, operating_hours
) VALUES (
    '10000000-0000-0000-0000-000000000001',
    'IronCore Fitness Center',
    'ironcore-metro',
    'Premier high-performance strength and conditioning facility.',
    '742 Evergreen Blvd, Metro City',
    '+1-555-IRON-CORE',
    'contact@ironcore.fit',
    40,
    '06:00 - 22:00 Daily'
) ON CONFLICT (id) DO NOTHING;

-- 5. SEED TRAINER PROFILES (VERIFIED & UNVERIFIED GATING)
INSERT INTO trainer_profiles (
    user_id, trainer_code, bio, years_experience, rating, review_count, verification_status, is_independent, hourly_rate
) VALUES
-- Alex Rivera: Verified Coach
('00000000-0000-0000-0000-000000000002', 'TRN001', 'NASM Certified Master Trainer specializing in biomechanics, hypertrophy, and sustainable body recomposition.', 8, 4.90, 24, 'VERIFIED', FALSE, 75.00),
-- Maya Lin: Verified Coach
('00000000-0000-0000-0000-000000000003', 'MAYA02', 'ACE Certified & Yoga Alliance RYT-500. Functional movement patterns, calisthenics, and core stabilization.', 6, 4.95, 19, 'VERIFIED', FALSE, 65.00),
-- Leo Novak: UNVERIFIED Coach (Hidden from public search, accessible via direct code LEO007)
('00000000-0000-0000-0000-000000000004', 'LEO007', 'Boxing coach and high-intensity interval conditioning specialist.', 3, 4.70, 5, 'UNVERIFIED', TRUE, 50.00),
-- Marcus Vance: Head Trainer Profile
('00000000-0000-0000-0000-000000000005', 'HEAD01', 'Director of Performance & Head Coach at IronCore Fitness.', 12, 5.00, 48, 'VERIFIED', FALSE, 100.00)
ON CONFLICT (user_id) DO NOTHING;

-- 6. SEED MULTI-GYM MEMBERSHIPS
INSERT INTO gym_memberships (gym_id, trainer_id, role_in_gym, is_primary) VALUES
('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000006', 'GYM_MANAGER', TRUE),
('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000005', 'HEAD_TRAINER', TRUE),
('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'TRAINER', TRUE),
('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000003', 'TRAINER', TRUE)
ON CONFLICT (gym_id, trainer_id) DO NOTHING;

-- 7. SEED 12-CATEGORY GLOBAL EXERCISE DIRECTORY
INSERT INTO exercises (id, name, category, equipment, target_muscles, description, is_custom) VALUES
('20000000-0000-0000-0000-000000000001', 'Barbell Flat Bench Press', 'CHEST', 'Barbell + Bench', 'Pectoralis Major, Anterior Deltoid, Triceps', 'Retract scapulae, touch lower sternum and press with leg drive.', FALSE),
('20000000-0000-0000-0000-000000000002', 'Incline Dumbbell Press', 'CHEST', 'Dumbbells + Incline Bench', 'Clavicular Upper Chest, Anterior Deltoids', '30-degree incline for optimal upper chest fiber recruitment.', FALSE),
('20000000-0000-0000-0000-000000000003', 'Lat Pulldown', 'BACK', 'Cable Machine', 'Latissimus Dorsi, Teres Major, Biceps', 'Full vertical stretch at top, pull to upper clavicle with chest tall.', FALSE),
('20000000-0000-0000-0000-000000000004', 'Barbell Conventional Deadlift', 'BACK', 'Barbell', 'Erector Spinae, Gluteus, Hamstrings, Lats', 'Hinge at hips, brace abdominal wall, pull slack out of bar.', FALSE),
('20000000-0000-0000-0000-000000000005', 'Barbell Back Squat', 'LEGS', 'Barbell + Squat Rack', 'Quadriceps, Gluteus Maximus, Adductors', 'Descend below parallel with neutral spine and knee tracking.', FALSE),
('20000000-0000-0000-0000-000000000006', 'Romanian Deadlift (RDL)', 'LEGS', 'Barbell or Dumbbells', 'Hamstrings, Gluteus Maximus', 'Hip hinge with soft knees, feel deep hamstring stretch at bottom.', FALSE),
('20000000-0000-0000-0000-000000000007', 'Overhead Dumbbell Shoulder Press', 'SHOULDERS', 'Dumbbells', 'Anterior & Lateral Deltoids, Triceps', 'Press in scapular plane without arching lumbar spine.', FALSE),
('20000000-0000-0000-0000-000000000008', 'Dumbbell Lateral Raise', 'SHOULDERS', 'Dumbbells', 'Lateral Deltoid', 'Lead with elbows slightly forward in the scapular plane.', FALSE),
('20000000-0000-0000-0000-000000000009', 'Incline Dumbbell Bicep Curl', 'BICEPS', 'Dumbbells + Incline Bench', 'Biceps Brachii (Long Head)', 'Supinate wrists at top for peak bicep contraction.', FALSE),
('20000000-0000-0000-0000-000000000010', 'Triceps Rope Pushdown', 'TRICEPS', 'Cable Machine', 'Triceps Brachii (Lateral & Medial Head)', 'Flare rope apart at bottom with elbows pinned to ribs.', FALSE),
('20000000-0000-0000-0000-000000000011', 'Barbell Hip Thrust', 'GLUTES', 'Barbell + Hip Thrust Bench', 'Gluteus Maximus', 'Full hip extension at lockout with chin tucked and posterior pelvic tilt.', FALSE),
('20000000-0000-0000-0000-000000000012', 'Standing Calf Raise', 'CALVES', 'Calf Machine or Step', 'Gastrocnemius, Soleus', 'Full stretch at bottom, 2-second isometric pause at peak.', FALSE),
('20000000-0000-0000-0000-000000000013', 'Plank with Shoulder Taps', 'CORE', 'Bodyweight', 'Rectus Abdominis, Transverse Abdominis, Obliques', 'Maintain anti-rotational core stability.', FALSE),
('20000000-0000-0000-0000-000000000014', 'Barbell Clean and Press', 'FULL_BODY', 'Barbell', 'Full Kinetic Chain', 'Explosive triple extension into overhead lockout.', FALSE)
ON CONFLICT (id) DO NOTHING;

-- 8. SEED PACKAGES (ALEX RIVERA)
INSERT INTO packages (
    id, trainer_id, gym_id, name, description, sessions, price, validity_days
) VALUES
('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '10 PT Sessions Starter Pack', 'Comprehensive 1-on-1 coaching, nutrition guidance, and bi-weekly body scans.', 10, 499.00, 45),
('30000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '20 PT Elite Body Transformation', 'Full transformation program with 3x weekly training, mobility routines, and app support.', 20, 899.00, 90)
ON CONFLICT (id) DO NOTHING;
