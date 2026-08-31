// FitTrainer Business Logic Actions & State Transitions

import { store } from './store.js';

export const Actions = {
  // 1. CLIENT: Send Consultation / Interest Request
  sendConsultationRequest(trainerId, goals = '', notes = '') {
    const state = store.getState();
    const client = store.getCurrentUser();
    
    // Check if relationship already exists
    let rel = state.relationships.find(r => r.client_id === client.id && r.trainer_id === trainerId);
    if (!rel) {
      rel = {
        id: `rel-${Date.now()}`,
        client_id: client.id,
        trainer_id: trainerId,
        status: 'REQUESTED',
        goals,
        notes,
        created_at: new Date().toISOString()
      };
      state.relationships.push(rel);
    } else {
      rel.status = 'REQUESTED';
      rel.goals = goals;
      rel.notes = notes;
    }

    // Add notification to Trainer
    const trainerObj = state.trainers.find(t => t.id === trainerId);
    if (trainerObj) {
      state.notifications.unshift({
        id: `notif-${Date.now()}`,
        user_id: trainerObj.user_id,
        title: 'New Client Request',
        message: `${client.name} has requested a consultation with you.`,
        read: false,
        timestamp: new Date().toISOString()
      });
    }

    store.notify();
    return rel;
  },

  // 2. TRAINER: Accept & Approve Client for Package Purchase
  acceptClientRequest(relationshipId) {
    const state = store.getState();
    const rel = state.relationships.find(r => r.id === relationshipId);
    if (rel) {
      rel.status = 'ACCEPTED';
      rel.approved_for_packages = true;
      rel.accepted_at = new Date().toISOString();

      // Notify Client
      state.notifications.unshift({
        id: `notif-${Date.now()}`,
        user_id: rel.client_id,
        title: 'Trainer Approved!',
        message: `Your trainer accepted your request. You can now select and purchase a training package!`,
        read: false,
        timestamp: new Date().toISOString()
      });

      store.notify();
    }
  },

  // 3. CLIENT: Select Package & Submit Mock Offline Payment ("I Have Paid")
  selectPackageAndSubmitPayment(packageId, transactionRef) {
    const state = store.getState();
    const client = store.getCurrentUser();
    const pkg = state.packages.find(p => p.id === packageId);
    if (!pkg) return false;

    // Create Payment Record (Status: PENDING_VERIFICATION)
    const payment = {
      id: `pay-${Date.now()}`,
      client_id: client.id,
      trainer_id: pkg.trainer_id,
      package_id: pkg.id,
      amount: pkg.price,
      payment_method: 'UPI',
      transaction_reference: transactionRef,
      payment_status: 'PENDING_VERIFICATION', // Correct mock flow: Not active immediately
      created_at: new Date().toISOString()
    };
    state.payments.push(payment);

    // Create Client Package in PENDING_PAYMENT status
    const clientPkg = {
      id: `cpkg-${Date.now()}`,
      client_id: client.id,
      trainer_id: pkg.trainer_id,
      package_id: pkg.id,
      total_sessions: pkg.sessions,
      completed_sessions: 0,
      remaining_sessions: 0, // Unlocked only upon verification
      validity_days: pkg.validity_days,
      purchase_date: new Date().toISOString(),
      status: 'PENDING_PAYMENT',
      payment_id: payment.id
    };
    state.client_packages.push(clientPkg);

    // Notify Trainer
    const trainerObj = state.trainers.find(t => t.id === pkg.trainer_id);
    if (trainerObj) {
      state.notifications.unshift({
        id: `notif-${Date.now()}`,
        user_id: trainerObj.user_id,
        title: 'Payment Verification Required',
        message: `${client.name} submitted offline payment (${transactionRef}) for "${pkg.name}".`,
        read: false,
        timestamp: new Date().toISOString()
      });
    }

    store.notify();
    return true;
  },

  // 4. TRAINER: Verify Offline Payment Received
  verifyPayment(paymentId, approve = true, rejectionReason = '') {
    const state = store.getState();
    const payment = state.payments.find(p => p.id === paymentId);
    if (!payment) return;

    const clientPkg = state.client_packages.find(cp => cp.payment_id === paymentId);
    const trainer = store.getCurrentUser();

    if (approve) {
      payment.payment_status = 'PAID';
      payment.verified_at = new Date().toISOString();
      payment.verified_by = trainer.id;

      if (clientPkg) {
        clientPkg.status = 'ACTIVE';
        clientPkg.remaining_sessions = clientPkg.total_sessions; // Sets to 10
        clientPkg.activation_date = new Date().toISOString();
        
        // Expiration date
        const exp = new Date();
        exp.setDate(exp.getDate() + clientPkg.validity_days);
        clientPkg.expiry_date = exp.toISOString();
      }

      // Notify Client
      state.notifications.unshift({
        id: `notif-${Date.now()}`,
        user_id: payment.client_id,
        title: 'Package Activated! 🎉',
        message: `Your payment was verified. ${clientPkg ? clientPkg.total_sessions : 10} session credits are now available for booking!`,
        read: false,
        timestamp: new Date().toISOString()
      });
    } else {
      payment.payment_status = 'REJECTED';
      payment.rejection_reason = rejectionReason;
      if (clientPkg) {
        clientPkg.status = 'CANCELLED';
      }

      // Notify Client
      state.notifications.unshift({
        id: `notif-${Date.now()}`,
        user_id: payment.client_id,
        title: 'Payment Verification Issue',
        message: `Your trainer could not verify your payment (${rejectionReason || 'Reference not found'}). Please resubmit.`,
        read: false,
        timestamp: new Date().toISOString()
      });
    }

    store.notify();
  },

  // 5. CLIENT: Request Session Booking
  requestSessionBooking(trainerId, clientPackageId, scheduledDate, scheduledTime) {
    const state = store.getState();
    const client = store.getCurrentUser();
    const clientPkg = state.client_packages.find(cp => cp.id === clientPackageId && cp.status === 'ACTIVE');

    if (!clientPkg || clientPkg.remaining_sessions <= 0) {
      alert('Cannot book session: Zero session credits remaining or package inactive.');
      return null;
    }

    // Create session in REQUESTED state (0 credits deducted!)
    const session = {
      id: `sess-${Date.now()}`,
      client_id: client.id,
      trainer_id: trainerId,
      client_package_id: clientPackageId,
      session_type: 'PERSONAL_TRAINING',
      scheduled_start: `${scheduledDate}T${scheduledTime}:00`,
      status: 'REQUESTED',
      credit_consumed: false, // Strict Rule: Not deducted on booking
      created_at: new Date().toISOString()
    };
    state.sessions.push(session);

    // Notify Trainer
    const trainerObj = state.trainers.find(t => t.id === trainerId);
    if (trainerObj) {
      state.notifications.unshift({
        id: `notif-${Date.now()}`,
        user_id: trainerObj.user_id,
        title: 'New Session Booking Request',
        message: `${client.name} requested a PT session on ${scheduledDate} at ${scheduledTime}.`,
        read: false,
        timestamp: new Date().toISOString()
      });
    }

    store.notify();
    return session;
  },

  // 6. TRAINER: Accept Session Booking
  acceptBookingRequest(sessionId) {
    const state = store.getState();
    const session = state.sessions.find(s => s.id === sessionId);
    if (session) {
      session.status = 'CONFIRMED';
      session.confirmed_at = new Date().toISOString();

      // Notify Client
      state.notifications.unshift({
        id: `notif-${Date.now()}`,
        user_id: session.client_id,
        title: 'Session Confirmed!',
        message: `Your training session on ${session.scheduled_start.split('T')[0]} is confirmed.`,
        read: false,
        timestamp: new Date().toISOString()
      });

      store.notify();
    }
  },

  // 7. TRAINER: Assign Workout Routine
  assignWorkout(clientId, templateId, assignedDate = new Date().toISOString().split('T')[0]) {
    const state = store.getState();
    const trainer = store.getCurrentTrainerProfile();
    const tmpl = state.workout_templates.find(t => t.id === templateId) || state.workout_templates[0];

    const workout = {
      id: `wo-${Date.now()}`,
      trainer_id: trainer ? trainer.id : 'trn-alex',
      client_id: clientId,
      name: tmpl.name,
      description: tmpl.description,
      workout_type: 'ASSIGNED',
      assigned_date: assignedDate,
      status: 'PENDING',
      exercises: tmpl.exercises.map((ex, idx) => ({
        id: `wo-ex-${idx}`,
        exercise_id: ex.exercise_id,
        name: ex.name,
        sets: ex.sets || 3,
        repetitions: ex.reps || 10,
        weight_kg: ex.weight || 50,
        completed_sets: 0,
        is_completed: false
      }))
    };

    state.workouts.unshift(workout);

    // Notify Client
    state.notifications.unshift({
      id: `notif-${Date.now()}`,
      user_id: clientId,
      title: 'New Workout Assigned',
      message: `Your trainer assigned "${workout.name}" for ${assignedDate}.`,
      read: false,
      timestamp: new Date().toISOString()
    });

    store.notify();
    return workout;
  },

  // 8. TRAINER: Start Session, Log Sets, Reps & Weight, and Complete Session (CREDIT DEDUCTION EXECUTION)
  completeSessionAndLogWorkout(sessionId, workoutId, loggedExercises = []) {
    const state = store.getState();
    const session = state.sessions.find(s => s.id === sessionId);
    const workout = state.workouts.find(w => w.id === workoutId);

    if (workout) {
      workout.status = 'COMPLETED';
      workout.completed_at = new Date().toISOString();
      if (loggedExercises.length > 0) {
        workout.exercises = loggedExercises;
      }
    }

    if (session) {
      session.status = 'COMPLETED';
      session.completed_at = new Date().toISOString();
      
      // CRITICAL BUSINESS RULE: PT session completed consumes exactly ONE credit
      if (session.session_type === 'PERSONAL_TRAINING' && !session.credit_consumed) {
        session.credit_consumed = true;

        // Decrement Client Package Balance (e.g. 10 -> 9)
        const clientPkg = state.client_packages.find(cp => cp.id === session.client_package_id);
        if (clientPkg && clientPkg.remaining_sessions > 0) {
          clientPkg.remaining_sessions -= 1;
          clientPkg.completed_sessions += 1;
          console.log(`[LEDGER] Client Package ${clientPkg.id} updated: Remaining sessions = ${clientPkg.remaining_sessions}`);
        }
      }

      // Notify Client
      state.notifications.unshift({
        id: `notif-${Date.now()}`,
        user_id: session.client_id,
        title: 'Workout Completed! 💪',
        message: `Your session was marked completed. Remaining credits: ${
          session.client_package_id ? (state.client_packages.find(cp => cp.id === session.client_package_id)?.remaining_sessions ?? 0) : 'N/A'
        }. Great work!`,
        read: false,
        timestamp: new Date().toISOString()
      });
    }

    store.notify();
  },

  // 9. CLIENT: Create & Log "Own Workout" (Strict Rule: NEVER deducts credits)
  logOwnWorkout(name, exercises = []) {
    const state = store.getState();
    const client = store.getCurrentUser();

    const ownWorkout = {
      id: `wo-own-${Date.now()}`,
      trainer_id: null,
      client_id: client.id,
      name: name || 'Own Workout (Self-Trained)',
      description: 'Independent client workout session',
      workout_type: 'OWN_WORKOUT',
      assigned_date: new Date().toISOString().split('T')[0],
      status: 'COMPLETED',
      completed_at: new Date().toISOString(),
      exercises: exercises
    };

    state.workouts.unshift(ownWorkout);

    // Record session for calendar history with zero credit consumed
    state.sessions.push({
      id: `sess-own-${Date.now()}`,
      client_id: client.id,
      trainer_id: null,
      session_type: 'OWN_WORKOUT',
      scheduled_start: new Date().toISOString(),
      status: 'COMPLETED',
      credit_consumed: false, // Strictly false
      notes: 'Own independent workout'
    });

    store.notify();
    return ownWorkout;
  },

  // 10. Privacy & Feature Flag Toggles
  toggleClientPersonalInfoSharing(isShared) {
    const state = store.getState();
    const user = store.getCurrentUser();
    user.share_personal_info_with_trainer = isShared;
    store.notify();
  },

  toggleFeatureFlag(flagKey, value) {
    const state = store.getState();
    state.feature_flags[flagKey] = value;
    store.notify();
  },

  // 11. Package Creation (with suggested 4x formula and manual customization)
  createTrainerPackage(name, description, sessions, price, validityDays) {
    const state = store.getState();
    const trainer = store.getCurrentTrainerProfile();
    if (!trainer) return;

    const newPkg = {
      id: `pkg-${Date.now()}`,
      trainer_id: trainer.id,
      name: name,
      description: description,
      sessions: parseInt(sessions, 10),
      price: parseFloat(price),
      validity_days: parseInt(validityDays, 10),
      validity_mode: 'CUSTOM',
      session_duration: 60,
      status: 'ACTIVE'
    };

    state.packages.push(newPkg);
    store.notify();
    return newPkg;
  }
};
