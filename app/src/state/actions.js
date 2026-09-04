// FitTrainer Business Logic Actions & State Transitions (Stage 1B Master)

import { store } from './store.js';

export const Actions = {
  // ==========================================
  // 1. CLIENT & TRAINER: PROGRESS TRACKING
  // ==========================================
  logProgressMeasurement(data = {}) {
    const state = store.getState();
    const currentUser = store.getCurrentUser();
    const clientId = data.clientId || (currentUser.role === 'CLIENT' ? currentUser.id : 'usr-client-1');

    const weight = parseFloat(data.weight) || 65.0;
    const height = parseFloat(data.height_cm) || 168.0;
    const heightInMeters = height / 100;
    const calculatedBmi = parseFloat((weight / (heightInMeters * heightInMeters)).toFixed(1));

    const newMeasurement = {
      id: `m-${Date.now()}`,
      client_id: clientId,
      date: data.date || new Date().toISOString().split('T')[0],
      weight: weight,
      height_cm: height,
      bmi: calculatedBmi,
      body_fat: parseFloat(data.body_fat) || 22.0,
      chest: parseFloat(data.chest) || 90.0,
      waist: parseFloat(data.waist) || 72.0,
      hips: parseFloat(data.hips) || 95.0,
      biceps: parseFloat(data.biceps) || 29.0,
      thighs: parseFloat(data.thighs) || 55.0,
      calves: parseFloat(data.calves) || 36.5,
      photos: data.photos || {
        front: '📸 Front View Uploaded',
        side: '📸 Side View Uploaded',
        back: '📸 Back View Uploaded'
      },
      notes: data.notes || 'Routine check-in body measurement.'
    };

    state.progress_measurements.unshift(newMeasurement);

    // If logged by trainer or client, send appropriate notification
    if (currentUser.role === 'TRAINER') {
      this.triggerNotification(
        clientId,
        'New Progress Logged 📊',
        `Your trainer logged a new body measurement assessment for you.`,
        'PROGRESS'
      );
    }

    store.notify();
    return newMeasurement;
  },

  // ==========================================
  // 2. CLIENT: OWN WORKOUTS (0 PT CREDITS)
  // ==========================================
  createAndLogOwnWorkout(name, exercises = [], notes = '') {
    const state = store.getState();
    const client = store.getCurrentUser();

    const formattedExercises = exercises.length > 0 ? exercises : [
      { id: 'ex-log-1', name: 'Barbell Bench Press', sets: 3, repetitions: 10, weight_kg: 50, is_completed: true },
      { id: 'ex-log-2', name: 'Plank with Shoulder Taps', sets: 3, repetitions: 15, weight_kg: 0, is_completed: true }
    ];

    const ownWorkout = {
      id: `wo-own-${Date.now()}`,
      trainer_id: null,
      client_id: client.id,
      name: name || 'Independent Strength & Cardio',
      description: notes || 'Client self-programmed independent training session.',
      workout_type: 'OWN_WORKOUT',
      assigned_date: new Date().toISOString().split('T')[0],
      status: 'COMPLETED',
      completed_at: new Date().toISOString(),
      exercises: formattedExercises
    };

    state.workouts.unshift(ownWorkout);

    // Record session for calendar history with STRICT ZERO CREDIT DEDUCTION
    state.sessions.push({
      id: `sess-own-${Date.now()}`,
      client_id: client.id,
      trainer_id: null,
      session_type: 'OWN_WORKOUT',
      scheduled_start: new Date().toISOString(),
      status: 'COMPLETED',
      credit_consumed: false, // CRITICAL RULE: Strictly false
      notes: 'Own independent workout'
    });

    store.notify();
    return ownWorkout;
  },

  // ==========================================
  // 3. EXERCISE LIBRARY & WORKOUT TEMPLATES
  // ==========================================
  createCustomExercise(name, category, equipment, target, description) {
    const state = store.getState();
    const trainer = store.getCurrentTrainerProfile();

    const customEx = {
      id: `ex-custom-${Date.now()}`,
      name: name.trim(),
      category: category || 'Full Body',
      equipment: equipment || 'Bodyweight',
      target: target || 'General',
      description: description || 'Custom trainer exercise.',
      trainer_id: trainer ? trainer.id : null,
      is_custom: true
    };

    state.exercises.push(customEx);
    store.notify();
    return customEx;
  },

  saveWorkoutTemplate(name, description, exercises = []) {
    const state = store.getState();
    const trainer = store.getCurrentTrainerProfile();

    const template = {
      id: `tmpl-${Date.now()}`,
      trainer_id: trainer ? trainer.id : 'trn-alex',
      name: name.trim(),
      description: description.trim(),
      exercises: exercises.length > 0 ? exercises : [
        { exercise_id: 'ex-1', name: 'Barbell Bench Press', sets: 3, reps: 10, weight: 60, rest: 60 },
        { exercise_id: 'ex-5', name: 'Lat Pulldown', sets: 3, reps: 12, weight: 50, rest: 60 }
      ]
    };

    state.workout_templates.unshift(template);
    store.notify();
    return template;
  },

  updateWorkoutTemplate(templateId, updatedData = {}) {
    const state = store.getState();
    const tmpl = state.workout_templates.find(t => t.id === templateId);
    if (tmpl) {
      Object.assign(tmpl, updatedData);
      store.notify();
    }
  },

  deleteWorkoutTemplate(templateId) {
    const state = store.getState();
    state.workout_templates = state.workout_templates.filter(t => t.id !== templateId);
    store.notify();
  },

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
        exercise_id: ex.exercise_id || ex.id,
        name: ex.name,
        sets: ex.sets || 3,
        repetitions: ex.reps || ex.repetitions || 10,
        weight_kg: ex.weight || ex.weight_kg || 40,
        completed_sets: 0,
        is_completed: false
      }))
    };

    state.workouts.unshift(workout);

    this.triggerNotification(
      clientId,
      'New Workout Assigned 📋',
      `Your trainer assigned "${workout.name}" for ${assignedDate}.`,
      'WORKOUT'
    );

    store.notify();
    return workout;
  },

  // ==========================================
  // 4. ADVANCED CALENDAR, AVAILABILITY & RECURRING
  // ==========================================
  updateTrainerWorkingHours(trainerId, workingHours) {
    const state = store.getState();
    const trainer = state.trainers.find(t => t.id === trainerId);
    if (trainer) {
      trainer.working_hours = workingHours;
      store.notify();
    }
  },

  requestSessionBooking(trainerId, clientPackageId, scheduledDate, scheduledTime, recurringWeeks = 1) {
    const state = store.getState();
    const client = store.getCurrentUser();
    const clientPkg = state.client_packages.find(cp => cp.id === clientPackageId && cp.status === 'ACTIVE');

    if (!clientPkg || clientPkg.remaining_sessions < recurringWeeks) {
      alert(`Cannot book session: Insufficient credits. Requested ${recurringWeeks} sessions, but only ${clientPkg ? clientPkg.remaining_sessions : 0} credits remaining.`);
      return null;
    }

    const createdSessions = [];

    for (let i = 0; i < recurringWeeks; i++) {
      const targetDate = new Date(`${scheduledDate}T${scheduledTime}:00`);
      targetDate.setDate(targetDate.getDate() + (i * 7));
      const dateString = targetDate.toISOString().split('T')[0];

      // Check slot capacity
      const existingInSlot = state.sessions.filter(s => 
        s.trainer_id === trainerId && 
        s.scheduled_start === `${dateString}T${scheduledTime}:00` && 
        s.status !== 'CANCELLED'
      );

      const trainerObj = state.trainers.find(t => t.id === trainerId);
      const dayName = targetDate.toLocaleDateString('en-US', { weekday: 'lowercase' });
      const maxCapacity = trainerObj?.working_hours?.[dayName]?.slot_capacity || 2;

      if (existingInSlot.length >= maxCapacity) {
        alert(`Slot on ${dateString} at ${scheduledTime} is at maximum capacity (${maxCapacity} clients). Please select another time.`);
        break;
      }

      const session = {
        id: `sess-${Date.now()}-${i}`,
        client_id: client.id,
        trainer_id: trainerId,
        client_package_id: clientPackageId,
        session_type: 'PERSONAL_TRAINING',
        scheduled_start: `${dateString}T${scheduledTime}:00`,
        status: 'REQUESTED',
        is_recurring: recurringWeeks > 1,
        credit_consumed: false, // Strict Rule: 0 credits deducted upon booking
        created_at: new Date().toISOString()
      };

      state.sessions.push(session);
      createdSessions.push(session);
    }

    if (createdSessions.length > 0) {
      const trainerObj = state.trainers.find(t => t.id === trainerId);
      if (trainerObj) {
        this.triggerNotification(
          trainerObj.user_id,
          'New Booking Request 📅',
          `${client.name} requested ${createdSessions.length} session(s) starting ${scheduledDate} at ${scheduledTime}.`,
          'BOOKING'
        );
      }
    }

    store.notify();
    return createdSessions[0];
  },

  acceptBookingRequest(sessionId) {
    const state = store.getState();
    const session = state.sessions.find(s => s.id === sessionId);
    if (session) {
      session.status = 'CONFIRMED';
      session.confirmed_at = new Date().toISOString();

      this.triggerNotification(
        session.client_id,
        'Session Confirmed! 🎉',
        `Your training session on ${session.scheduled_start.replace('T', ' at ')} has been confirmed.`,
        'BOOKING'
      );

      store.notify();
    }
  },

  rejectBookingRequest(sessionId, reason = 'Trainer unavailable for this slot.') {
    const state = store.getState();
    const session = state.sessions.find(s => s.id === sessionId);
    if (session) {
      session.status = 'REJECTED';
      session.rejection_reason = reason;

      this.triggerNotification(
        session.client_id,
        'Booking Request Declined',
        `Your session on ${session.scheduled_start.replace('T', ' at ')} was declined: ${reason}`,
        'BOOKING'
      );

      store.notify();
    }
  },

  rescheduleSession(sessionId, newDate, newTime) {
    const state = store.getState();
    const session = state.sessions.find(s => s.id === sessionId);
    if (session) {
      session.scheduled_start = `${newDate}T${newTime}:00`;
      session.status = 'CONFIRMED';

      this.triggerNotification(
        session.client_id,
        'Session Rescheduled 🔄',
        `Your session was moved to ${newDate} at ${newTime}.`,
        'BOOKING'
      );

      store.notify();
    }
  },

  cancelSession(sessionId, cancelledBy = 'CLIENT', reason = '') {
    const state = store.getState();
    const session = state.sessions.find(s => s.id === sessionId);
    if (!session) return;

    const trainer = state.trainers.find(t => t.id === session.trainer_id);
    const sessionTime = new Date(session.scheduled_start).getTime();
    const now = new Date().getTime();
    const hoursUntilSession = (sessionTime - now) / (1000 * 60 * 60);

    session.status = 'CANCELLED';
    session.cancelled_at = new Date().toISOString();
    session.cancel_reason = reason;

    // 4-Hour Cancellation Policy Evaluation
    const isPenalty = trainer && trainer.cancellation_policy === 'FOUR_HOUR_POLICY' && hoursUntilSession < 4;

    if (isPenalty && session.session_type === 'PERSONAL_TRAINING' && !session.credit_consumed) {
      session.credit_consumed = true;
      const clientPkg = state.client_packages.find(cp => cp.id === session.client_package_id);
      if (clientPkg && clientPkg.remaining_sessions > 0) {
        clientPkg.remaining_sessions -= 1;
      }
      this.triggerNotification(
        session.client_id,
        'Session Cancelled (1 Credit Penalty Applied)',
        `Session cancelled under 4 hours before start. 1 credit was consumed under trainer policy.`,
        'BOOKING'
      );
    } else {
      this.triggerNotification(
        session.client_id,
        'Session Cancelled',
        `Your session on ${session.scheduled_start.replace('T', ' at ')} was cancelled without penalty (0 credits consumed).`,
        'BOOKING'
      );
    }

    store.notify();
  },

  // ==========================================
  // 5. HEAD TRAINER & GYM MANAGEMENT
  // ==========================================
  reassignClient(relationshipId, newTrainerId, reason = 'Staff schedule optimization') {
    const state = store.getState();
    const rel = state.relationships.find(r => r.id === relationshipId);
    if (!rel) return false;

    const oldTrainer = state.trainers.find(t => t.id === rel.trainer_id);
    const newTrainer = state.trainers.find(t => t.id === newTrainerId);
    const client = state.users.find(u => u.id === rel.client_id);

    // Update relationship
    rel.trainer_id = newTrainerId;
    rel.reassigned_at = new Date().toISOString();
    rel.reassignment_reason = reason;

    // Update associated active client packages
    state.client_packages.forEach(cp => {
      if (cp.client_id === rel.client_id && cp.trainer_id === oldTrainer?.id) {
        cp.trainer_id = newTrainerId;
      }
    });

    // Notify all parties
    if (client) {
      this.triggerNotification(
        client.id,
        'Trainer Reassignment Notice 🔄',
        `Your personal trainer has been updated to ${newTrainer?.name || 'new trainer'} (${reason}). All active credits & logs are preserved!`,
        'MANAGEMENT'
      );
    }
    if (newTrainer) {
      this.triggerNotification(
        newTrainer.user_id,
        'New Client Assigned',
        `${client?.name || 'A client'} has been reassigned to your roster by Gym Management.`,
        'MANAGEMENT'
      );
    }

    store.notify();
    return true;
  },

  updateGymProfile(gymId, gymData = {}) {
    const state = store.getState();
    const gym = state.gyms.find(g => g.id === gymId);
    if (gym) {
      Object.assign(gym, gymData);
      store.notify();
    }
  },

  // ==========================================
  // 6. CLIENT REVIEWS & RATINGS
  // ==========================================
  submitTrainerReview(trainerId, rating, comment = '') {
    const state = store.getState();
    const client = store.getCurrentUser();
    const trainer = state.trainers.find(t => t.id === trainerId);
    if (!trainer) return;

    const newReview = {
      id: `rev-${Date.now()}`,
      trainer_id: trainerId,
      client_id: client.id,
      client_name: client.name,
      rating: parseInt(rating, 10),
      comment: comment.trim(),
      created_at: new Date().toISOString()
    };

    state.reviews.unshift(newReview);

    // Recalculate Trainer Average Rating
    const trainerReviews = state.reviews.filter(r => r.trainer_id === trainerId);
    const avgRating = (trainerReviews.reduce((sum, r) => sum + r.rating, 0) / trainerReviews.length).toFixed(1);
    trainer.rating = parseFloat(avgRating);
    trainer.review_count = trainerReviews.length;

    this.triggerNotification(
      trainer.user_id,
      'New 5-Star Review Received ⭐',
      `${client.name} left a ${rating}-star review: "${comment.slice(0, 40)}..."`,
      'REVIEW'
    );

    store.notify();
    return newReview;
  },

  // ==========================================
  // 7. NOTIFICATION CENTRE
  // ==========================================
  triggerNotification(userId, title, message, type = 'INFO') {
    const state = store.getState();
    state.notifications.unshift({
      id: `notif-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`,
      user_id: userId,
      title,
      message,
      type,
      read: false,
      timestamp: new Date().toISOString()
    });
  },

  markNotificationRead(notifId) {
    const state = store.getState();
    const notif = state.notifications.find(n => n.id === notifId);
    if (notif) {
      notif.read = true;
      store.notify();
    }
  },

  markAllNotificationsRead() {
    const state = store.getState();
    const user = store.getCurrentUser();
    state.notifications.forEach(n => {
      if (n.user_id === user.id) n.read = true;
    });
    store.notify();
  },

  // ==========================================
  // 8. SUPER ADMIN CONTROLS & VERIFICATION
  // ==========================================
  toggleTrainerVerification(trainerId, isVerified) {
    const state = store.getState();
    const trainer = state.trainers.find(t => t.id === trainerId);
    if (trainer) {
      trainer.verification_status = isVerified ? 'VERIFIED' : 'UNVERIFIED';
      this.triggerNotification(
        trainer.user_id,
        isVerified ? 'Verification Approved! 🎉' : 'Verification Revoked',
        isVerified ? 'You are now visible in public discovery.' : 'Your profile has been unverified from public search.',
        'ADMIN'
      );
      store.notify();
    }
  },

  updateUserStatus(userId, newStatus) {
    const state = store.getState();
    const user = state.users.find(u => u.id === userId);
    if (user) {
      user.status = newStatus;
      store.notify();
    }
  },

  // Core Stage 1A Handlers
  sendConsultationRequest(trainerId, goals = '', notes = '') {
    const state = store.getState();
    const client = store.getCurrentUser();
    
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

    const trainerObj = state.trainers.find(t => t.id === trainerId);
    if (trainerObj) {
      this.triggerNotification(
        trainerObj.user_id,
        'New Client Consultation Request',
        `${client.name} requested a consultation with you.`,
        'CONSULTATION'
      );
    }

    store.notify();
    return rel;
  },

  acceptClientRequest(relationshipId) {
    const state = store.getState();
    const rel = state.relationships.find(r => r.id === relationshipId);
    if (rel) {
      rel.status = 'ACCEPTED';
      rel.approved_for_packages = true;
      rel.accepted_at = new Date().toISOString();

      this.triggerNotification(
        rel.client_id,
        'Trainer Approved! 🎉',
        `Your trainer accepted your request. You can now select and purchase a training package!`,
        'CONSULTATION'
      );

      store.notify();
    }
  },

  selectPackageAndSubmitPayment(packageId, transactionRef) {
    const state = store.getState();
    const client = store.getCurrentUser();
    const pkg = state.packages.find(p => p.id === packageId);
    if (!pkg) return false;

    const payment = {
      id: `pay-${Date.now()}`,
      client_id: client.id,
      trainer_id: pkg.trainer_id,
      package_id: pkg.id,
      amount: pkg.price,
      payment_method: 'UPI',
      transaction_reference: transactionRef,
      payment_status: 'PENDING_VERIFICATION',
      created_at: new Date().toISOString()
    };
    state.payments.push(payment);

    const clientPkg = {
      id: `cpkg-${Date.now()}`,
      client_id: client.id,
      trainer_id: pkg.trainer_id,
      package_id: pkg.id,
      total_sessions: pkg.sessions,
      completed_sessions: 0,
      remaining_sessions: 0,
      validity_days: pkg.validity_days,
      purchase_date: new Date().toISOString(),
      status: 'PENDING_PAYMENT',
      payment_id: payment.id
    };
    state.client_packages.push(clientPkg);

    const trainerObj = state.trainers.find(t => t.id === pkg.trainer_id);
    if (trainerObj) {
      this.triggerNotification(
        trainerObj.user_id,
        'Payment Verification Required 💳',
        `${client.name} submitted offline payment (${transactionRef}) for "${pkg.name}".`,
        'PAYMENT'
      );
    }

    store.notify();
    return true;
  },

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
        clientPkg.remaining_sessions = clientPkg.total_sessions;
        clientPkg.activation_date = new Date().toISOString();
        
        const exp = new Date();
        exp.setDate(exp.getDate() + clientPkg.validity_days);
        clientPkg.expiry_date = exp.toISOString();
      }

      this.triggerNotification(
        payment.client_id,
        'Package Activated! 🎉',
        `Your payment was verified. ${clientPkg ? clientPkg.total_sessions : 10} session credits are now available for booking!`,
        'PAYMENT'
      );
    } else {
      payment.payment_status = 'REJECTED';
      payment.rejection_reason = rejectionReason;
      if (clientPkg) {
        clientPkg.status = 'CANCELLED';
      }

      this.triggerNotification(
        payment.client_id,
        'Payment Verification Issue',
        `Your trainer could not verify your payment (${rejectionReason || 'Reference not found'}). Please resubmit.`,
        'PAYMENT'
      );
    }

    store.notify();
  },

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

        const clientPkg = state.client_packages.find(cp => cp.id === session.client_package_id);
        if (clientPkg && clientPkg.remaining_sessions > 0) {
          clientPkg.remaining_sessions -= 1;
          clientPkg.completed_sessions += 1;

          // Low Credit Warning Trigger
          if (clientPkg.remaining_sessions <= 2 && clientPkg.remaining_sessions > 0) {
            this.triggerNotification(
              session.client_id,
              'Low Session Credits Warning ⚠️',
              `You have only ${clientPkg.remaining_sessions} PT credit(s) remaining in your package. Consider renewing soon!`,
              'WARNING'
            );
          }
        }
      }

      this.triggerNotification(
        session.client_id,
        'Workout Completed! 💪',
        `Your session was marked completed. Remaining credits: ${
          session.client_package_id ? (state.client_packages.find(cp => cp.id === session.client_package_id)?.remaining_sessions ?? 0) : 'N/A'
        }. Great work!`,
        'WORKOUT'
      );
    }

    store.notify();
  },

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
