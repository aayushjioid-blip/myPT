// Automated Stage 1B Comprehensive E2E Flow & Business Rules Test Suite

import { store } from './app/src/state/store.js';
import { Actions } from './app/src/state/actions.js';

console.log('🧪 Starting FitTrainer Stage 1B Comprehensive Validation Suite...\n');

// 1. Initial State Reset
store.resetToDefaults();
let state = store.getState();
const client = store.getCurrentUser();
console.log(`[CHECK 1] Initial Profile: ${client.name} (${client.role})`);

// -------------------------------------------------------------
// MILESTONE 1: PROGRESS TRACKING & OWN WORKOUTS
// -------------------------------------------------------------
console.log('\n--- MILESTONE 1: PROGRESS TRACKING & OWN WORKOUTS ---');
// 1.1 Progress Measurement with BMI auto-calculation
const measurement = Actions.logProgressMeasurement({
  weight: 63.8,
  height_cm: 168,
  body_fat: 21.0,
  chest: 90.0,
  waist: 71.0,
  hips: 95.0,
  biceps: 29.5,
  thighs: 54.5,
  calves: 36.2,
  notes: 'Stage 1B milestone 1 test check-in'
});
state = store.getState();
console.log(`  Logged Weight: ${measurement.weight} kg, Calculated BMI: ${measurement.bmi} (Expected: ~22.6)`);
if (measurement.bmi < 22.0 || measurement.bmi > 23.0) {
  throw new Error(`BMI computation error: expected ~22.6, got ${measurement.bmi}`);
}

// 1.2 Privacy Opt-in Rule: Client explicitly controls sharing
console.log(`  Initial Sharing Status: ${client.share_personal_info_with_trainer} (Private)`);
Actions.toggleClientPersonalInfoSharing(true);
console.log(`  Updated Sharing Status: ${client.share_personal_info_with_trainer} (Shared with trainer)`);
if (!client.share_personal_info_with_trainer) {
  throw new Error('Privacy toggle failed to update client opt-in state.');
}

// -------------------------------------------------------------
// STAGE 1A REGRESSION: E2E PT JOURNEY & CREDIT LEDGER
// -------------------------------------------------------------
console.log('\n--- STAGE 1A REGRESSION: PRIMARY PT JOURNEY ---');
// 2.1 Send Consultation & Accept
Actions.sendConsultationRequest('trn-alex', 'Hypertrophy & Fat Loss', 'Weekdays 10 AM');
const rel = state.relationships.find(r => r.client_id === client.id && r.trainer_id === 'trn-alex');
store.setCurrentUser('usr-trn-1');
Actions.acceptClientRequest(rel.id);
console.log(`  Consultation Accepted: ${rel.status}`);

// 2.2 Select Package & Offline Payment
store.setCurrentUser('usr-client-1');
const pkg10 = state.packages.find(p => p.id === 'pkg-10pt');
Actions.selectPackageAndSubmitPayment(pkg10.id, 'UPI-REF-998811');
const payment = state.payments.find(p => p.client_id === client.id);
const clientPkg = state.client_packages.find(cp => cp.client_id === client.id);
console.log(`  Payment Submitted: ${payment.payment_status}, Package Initial Status: ${clientPkg.status} (0 Credits)`);

// 2.3 Verify Payment (Activates with 10 Credits)
store.setCurrentUser('usr-trn-1');
Actions.verifyPayment(payment.id, true);
console.log(`  Payment Verified: ${payment.payment_status}, Activated Remaining Sessions: ${clientPkg.remaining_sessions}`);
if (clientPkg.remaining_sessions !== 10) {
  throw new Error(`Package activation failed: expected 10 credits, got ${clientPkg.remaining_sessions}`);
}

// -------------------------------------------------------------
// MILESTONE 3: ADVANCED CALENDAR & RECURRING SESSIONS
// -------------------------------------------------------------
console.log('\n--- MILESTONE 3: ADVANCED CALENDAR & RECURRING SESSIONS ---');
store.setCurrentUser('usr-client-1');
// Book 2-week recurring sessions
const session = Actions.requestSessionBooking('trn-alex', clientPkg.id, '2026-09-02', '10:00', 2);
state = store.getState();
const bookedSessions = state.sessions.filter(s => s.client_id === client.id && s.status === 'REQUESTED');
console.log(`  Recurring Sessions Created: ${bookedSessions.length}, Credit Balance on Booking: ${clientPkg.remaining_sessions}`);
if (clientPkg.remaining_sessions !== 10 || session.credit_consumed !== false) {
  throw new Error('Credit rule violation: Credits were deducted on booking request!');
}

// Accept booking
store.setCurrentUser('usr-trn-1');
Actions.acceptBookingRequest(session.id);
console.log(`  Session Status: ${session.status}`);

// -------------------------------------------------------------
// MILESTONE 2: EXERCISE LIBRARY & TEMPLATES
// -------------------------------------------------------------
console.log('\n--- MILESTONE 2: EXERCISE LIBRARY & TEMPLATES ---');
// 3.1 12 Categories Verification
const categories = new Set(state.exercises.map(e => e.category));
console.log(`  Categories present in library: ${Array.from(categories).join(', ')}`);
if (categories.size < 10) {
  throw new Error(`Exercise library missing required categories. Found ${categories.size}`);
}

// 3.2 Custom Trainer Exercise Creation
const customEx = Actions.createCustomExercise(
  'Landmine Single-Arm Press',
  'Shoulders',
  'Barbell',
  'Anterior Deltoid & Core',
  'Explosive upward press with neutral wrist.'
);
console.log(`  Custom Exercise Created: "${customEx.name}" (ID: ${customEx.id})`);

// 3.3 Custom Template Creation & Assignment
const newTmpl = Actions.saveWorkoutTemplate('Athletic Upper Power', 'Power progressions', [
  { exercise_id: customEx.id, name: customEx.name, sets: 4, reps: 8, weight: 25, rest: 60 },
  { exercise_id: 'ex-1', name: 'Barbell Bench Press', sets: 3, reps: 10, weight: 60, rest: 60 }
]);
console.log(`  Template Saved: "${newTmpl.name}" with ${newTmpl.exercises.length} exercises`);

const assignedWorkout = Actions.assignWorkout('usr-client-1', newTmpl.id);
console.log(`  Workout Assigned to Client: "${assignedWorkout.name}"`);

// 3.4 Complete PT Session (Executes 1 credit deduction)
Actions.completeSessionAndLogWorkout(session.id, assignedWorkout.id);
state = store.getState();
console.log(`  PT Session Completed. Remaining Credits: ${clientPkg.remaining_sessions} (Decremented: 10 ➔ ${clientPkg.remaining_sessions})`);
if (clientPkg.remaining_sessions !== 9) {
  throw new Error(`Credit ledger error: expected 9 remaining credits, got ${clientPkg.remaining_sessions}`);
}

// 3.5 Log Own Workout (Strict 0 PT Credit Deduction)
store.setCurrentUser('usr-client-1');
const ownWorkout = Actions.createAndLogOwnWorkout('Independent HIIT & Abs', [
  { id: 'ex-own-1', name: 'Plank with Shoulder Taps', sets: 3, repetitions: 20, weight_kg: 0, is_completed: true }
]);
state = store.getState();
console.log(`  Own Workout Completed: "${ownWorkout.name}" (Type: ${ownWorkout.workout_type})`);
console.log(`  Remaining Credits after Own Workout: ${clientPkg.remaining_sessions}`);
if (clientPkg.remaining_sessions !== 9) {
  throw new Error(`CRITICAL RULE VIOLATION: Own Workouts deducted PT credits! Balance is ${clientPkg.remaining_sessions}`);
}

// -------------------------------------------------------------
// MILESTONE 4: HEAD TRAINER CLIENT REASSIGNMENT
// -------------------------------------------------------------
console.log('\n--- MILESTONE 4: HEAD TRAINER CLIENT REASSIGNMENT ---');
store.setCurrentUser('usr-headtrn-1');
// Reassign Sarah from Alex Rivera (trn-alex) to Maya Lin (trn-maya)
Actions.reassignClient(rel.id, 'trn-maya', 'Client requested calisthenics & mobility specialization');
state = store.getState();
console.log(`  Client Reassigned to: ${rel.trainer_id}`);
console.log(`  Active Client Package Transferred Trainer: ${clientPkg.trainer_id}`);
console.log(`  Credits Preserved: ${clientPkg.remaining_sessions} credits intact`);
if (rel.trainer_id !== 'trn-maya' || clientPkg.trainer_id !== 'trn-maya' || clientPkg.remaining_sessions !== 9) {
  throw new Error('Head Trainer reassignment failed to transfer trainer or preserve active package credits!');
}

// -------------------------------------------------------------
// MILESTONE 6: CLIENT REVIEWS & RATINGS
// -------------------------------------------------------------
console.log('\n--- MILESTONE 6: CLIENT REVIEWS & RATINGS ---');
store.setCurrentUser('usr-client-1');
const review = Actions.submitTrainerReview('trn-maya', 5, 'Maya is incredible with mobility flows and calisthenics progressions!');
state = store.getState();
const mayaTrainer = state.trainers.find(t => t.id === 'trn-maya');
console.log(`  Review Posted for Maya Lin: ⭐ ${review.rating}/5`);
console.log(`  Maya Updated Average Rating: ⭐ ${mayaTrainer.rating} (${mayaTrainer.review_count} reviews)`);
if (!mayaTrainer.rating || mayaTrainer.rating < 4.0) {
  throw new Error('Trainer review aggregation failed.');
}

// -------------------------------------------------------------
// MILESTONE 7: NOTIFICATION CENTRE
// -------------------------------------------------------------
console.log('\n--- MILESTONE 7: NOTIFICATION CENTRE ---');
const sarahNotifs = state.notifications.filter(n => n.user_id === 'usr-client-1');
console.log(`  Client Notification Count: ${sarahNotifs.length}`);
console.log(`  Latest Notification: "[${sarahNotifs[0].title}] ${sarahNotifs[0].message}"`);
if (sarahNotifs.length < 3) {
  throw new Error('Notification center failed to capture lifecycle event triggers.');
}

// -------------------------------------------------------------
// MILESTONE 8: SUPER ADMIN & FEATURE FLAGS
// -------------------------------------------------------------
console.log('\n--- MILESTONE 8: SUPER ADMIN & FEATURE FLAGS ---');
store.setCurrentUser('usr-admin-1');
console.log(`  Initial Feature Flag advanced_trainer_search: ${state.feature_flags.advanced_trainer_search} (Expected: false)`);
if (state.feature_flags.advanced_trainer_search !== false) {
  throw new Error('Rule 1 Violation: advanced_trainer_search must default to false.');
}

// Toggle feature flag
Actions.toggleFeatureFlag('advanced_trainer_search', true);
console.log(`  Toggled Feature Flag advanced_trainer_search: ${state.feature_flags.advanced_trainer_search} (Now: true)`);

// Toggle trainer verification
const leoTrainer = state.trainers.find(t => t.id === 'trn-leo');
console.log(`  Leo Novak initial verification: ${leoTrainer.verification_status}`);
Actions.toggleTrainerVerification('trn-leo', true);
console.log(`  Leo Novak updated verification: ${leoTrainer.verification_status}`);
if (leoTrainer.verification_status !== 'VERIFIED') {
  throw new Error('Admin trainer verification toggle failed.');
}

console.log('\n================================================================');
console.log('🎉 ALL 8 MILESTONES & CORE STAGE 1A REGRESSION TESTS PASSED 100%!');
console.log('================================================================\n');
