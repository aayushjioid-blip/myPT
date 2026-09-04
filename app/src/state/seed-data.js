// FitTrainer Seed Data Fixtures (Stage 1B Master)

export const initialSeedData = {
  // Test Accounts for all 5 roles
  users: [
    {
      id: 'usr-admin-1',
      name: 'Super Admin',
      email: 'admin@test.local',
      role: 'SUPER_ADMIN',
      avatar: '🛡️',
      status: 'ACTIVE',
      share_personal_info_with_trainer: false
    },
    {
      id: 'usr-gymmgr-1',
      name: 'Elena Rostova',
      email: 'gymmanager@test.local',
      role: 'GYM_MANAGER',
      avatar: '🏢',
      status: 'ACTIVE',
      gym_id: 'gym-ironcore',
      share_personal_info_with_trainer: false
    },
    {
      id: 'usr-headtrn-1',
      name: 'Marcus Vance',
      email: 'headtrainer@test.local',
      role: 'HEAD_TRAINER',
      avatar: '👑',
      status: 'ACTIVE',
      gym_id: 'gym-ironcore',
      share_personal_info_with_trainer: false
    },
    {
      id: 'usr-trn-1',
      name: 'Alex Rivera',
      email: 'trainer@test.local',
      role: 'TRAINER',
      avatar: '🏋️',
      status: 'ACTIVE',
      gym_id: 'gym-ironcore',
      share_personal_info_with_trainer: false
    },
    {
      id: 'usr-trn-2',
      name: 'Maya Lin',
      email: 'maya.trainer@test.local',
      role: 'TRAINER',
      avatar: '🤸‍♀️',
      status: 'ACTIVE',
      gym_id: 'gym-ironcore',
      share_personal_info_with_trainer: false
    },
    {
      id: 'usr-client-1',
      name: 'Sarah Jenkins',
      email: 'client@test.local',
      role: 'CLIENT',
      avatar: '🏃‍♀️',
      status: 'ACTIVE',
      share_personal_info_with_trainer: false, // Optional sharing control
      age: 28,
      height_cm: 168,
      weight_kg: 64.5,
      fitness_goal: 'Fat Loss & Athletic Conditioning',
      fitness_level: 'Intermediate',
      injuries: 'Past minor rotator cuff strain (left shoulder)',
      medical_info: 'No chronic conditions',
      emergency_contact: '+1-555-0199 (Mike Jenkins)'
    },
    {
      id: 'usr-client-2',
      name: 'David Kim',
      email: 'david.client@test.local',
      role: 'CLIENT',
      avatar: '🧗',
      status: 'ACTIVE',
      share_personal_info_with_trainer: true,
      age: 34,
      height_cm: 178,
      weight_kg: 82.0,
      fitness_goal: 'Hypertrophy & Strength',
      fitness_level: 'Advanced',
      injuries: 'None',
      medical_info: 'Asthma (carries inhaler)',
      emergency_contact: '+1-555-4422 (Hannah Kim)'
    },
    // Unverified Trainer for discovery test
    {
      id: 'usr-trn-unverified',
      name: 'Leo Novak',
      email: 'leo.unverified@test.local',
      role: 'TRAINER',
      avatar: '🥊',
      status: 'ACTIVE',
      share_personal_info_with_trainer: false
    }
  ],

  trainers: [
    {
      id: 'trn-alex',
      user_id: 'usr-trn-1',
      name: 'Alex Rivera',
      verification_status: 'VERIFIED', // Appears in public search
      bio: 'NASM-certified Elite Performance Coach with 8+ years specializing in hypertrophy, mobility, and fat loss.',
      experience_years: 8,
      certifications: ['NASM-CPT', 'CSCS', 'Precision Nutrition L1'],
      specializations: ['Hypertrophy', 'Fat Loss', 'Mobility', 'Strength'],
      skills: ['Barbell Mastery', 'Postural Restoration', 'Kettlebell Flow', 'HIIT'],
      services: ['1-on-1 In-Person PT', 'Nutrition Consulting', 'Custom Workout Programming', 'Bi-Weekly Body Composition'],
      languages: ['English', 'Spanish'],
      location: 'Downtown Athletic Club / Hybrid Online',
      trainer_code: 'TRN001',
      upi_id: 'alex.rivera@upi',
      mobile_payment_number: '+1-555-8822',
      cancellation_policy: 'FOUR_HOUR_POLICY',
      custom_cancellation_hours: 4,
      rating: 4.9,
      review_count: 38,
      trial_days_remaining: 320,
      working_hours: {
        monday: { start: '08:00', end: '19:00', active: true, slot_capacity: 2 },
        tuesday: { start: '08:00', end: '19:00', active: true, slot_capacity: 2 },
        wednesday: { start: '08:00', end: '19:00', active: true, slot_capacity: 2 },
        thursday: { start: '08:00', end: '19:00', active: true, slot_capacity: 2 },
        friday: { start: '08:00', end: '18:00', active: true, slot_capacity: 2 },
        saturday: { start: '09:00', end: '14:00', active: true, slot_capacity: 1 },
        sunday: { start: '10:00', end: '13:00', active: false, slot_capacity: 1 }
      }
    },
    {
      id: 'trn-maya',
      user_id: 'usr-trn-2',
      name: 'Maya Lin',
      verification_status: 'VERIFIED',
      bio: 'Yoga, Calisthenics, and Athletic Functional Conditioning Coach with Olympic lifting background.',
      experience_years: 6,
      certifications: ['ACE-CPT', 'RYT-500 Yoga Master', 'USAW L1'],
      specializations: ['Mobility', 'Functional Training', 'Calisthenics', 'Core Strength'],
      skills: ['Bodyweight Acrobatics', 'Flexibility Training', 'Breathwork', 'Rehabilitation'],
      services: ['Functional Movement Screen', 'Small Group Calisthenics', '1-on-1 PT'],
      languages: ['English', 'Mandarin'],
      location: 'IronCore Fitness Center',
      trainer_code: 'MAYA02',
      upi_id: 'maya.lin@upi',
      mobile_payment_number: '+1-555-7733',
      cancellation_policy: 'FOUR_HOUR_POLICY',
      custom_cancellation_hours: 4,
      rating: 4.95,
      review_count: 24,
      trial_days_remaining: 340,
      working_hours: {
        monday: { start: '07:00', end: '16:00', active: true, slot_capacity: 2 },
        tuesday: { start: '07:00', end: '16:00', active: true, slot_capacity: 2 },
        wednesday: { start: '07:00', end: '16:00', active: true, slot_capacity: 2 },
        thursday: { start: '07:00', end: '16:00', active: true, slot_capacity: 2 },
        friday: { start: '07:00', end: '15:00', active: true, slot_capacity: 2 },
        saturday: { start: '08:00', end: '12:00', active: true, slot_capacity: 2 },
        sunday: { start: '00:00', end: '00:00', active: false, slot_capacity: 1 }
      }
    },
    {
      id: 'trn-leo',
      user_id: 'usr-trn-unverified',
      name: 'Leo Novak',
      verification_status: 'UNVERIFIED', // Gated: Must NOT appear in public discovery
      bio: 'Independent boxing and high-intensity combat conditioning coach.',
      experience_years: 3,
      certifications: ['Boxing Fundamentals Coach'],
      specializations: ['Boxing', 'Conditioning'],
      skills: ['Pad Work', 'Footwork Drills', 'Heavy Bag Conditioning'],
      services: ['Boxing 1-on-1', 'HIIT Cardio'],
      languages: ['English'],
      location: 'Metro Boxing Studio',
      trainer_code: 'LEO007',
      upi_id: 'leo.boxing@upi',
      mobile_payment_number: '+1-555-3344',
      cancellation_policy: 'NO_PENALTY',
      custom_cancellation_hours: 0,
      rating: 5.0,
      review_count: 2,
      trial_days_remaining: 360,
      working_hours: {
        monday: { start: '10:00', end: '20:00', active: true, slot_capacity: 1 },
        tuesday: { start: '10:00', end: '20:00', active: true, slot_capacity: 1 },
        wednesday: { start: '10:00', end: '20:00', active: true, slot_capacity: 1 },
        thursday: { start: '10:00', end: '20:00', active: true, slot_capacity: 1 },
        friday: { start: '10:00', end: '20:00', active: true, slot_capacity: 1 },
        saturday: { start: '10:00', end: '16:00', active: true, slot_capacity: 1 },
        sunday: { start: '00:00', end: '00:00', active: false, slot_capacity: 1 }
      }
    }
  ],

  gyms: [
    {
      id: 'gym-ironcore',
      name: 'IronCore Fitness Center',
      owner_id: 'usr-gymmgr-1',
      head_trainer_id: 'usr-headtrn-1',
      address: '742 Evergreen Blvd, Metro City',
      phone: '+1-555-0900',
      operating_hours: '06:00 - 22:00 Daily',
      max_floor_capacity: 40,
      status: 'ACTIVE',
      amenities: ['Olympic Lifting Platforms', 'Sauna & Ice Bath', 'Turf Sprint Track', 'Private Assessment Rooms']
    }
  ],

  gym_trainer_affiliations: [
    { id: 'aff-1', gym_id: 'gym-ironcore', trainer_id: 'trn-alex', status: 'ACTIVE', role: 'STAFF_TRAINER' },
    { id: 'aff-2', gym_id: 'gym-ironcore', trainer_id: 'trn-maya', status: 'ACTIVE', role: 'STAFF_TRAINER' }
  ],

  packages: [
    {
      id: 'pkg-10pt',
      trainer_id: 'trn-alex',
      name: '10 PT Sessions Starter Pack',
      description: 'Comprehensive 1-on-1 coaching with personalized nutrition & workout programming.',
      sessions: 10,
      price: 499.00,
      validity_days: 40, // default sessions * 4
      validity_mode: 'SESSIONS_MULTIPLIED_BY_4',
      session_duration: 60,
      status: 'ACTIVE'
    },
    {
      id: 'pkg-20pt',
      trainer_id: 'trn-alex',
      name: '20 PT Sessions Transformation',
      description: 'Full body transformation program with bi-weekly body composition scans.',
      sessions: 20,
      price: 899.00,
      validity_days: 80,
      validity_mode: 'SESSIONS_MULTIPLIED_BY_4',
      session_duration: 60,
      status: 'ACTIVE'
    },
    {
      id: 'pkg-10maya',
      trainer_id: 'trn-maya',
      name: '10 Mobility & Calisthenics Sessions',
      description: 'Progressive bodyweight strength, core endurance, and deep joint mobility.',
      sessions: 10,
      price: 479.00,
      validity_days: 45,
      validity_mode: 'CUSTOM',
      session_duration: 60,
      status: 'ACTIVE'
    }
  ],

  // Client-Trainer Relationship states
  relationships: [],

  client_packages: [],

  payments: [],

  sessions: [],

  // 12 Full Categories of Global + Custom Exercises
  exercises: [
    // 1. CHEST
    { id: 'ex-1', name: 'Barbell Bench Press', category: 'Chest', equipment: 'Barbell', target: 'Pectorals, Triceps, Anterior Deltoid', description: 'Compound chest press on a flat bench for mass and power.' },
    { id: 'ex-2', name: 'Incline Dumbbell Press', category: 'Chest', equipment: 'Dumbbells', target: 'Clavicular Upper Chest', description: 'Angled pressing movement focusing on upper pec development.' },
    { id: 'ex-3', name: 'Cable Chest Flyes', category: 'Chest', equipment: 'Cable', target: 'Sternal Pectoralis', description: 'Continuous tension chest isolation exercise.' },
    
    // 2. BACK
    { id: 'ex-4', name: 'Barbell Deadlift', category: 'Back', equipment: 'Barbell', target: 'Posterior Chain, Lats, Spinal Erectors', description: 'Full-body sovereign strength lift originating from the floor.' },
    { id: 'ex-5', name: 'Lat Pulldown', category: 'Back', equipment: 'Cable', target: 'Latissimus Dorsi, Biceps', description: 'Vertical pulling movement for back width and posture.' },
    { id: 'ex-6', name: 'Seated Cable Row', category: 'Back', equipment: 'Cable', target: 'Rhomboids, Middle Trapezius', description: 'Horizontal pull for mid-back thickness and scapular retraction.' },

    // 3. LEGS (Quadriceps)
    { id: 'ex-7', name: 'Barbell Back Squat', category: 'Legs', equipment: 'Barbell', target: 'Quadriceps, Glutes', description: 'King of lower body exercises for strength and leg development.' },
    { id: 'ex-8', name: 'Bulgarian Split Squat', category: 'Legs', equipment: 'Dumbbells', target: 'Quadriceps, Gluteus Medius', description: 'Unilateral quad-dominant leg challenge.' },
    { id: 'ex-9', name: 'Leg Press', category: 'Legs', equipment: 'Machine', target: 'Quadriceps, Adductors', description: 'Heavy quad volume with reduced lower back loading.' },

    // 4. SHOULDERS
    { id: 'ex-10', name: 'Overhead Barbell Press', category: 'Shoulders', equipment: 'Barbell', target: 'Anterior & Medial Deltoids', description: 'Standing strict vertical press for shoulder power.' },
    { id: 'ex-11', name: 'Dumbbell Lateral Raise', category: 'Shoulders', equipment: 'Dumbbells', target: 'Lateral Deltoid', description: 'Side shoulder isolation for boulder shoulder width.' },
    { id: 'ex-12', name: 'Face Pulls', category: 'Shoulders', equipment: 'Cable', target: 'Rear Delts, Rotator Cuff', description: 'Key bulletproofing movement for shoulder health and posture.' },

    // 5. BICEPS
    { id: 'ex-13', name: 'Incline Dumbbell Bicep Curl', category: 'Biceps', equipment: 'Dumbbells', target: 'Biceps Long Head', description: 'Deep stretch curl on an inclined bench.' },
    { id: 'ex-14', name: 'Hammer Curls', category: 'Biceps', equipment: 'Dumbbells', target: 'Brachialis, Forearms', description: 'Neutral grip curl for upper arm thickness.' },

    // 6. TRICEPS
    { id: 'ex-15', name: 'Triceps Rope Pushdown', category: 'Triceps', equipment: 'Cable', target: 'Triceps Lateral & Medial Head', description: 'Constant cable tension for horseshoe triceps.' },
    { id: 'ex-16', name: 'Skull Crushers (Lying Triceps Ext)', category: 'Triceps', equipment: 'EZ-Bar', target: 'Triceps Long Head', description: 'Overhead stretch for triceps mass.' },

    // 7. FOREARMS
    { id: 'ex-17', name: 'Barbell Wrist Curls', category: 'Forearms', equipment: 'Barbell', target: 'Wrist Flexors, Grip', description: 'Forearm hypertrophy and crushing grip strength.' },
    { id: 'ex-18', name: 'Farmers Walk', category: 'Forearms', equipment: 'Dumbbells / Trap Bar', target: 'Grip, Trapezius, Core', description: 'Heavy loaded carry building endurance and forearm density.' },

    // 8. GLUTES
    { id: 'ex-19', name: 'Barbell Hip Thrust', category: 'Glutes', equipment: 'Barbell / Bench', target: 'Gluteus Maximus', description: 'Top tier glute activation with peak horizontal contraction.' },
    { id: 'ex-20', name: 'Cable Kickbacks', category: 'Glutes', equipment: 'Cable', target: 'Gluteus Medius & Maximus', description: 'Isolated glute shaping and hip stability.' },

    // 9. HIPS
    { id: 'ex-21', name: 'Hip Abduction Machine', category: 'Hips', equipment: 'Machine', target: 'Gluteus Medius, Tensor Fasciae Latae', description: 'Hip stabilization and lateral strength.' },
    { id: 'ex-22', name: '90-90 Hip Mobility Flow', category: 'Hips', equipment: 'Bodyweight', target: 'Internal & External Hip Rotators', description: 'Essential hip joint mobility and impingement prevention.' },

    // 10. CORE
    { id: 'ex-23', name: 'Plank with Shoulder Taps', category: 'Core', equipment: 'Bodyweight', target: 'Transverse Abdominis, Anti-Rotation', description: 'Dynamic anti-rotational core stabilization.' },
    { id: 'ex-24', name: 'Hanging Leg Raises', category: 'Core', equipment: 'Pull-up Bar', target: 'Rectus Abdominis, Hip Flexors', description: 'Lower ab isolation and spinal decompression.' },
    { id: 'ex-25', name: 'Cable Woodchoppers', category: 'Core', equipment: 'Cable', target: 'Obliques, Rotational Power', description: 'Athletic rotational strength.' },

    // 11. CALVES
    { id: 'ex-26', name: 'Standing Calf Raise', category: 'Calves', equipment: 'Machine / Barbell', target: 'Gastrocnemius', description: 'Straight-leg calf extension for diamond calves.' },
    { id: 'ex-27', name: 'Seated Calf Raise', category: 'Calves', equipment: 'Machine', target: 'Soleus', description: 'Bent-knee calf work targeting the deep soleus muscle.' },

    // 12. FULL BODY
    { id: 'ex-28', name: 'Kettlebell Clean & Press', category: 'Full Body', equipment: 'Kettlebell', target: 'Full Body Power, Shoulders, Glutes', description: 'Dynamic explosive full-body movement.' },
    { id: 'ex-29', name: 'Barbell Thruster', category: 'Full Body', equipment: 'Barbell', target: 'Quads, Shoulders, Cardiovascular', description: 'Front squat fluidly transitioning into an overhead press.' },
    { id: 'ex-30', name: 'Burpee Box Jump', category: 'Full Body', equipment: 'Plyo Box', target: 'Conditioning, Explosive Power', description: 'High intensity athletic conditioning test.' }
  ],

  workout_templates: [
    {
      id: 'tmpl-upper-hypertrophy',
      trainer_id: 'trn-alex',
      name: 'Upper Body Hypertrophy Focus',
      description: 'High intensity upper body power and hypertrophy sequence.',
      exercises: [
        { exercise_id: 'ex-1', name: 'Barbell Bench Press', sets: 3, reps: 10, weight: 60, rest: 60 },
        { exercise_id: 'ex-5', name: 'Lat Pulldown', sets: 3, reps: 12, weight: 50, rest: 60 },
        { exercise_id: 'ex-11', name: 'Dumbbell Lateral Raise', sets: 3, reps: 15, weight: 10, rest: 45 },
        { exercise_id: 'ex-15', name: 'Triceps Rope Pushdown', sets: 3, reps: 12, weight: 25, rest: 45 }
      ]
    },
    {
      id: 'tmpl-lower-strength',
      trainer_id: 'trn-alex',
      name: 'Lower Body & Glute Power',
      description: 'Quad strength, glute thrusts, and posterior chain resilience.',
      exercises: [
        { exercise_id: 'ex-7', name: 'Barbell Back Squat', sets: 4, reps: 8, weight: 75, rest: 90 },
        { exercise_id: 'ex-19', name: 'Barbell Hip Thrust', sets: 3, reps: 10, weight: 80, rest: 60 },
        { exercise_id: 'ex-8', name: 'Bulgarian Split Squat', sets: 3, reps: 10, weight: 16, rest: 60 },
        { exercise_id: 'ex-26', name: 'Standing Calf Raise', sets: 4, reps: 15, weight: 45, rest: 45 }
      ]
    },
    {
      id: 'tmpl-mobility-core',
      trainer_id: 'trn-maya',
      name: 'Core Stability & Hip Mobility',
      description: 'Functional movement screening, anti-rotation core, and deep hip opener.',
      exercises: [
        { exercise_id: 'ex-22', name: '90-90 Hip Mobility Flow', sets: 3, reps: 10, weight: 0, rest: 30 },
        { exercise_id: 'ex-23', name: 'Plank with Shoulder Taps', sets: 3, reps: 20, weight: 0, rest: 45 },
        { exercise_id: 'ex-24', name: 'Hanging Leg Raises', sets: 3, reps: 12, weight: 0, rest: 60 }
      ]
    }
  ],

  workouts: [],

  // Comprehensive 8-point body circumference & metrics tracking
  progress_measurements: [
    { 
      id: 'm-1', 
      client_id: 'usr-client-1', 
      date: '2026-06-01', 
      weight: 68.0, 
      height_cm: 168,
      bmi: 24.1,
      body_fat: 24.5, 
      chest: 94.0, 
      waist: 76.0, 
      hips: 99.0, 
      biceps: 28.5, 
      thighs: 58.0, 
      calves: 37.0,
      photos: { front: '📸 Front pose 01/06', side: '📸 Side pose 01/06', back: '📸 Back pose 01/06' },
      notes: 'Initial fitness baseline assessment.'
    },
    { 
      id: 'm-2', 
      client_id: 'usr-client-1', 
      date: '2026-07-01', 
      weight: 66.2, 
      height_cm: 168,
      bmi: 23.5,
      body_fat: 23.0, 
      chest: 92.5, 
      waist: 74.0, 
      hips: 97.5, 
      biceps: 28.8, 
      thighs: 56.5, 
      calves: 36.8,
      photos: { front: '📸 Front pose 01/07', side: '📸 Side pose 01/07', back: '📸 Back pose 01/07' },
      notes: 'Month 1 check-in: Noticeable waist reduction.'
    },
    { 
      id: 'm-3', 
      client_id: 'usr-client-1', 
      date: '2026-08-01', 
      weight: 64.5, 
      height_cm: 168,
      bmi: 22.9,
      body_fat: 21.8, 
      chest: 91.0, 
      waist: 72.0, 
      hips: 96.0, 
      biceps: 29.2, 
      thighs: 55.0, 
      calves: 36.5,
      photos: { front: '📸 Front pose 01/08', side: '📸 Side pose 01/08', back: '📸 Back pose 01/08' },
      notes: 'Month 2 check-in: Lean muscle gains and sustained fat loss.'
    }
  ],

  // Client Reviews & Ratings
  reviews: [
    {
      id: 'rev-1',
      trainer_id: 'trn-alex',
      client_id: 'usr-client-2',
      client_name: 'David Kim',
      rating: 5,
      comment: 'Alex is phenomenal! He corrected my squat mechanics and programmed a tailored hypertrophy routine that added 10kg to my lifts.',
      created_at: '2026-08-15T14:30:00Z'
    },
    {
      id: 'rev-2',
      trainer_id: 'trn-alex',
      client_id: 'usr-client-1',
      client_name: 'Sarah Jenkins',
      rating: 5,
      comment: 'Super structured workouts and attentive coaching. Down 3.5kg and feeling stronger than ever!',
      created_at: '2026-08-20T09:15:00Z'
    },
    {
      id: 'rev-3',
      trainer_id: 'trn-maya',
      client_id: 'usr-client-1',
      client_name: 'Sarah Jenkins',
      rating: 5,
      comment: 'Maya helped fix my shoulder impingement through calisthenics and mobility flows. Incredible instructor!',
      created_at: '2026-08-22T11:00:00Z'
    }
  ],

  feature_flags: {
    advanced_trainer_search: false,       // Default false: Gated advanced filters
    client_personal_information: true,   // Default true (opt-in controls sharing)
    online_payments: false,              // Default false (offline payment simulation)
    trainer_reviews: true,
    whatsapp_notifications: false
  },

  notifications: [
    {
      id: 'notif-1',
      user_id: 'usr-client-1',
      title: 'Welcome to FitTrainer',
      message: 'Explore verified trainers to start your fitness journey!',
      type: 'INFO',
      read: false,
      timestamp: new Date().toISOString()
    }
  ]
};
