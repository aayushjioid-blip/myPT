// Automated E2E Flow Validation Test

import { store } from './app/src/state/store.js';
import { Actions } from './app/src/state/actions.js';

console.log('🧪 Starting FitTrainer Prioritized E2E Flow Validation...\n');

// 1. Initial State Check (Client Sarah Jenkins)
store.resetToDefaults();
let state = store.getState();
const client = store.getCurrentUser();
console.log(`[STEP 1] Current User: ${client.name} (${client.role})`);
console.log(`  Initial Active Packages: ${state.client_packages.filter(cp => cp.client_id === client.id && cp.status === 'ACTIVE').length}`);

// 2. Discover Verified Trainer
const verifiedTrainers = state.trainers.filter(t => t.verification_status === 'VERIFIED');
const unverifiedTrainers = state.trainers.filter(t => t.verification_status === 'UNVERIFIED');
console.log(`[STEP 2] Discovery Check:`);
console.log(`  Verified trainers visible: ${verifiedTrainers.map(t => t.name).join(', ')}`);
console.log(`  Unverified trainers hidden: ${unverifiedTrainers.map(t => t.name).join(', ')}`);
if (verifiedTrainers.length !== 1 || verifiedTrainers[0].name !== 'Alex Rivera') {
  throw new Error('Verification rule failed: Alex Rivera should be the only verified trainer in public discovery.');
}

// 3. Client Sends Consultation Request to Alex Rivera
console.log('\n[STEP 3] Client sends consultation request to Alex Rivera...');
Actions.sendConsultationRequest('trn-alex', 'Fat Loss & Hypertrophy', 'Available weekday mornings');
state = store.getState();
const rel = state.relationships.find(r => r.client_id === client.id && r.trainer_id === 'trn-alex');
console.log(`  Relationship Status: ${rel.status}`);

// 4. Switch to Trainer Role & Approve Client
console.log('\n[STEP 4] Trainer (Alex) accepts client request...');
store.setCurrentUser('usr-trn-1');
Actions.acceptClientRequest(rel.id);
state = store.getState();
console.log(`  Relationship Status: ${rel.status}, Approved for packages: ${rel.approved_for_packages}`);

// 5. Switch to Client Role, Select Package, and Submit Mock Offline Payment
console.log('\n[STEP 5] Client selects "10 PT Sessions Starter Pack" and submits offline payment...');
store.setCurrentUser('usr-client-1');
const pkg10 = state.packages.find(p => p.id === 'pkg-10pt');
Actions.selectPackageAndSubmitPayment(pkg10.id, 'UPI-9847291823');
state = store.getState();
const payment = state.payments.find(p => p.client_id === client.id);
const clientPkg = state.client_packages.find(cp => cp.client_id === client.id);
console.log(`  Payment Status: ${payment.payment_status} (Ref: ${payment.transaction_reference})`);
console.log(`  Client Package Status: ${clientPkg.status}, Remaining Sessions: ${clientPkg.remaining_sessions}`);
if (clientPkg.status !== 'PENDING_PAYMENT' || clientPkg.remaining_sessions !== 0) {
  throw new Error('Rule 4 Failure: Package must not be activated before trainer verification!');
}

// 6. Switch to Trainer Role & Verify Offline Payment
console.log('\n[STEP 6] Trainer verifies payment...');
store.setCurrentUser('usr-trn-1');
Actions.verifyPayment(payment.id, true);
state = store.getState();
console.log(`  Payment Status: ${payment.payment_status}`);
console.log(`  Client Package Status: ${clientPkg.status}, Activated Remaining Sessions: ${clientPkg.remaining_sessions}`);
if (clientPkg.status !== 'ACTIVE' || clientPkg.remaining_sessions !== 10) {
  throw new Error('Activation Failure: Package should activate with 10 sessions upon verification.');
}

// 7. Switch to Client Role & Request Session Booking
console.log('\n[STEP 7] Client requests session booking...');
store.setCurrentUser('usr-client-1');
const session = Actions.requestSessionBooking('trn-alex', clientPkg.id, '2026-09-01', '10:00');
state = store.getState();
console.log(`  Session ID: ${session.id}, Status: ${session.status}, Credit Consumed on Booking: ${session.credit_consumed}`);
console.log(`  Remaining Credits after booking: ${clientPkg.remaining_sessions}`);
if (clientPkg.remaining_sessions !== 10 || session.credit_consumed !== false) {
  throw new Error('Rule 5 Failure: Credits must NOT be deducted upon booking!');
}

// 8. Switch to Trainer Role & Accept Booking
console.log('\n[STEP 8] Trainer accepts booking...');
store.setCurrentUser('usr-trn-1');
Actions.acceptBookingRequest(session.id);
console.log(`  Session Status: ${session.status}`);

// 9. Assign Workout, Start Session, Log Sets, and Complete Session
console.log('\n[STEP 9] Trainer assigns workout and marks session completed...');
const workout = Actions.assignWorkout('usr-client-1', 'tmpl-upper-hypertrophy');
Actions.completeSessionAndLogWorkout(session.id, workout.id, [
  { id: 'ex-log-1', name: 'Barbell Bench Press', sets: 3, repetitions: 10, weight_kg: 60, is_completed: true },
  { id: 'ex-log-2', name: 'Lat Pulldown', sets: 3, repetitions: 12, weight_kg: 50, is_completed: true }
]);
state = store.getState();
console.log(`  Session Status: ${session.status}, Credit Consumed: ${session.credit_consumed}`);
console.log(`  Remaining Sessions in Package: ${clientPkg.remaining_sessions} (decremented from 10 to ${clientPkg.remaining_sessions})`);
if (clientPkg.remaining_sessions !== 9) {
  throw new Error(`Rule 5 Failure: Remaining sessions should be 9 after completion, got ${clientPkg.remaining_sessions}`);
}

// 10. Switch to Client Role & Log an Own Workout
console.log('\n[STEP 10] Client logs an "Own Workout" (Independent)...');
store.setCurrentUser('usr-client-1');
const ownWorkout = Actions.logOwnWorkout('Independent Core & Cardio');
state = store.getState();
console.log(`  Own Workout Created: "${ownWorkout.name}", Type: ${ownWorkout.workout_type}`);
console.log(`  Remaining Sessions after Own Workout: ${clientPkg.remaining_sessions}`);
if (clientPkg.remaining_sessions !== 9) {
  throw new Error('Rule 5 Failure: Own workouts must NEVER deduct PT credits!');
}

console.log('\n🎉 ALL 10 E2E PRODUCT FLOW AND RULE VERIFICATIONS PASSED SUCCESSFULLY!\n');
