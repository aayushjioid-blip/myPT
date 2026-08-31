// FitTrainer Seed Data Fixtures

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
      share_personal_info_with_trainer: false
    },
    {
      id: 'usr-client-1',
      name: 'Sarah Jenkins',
      email: 'client@test.local',
      role: 'CLIENT',
      avatar: '🏃‍♀️',
      status: 'ACTIVE',
      share_personal_info_with_trainer: false, // Optional sharing test
      age: 28,
      height_cm: 168,
      weight_kg: 64.5,
      fitness_goal: 'Fat Loss & Athletic Conditioning',
      fitness_level: 'Intermediate',
      injuries: 'Past minor rotator cuff strain (left shoulder)',
      medical_info: 'No chronic conditions',
      emergency_contact: '+1-555-0199 (Mike Jenkins)'
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
      languages: ['English', 'Spanish'],
      location: 'Downtown Athletic Club / Hybrid Online',
      trainer_code: 'TRN001',
      upi_id: 'alex.rivera@upi',
      mobile_payment_number: '+1-555-8822',
      cancellation_policy: 'FOUR_HOUR_POLICY',
      custom_cancellation_hours: 4,
      rating: 4.9,
      review_count: 38,
      trial_days_remaining: 320
    },
    {
      id: 'trn-leo',
      user_id: 'usr-trn-unverified',
      name: 'Leo Novak',
      verification_status: 'UNVERIFIED', // Gated: Must NOT appear in public discovery
      bio: 'Independent boxing and HIIT coach.',
      experience_years: 3,
      certifications: ['Boxing Fundamentals'],
      specializations: ['Boxing', 'Conditioning'],
      languages: ['English'],
      location: 'Metro Boxing Studio',
      trainer_code: 'LEO007',
      upi_id: 'leo.boxing@upi',
      mobile_payment_number: '+1-555-3344',
      cancellation_policy: 'NO_PENALTY',
      custom_cancellation_hours: 0,
      rating: 5.0,
      review_count: 2,
      trial_days_remaining: 360
    }
  ],

  gyms: [
    {
      id: 'gym-ironcore',
      name: 'IronCore Fitness Center',
      owner_id: 'usr-gymmgr-1',
      address: '742 Evergreen Blvd, Metro City',
      status: 'ACTIVE'
    }
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
    }
  ],

  // Client-Trainer Relationship states
  relationships: [
    // Initial state: Start disconnected or pending so client can experience full E2E flow
  ],

  client_packages: [],

  payments: [],

  sessions: [],

  exercises: [
    { id: 'ex-1', name: 'Barbell Bench Press', category: 'CHEST', equipment: 'Barbell', target: 'Pectorals, Triceps, Anterior Deltoid' },
    { id: 'ex-2', name: 'Incline Dumbbell Press', category: 'CHEST', equipment: 'Dumbbells', target: 'Upper Chest' },
    { id: 'ex-3', name: 'Cable Chest Flyes', category: 'CHEST', equipment: 'Cable', target: 'Sternal Pectoralis' },
    { id: 'ex-4', name: 'Barbell Deadlift', category: 'BACK', equipment: 'Barbell', target: 'Posterior Chain, Lats, Glutes' },
    { id: 'ex-5', name: 'Lat Pulldown', category: 'BACK', equipment: 'Cable', target: 'Latissimus Dorsi, Biceps' },
    { id: 'ex-6', name: 'Barbell Back Squat', category: 'QUADRICEPS', equipment: 'Barbell', target: 'Quadriceps, Glutes' },
    { id: 'ex-7', name: 'Romanian Deadlift', category: 'HAMSTRINGS', equipment: 'Dumbbells', target: 'Hamstrings, Glutes' },
    { id: 'ex-8', name: 'Overhead Shoulder Press', category: 'SHOULDERS', equipment: 'Barbell', target: 'Anterior & Medial Deltoids' },
    { id: 'ex-9', name: 'Dumbbell Lateral Raise', category: 'SHOULDERS', equipment: 'Dumbbells', target: 'Lateral Deltoid' },
    { id: 'ex-10', name: 'Incline Bicep Curl', category: 'BICEPS', equipment: 'Dumbbells', target: 'Biceps Brachii' },
    { id: 'ex-11', name: 'Triceps Rope Pushdown', category: 'TRICEPS', equipment: 'Cable', target: 'Triceps Lateral & Medial Head' },
    { id: 'ex-12', name: 'Plank', category: 'CORE', equipment: 'Bodyweight', target: 'Transverse Abdominis' }
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
        { exercise_id: 'ex-9', name: 'Dumbbell Lateral Raise', sets: 3, reps: 15, weight: 10, rest: 45 },
        { exercise_id: 'ex-11', name: 'Triceps Rope Pushdown', sets: 3, reps: 12, weight: 25, rest: 45 }
      ]
    }
  ],

  workouts: [],

  progress_measurements: [
    { id: 'm-1', client_id: 'usr-client-1', date: '2026-06-01', weight: 68.0, waist: 76, chest: 92, body_fat: 24.5 },
    { id: 'm-2', client_id: 'usr-client-1', date: '2026-07-01', weight: 66.2, waist: 74, chest: 91, body_fat: 23.0 },
    { id: 'm-3', client_id: 'usr-client-1', date: '2026-08-01', weight: 64.5, waist: 72, chest: 90, body_fat: 21.8 }
  ],

  feature_flags: {
    advanced_trainer_search: false,       // Default false as corrected by user
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
      read: false,
      timestamp: new Date().toISOString()
    }
  ]
};
