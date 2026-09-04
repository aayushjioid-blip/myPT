// FitTrainer Main Application Bootstrap & Master Router (Stage 1B Master)

import { store } from './state/store.js';
import { Actions } from './state/actions.js';

// Components & Modals
import { renderRoleSwitcherHUD } from './components/RoleSwitcherHUD.js';
import { renderTopHeader } from './components/TopHeader.js';
import { renderBottomNav } from './components/BottomNav.js';
import { renderConsultationModal } from './components/ConsultationModal.js';
import { renderPaymentModal } from './components/PaymentModal.js';
import { renderWorkoutLoggerModal } from './components/WorkoutLoggerModal.js';
import { renderPackageBuilderModal } from './components/PackageBuilderModal.js';
import { renderMeasurementLoggerModal } from './components/MeasurementLoggerModal.js';
import { renderOwnWorkoutBuilderModal } from './components/OwnWorkoutBuilderModal.js';
import { renderCustomExerciseModal } from './components/CustomExerciseModal.js';
import { renderTemplateBuilderModal } from './components/TemplateBuilderModal.js';
import { renderClientReassignmentModal } from './components/ClientReassignmentModal.js';
import { renderTrainerReviewModal } from './components/TrainerReviewModal.js';
import { renderNotificationCenterModal } from './components/NotificationCenterModal.js';

// Views
import { renderClientHomeView } from './views/client/ClientHomeView.js';
import { renderTrainerDiscoveryView } from './views/client/TrainerDiscoveryView.js';
import { renderClientPackagesView } from './views/client/ClientPackagesView.js';
import { renderClientWorkoutView } from './views/client/ClientWorkoutView.js';
import { renderClientCalendarView } from './views/client/ClientCalendarView.js';
import { renderClientProgressView } from './views/client/ClientProgressView.js';

import { renderTrainerDashboardView } from './views/trainer/TrainerDashboardView.js';
import { renderTrainerRequestsView } from './views/trainer/TrainerRequestsView.js';
import { renderTrainerClientsView } from './views/trainer/TrainerClientsView.js';
import { renderTrainerCalendarView } from './views/trainer/TrainerCalendarView.js';
import { renderTrainerWorkoutsView } from './views/trainer/TrainerWorkoutsView.js';
import { renderTrainerPackagesView } from './views/trainer/TrainerPackagesView.js';

import { renderGymDashboardView } from './views/gym/GymDashboardView.js';
import { renderAdminDashboardView } from './views/admin/AdminDashboardView.js';

// Toast helper
function showToast(message, icon = '⚡') {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = 'toast animate-fade-in';
  toast.innerHTML = `<span>${icon}</span> <span>${message}</span>`;
  container.appendChild(toast);

  setTimeout(() => {
    toast.remove();
  }, 3500);
}

// Master Render Loop
function renderApp() {
  const state = store.getState();
  const user = store.getCurrentUser();
  const role = user.role;
  const currentTab = state.currentTab;

  // 1. Render Floating HUD
  const hudContainer = document.getElementById('role-hud-root');
  if (hudContainer) {
    hudContainer.innerHTML = renderRoleSwitcherHUD();
  }

  // 2. Render Header
  const headerContainer = document.getElementById('header-root');
  if (headerContainer) {
    headerContainer.innerHTML = renderTopHeader();
  }

  // 3. Render Bottom Navigation
  const navContainer = document.getElementById('nav-root');
  if (navContainer) {
    navContainer.innerHTML = renderBottomNav();
  }

  // 4. Render Active View
  const viewContainer = document.getElementById('view-root');
  if (!viewContainer) return;

  let viewHtml = '';

  if (role === 'CLIENT') {
    switch (currentTab) {
      case 'home': viewHtml = renderClientHomeView(); break;
      case 'discover': viewHtml = renderTrainerDiscoveryView(); break;
      case 'packages': viewHtml = renderClientPackagesView(); break;
      case 'workout': viewHtml = renderClientWorkoutView(); break;
      case 'calendar': viewHtml = renderClientCalendarView(); break;
      case 'progress': viewHtml = renderClientProgressView(); break;
      default: viewHtml = renderClientHomeView();
    }
  } else if (role === 'TRAINER') {
    switch (currentTab) {
      case 'home': viewHtml = renderTrainerDashboardView(); break;
      case 'requests': viewHtml = renderTrainerRequestsView(); break;
      case 'clients': viewHtml = renderTrainerClientsView(); break;
      case 'calendar': viewHtml = renderTrainerCalendarView(); break;
      case 'workouts': viewHtml = renderTrainerWorkoutsView(); break;
      case 'packages': viewHtml = renderTrainerPackagesView(); break;
      default: viewHtml = renderTrainerDashboardView();
    }
  } else if (role === 'HEAD_TRAINER' || role === 'GYM_MANAGER') {
    viewHtml = renderGymDashboardView();
  } else if (role === 'SUPER_ADMIN') {
    viewHtml = renderAdminDashboardView();
  }

  viewContainer.innerHTML = viewHtml;

  // 5. Render Active Modal
  const modalContainer = document.getElementById('modal-root');
  if (modalContainer) {
    if (state.activeModal) {
      switch (state.activeModal.type) {
        case 'consultation':
          modalContainer.innerHTML = renderConsultationModal(state.activeModal.data);
          break;
        case 'payment':
          modalContainer.innerHTML = renderPaymentModal(state.activeModal.data);
          break;
        case 'workout-logger':
          modalContainer.innerHTML = renderWorkoutLoggerModal(state.activeModal.data);
          break;
        case 'package-builder':
          modalContainer.innerHTML = renderPackageBuilderModal();
          break;
        case 'measurement-logger':
          modalContainer.innerHTML = renderMeasurementLoggerModal(state.activeModal.data);
          break;
        case 'own-workout-builder':
          modalContainer.innerHTML = renderOwnWorkoutBuilderModal();
          break;
        case 'custom-exercise':
          modalContainer.innerHTML = renderCustomExerciseModal();
          break;
        case 'template-builder':
          modalContainer.innerHTML = renderTemplateBuilderModal(state.activeModal.data);
          break;
        case 'client-reassignment':
          modalContainer.innerHTML = renderClientReassignmentModal(state.activeModal.data);
          break;
        case 'trainer-review':
          modalContainer.innerHTML = renderTrainerReviewModal(state.activeModal.data);
          break;
        case 'notifications':
          modalContainer.innerHTML = renderNotificationCenterModal();
          break;
        default:
          modalContainer.innerHTML = '';
      }
    } else {
      modalContainer.innerHTML = '';
    }
  }
}

// =========================================================================
// Global Window Event Handlers for Interactive Prototypes Across All Roles
// =========================================================================

window.switchRole = (userId) => {
  store.setCurrentUser(userId);
  const user = store.getCurrentUser();
  showToast(`Switched active profile to: ${user.name} (${user.role})`, user.avatar || '👤');
};

window.switchTab = (tabId) => {
  store.setCurrentTab(tabId);
};

window.toggleTheme = () => {
  const current = store.getState().currentTheme;
  const newTheme = current === 'dark' ? 'light' : 'dark';
  store.setTheme(newTheme);
  showToast(`Theme changed to ${newTheme.toUpperCase()}`, newTheme === 'dark' ? '🌙' : '☀️');
};

window.resetSeedData = () => {
  if (confirm('Reset prototype state to initial mock data?')) {
    store.resetToDefaults();
    showToast('Mock state successfully reset to initial seed values.', '🔄');
  }
};

window.closeModal = () => {
  store.closeModal();
};

// Milestone 1 Handlers
window.openMeasurementModal = (data = {}) => {
  store.openModal('measurement-logger', data);
};

window.updateModalBmiCalculation = () => {
  const wInput = document.getElementById('m-weight');
  const hInput = document.getElementById('m-height');
  const bmiDisplay = document.getElementById('m-bmi-display');
  if (wInput && hInput && bmiDisplay) {
    const w = parseFloat(wInput.value) || 65;
    const h = parseFloat(hInput.value) || 168;
    const hM = h / 100;
    const bmi = (w / (hM * hM)).toFixed(1);
    const label = bmi < 18.5 ? 'Underweight' : bmi < 25 ? 'Normal' : bmi < 30 ? 'Overweight' : 'Obese';
    bmiDisplay.value = `${bmi} (${label})`;
  }
};

window.submitBodyMeasurement = (e) => {
  e.preventDefault();
  const weight = document.getElementById('m-weight').value;
  const height_cm = document.getElementById('m-height').value;
  const date = document.getElementById('m-date').value;
  const body_fat = document.getElementById('m-bodyfat').value;
  const chest = document.getElementById('m-chest').value;
  const waist = document.getElementById('m-waist').value;
  const hips = document.getElementById('m-hips').value;
  const biceps = document.getElementById('m-biceps').value;
  const thighs = document.getElementById('m-thighs').value;
  const calves = document.getElementById('m-calves').value;
  const notes = document.getElementById('m-notes').value;

  Actions.logProgressMeasurement({
    weight, height_cm, date, body_fat, chest, waist, hips, biceps, thighs, calves, notes
  });
  store.closeModal();
  showToast('Body measurement entry saved successfully!', '📐');
};

window.openOwnWorkoutModal = () => {
  store.openModal('own-workout-builder');
};

window.submitOwnWorkoutForm = (e) => {
  e.preventDefault();
  const name = document.getElementById('own-wo-name').value;
  const notes = document.getElementById('own-wo-notes').value;
  const checkedBoxes = Array.from(document.querySelectorAll('.own-ex-checkbox:checked'));
  
  const exercises = checkedBoxes.map((cb, idx) => {
    const exObj = store.getState().exercises.find(ex => ex.id === cb.value) || { name: 'Exercise' };
    return {
      id: `ex-own-${idx}`,
      exercise_id: cb.value,
      name: exObj.name,
      sets: 3,
      repetitions: 12,
      weight_kg: 40,
      is_completed: true
    };
  });

  Actions.createAndLogOwnWorkout(name, exercises, notes);
  store.closeModal();
  showToast('Own Workout Logged! Strict Rule: 0 PT Credits consumed.', '🛡️');
};

// Milestone 2 Handlers
window.openCustomExerciseModal = () => {
  store.openModal('custom-exercise');
};

window.submitCustomExerciseForm = (e) => {
  e.preventDefault();
  const name = document.getElementById('cust-ex-name').value;
  const category = document.getElementById('cust-ex-category').value;
  const equipment = document.getElementById('cust-ex-equipment').value;
  const target = document.getElementById('cust-ex-target').value;
  const desc = document.getElementById('cust-ex-desc').value;

  Actions.createCustomExercise(name, category, equipment, target, desc);
  store.closeModal();
  showToast(`Custom exercise "${name}" added to library!`, '🏋️');
};

window.openTemplateBuilderModal = (templateId = '') => {
  store.openModal('template-builder', { templateId });
};

window.submitTemplateBuilderForm = (e, templateId) => {
  e.preventDefault();
  const name = document.getElementById('tmpl-name').value;
  const desc = document.getElementById('tmpl-desc').value;
  const checkedBoxes = Array.from(document.querySelectorAll('.tmpl-ex-checkbox:checked'));
  
  const exercises = checkedBoxes.map(cb => {
    const ex = store.getState().exercises.find(e => e.id === cb.value) || { name: 'Exercise' };
    return {
      exercise_id: cb.value,
      name: ex.name,
      sets: 3,
      reps: 10,
      weight: 50,
      rest: 60
    };
  });

  if (templateId) {
    Actions.updateWorkoutTemplate(templateId, { name, description: desc, exercises });
    showToast(`Template "${name}" updated!`, '💾');
  } else {
    Actions.saveWorkoutTemplate(name, desc, exercises);
    showToast(`New template "${name}" saved!`, '📋');
  }
  store.closeModal();
};

window.filterExercisesCategory = (cat, element) => {
  document.querySelectorAll('.filter-chip').forEach(c => c.classList.remove('active'));
  if (element) element.classList.add('active');

  const items = document.querySelectorAll('#exercise-catalog-list > div');
  items.forEach(item => {
    if (cat === 'All' || item.dataset.category === cat) {
      item.style.display = 'block';
    } else {
      item.style.display = 'none';
    }
  });
};

// Milestone 3 Calendar Handlers
window.submitSessionBooking = (e, trainerId, clientPackageId) => {
  e.preventDefault();
  const date = document.getElementById('booking-date').value;
  const time = document.getElementById('booking-time').value;
  const recurring = parseInt(document.getElementById('booking-recurring')?.value || '1', 10);
  Actions.requestSessionBooking(trainerId, clientPackageId, date, time, recurring);
  showToast(recurring > 1 ? `Requested ${recurring} recurring weekly sessions!` : 'Session booking request sent (0 credits on booking).', '📅');
};

window.acceptBooking = (sessionId) => {
  Actions.acceptBookingRequest(sessionId);
  showToast('Session booking confirmed!', '✓');
};

window.promptRejectBooking = (sessionId) => {
  const reason = prompt('Enter reason for declining session:', 'Trainer schedule conflict');
  if (reason) {
    Actions.rejectBookingRequest(sessionId, reason);
    showToast('Session booking declined.', '✕');
  }
};

window.promptReschedule = (sessionId) => {
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 2);
  const newDate = prompt('Enter new date (YYYY-MM-DD):', tomorrow.toISOString().split('T')[0]);
  if (newDate) {
    const newTime = prompt('Enter new time (HH:MM):', '11:00');
    if (newTime) {
      Actions.rescheduleSession(sessionId, newDate, newTime);
      showToast(`Session moved to ${newDate} at ${newTime}!`, '🔄');
    }
  }
};

window.promptCancelSession = (sessionId) => {
  if (confirm('Cancel this training session? (Subject to 4-hour cancellation rule)')) {
    Actions.cancelSession(sessionId, 'CLIENT', 'Client schedule change');
    showToast('Session cancelled.', '✕');
  }
};

// Milestone 4 Handlers
window.openClientReassignmentModal = (relationshipId) => {
  store.openModal('client-reassignment', { relationshipId });
};

window.submitClientReassignment = (e, relId) => {
  e.preventDefault();
  const newTrainerId = document.getElementById('reassign-new-trainer').value;
  const reason = document.getElementById('reassign-reason').value;
  Actions.reassignClient(relId, newTrainerId, reason);
  store.closeModal();
  showToast('Client successfully reassigned! Historical workout logs preserved.', '👑');
};

// Milestone 6 Handlers
window.openReviewModal = (trainerId) => {
  store.openModal('trainer-review', { trainerId });
};

window.submitReviewForm = (e, trainerId) => {
  e.preventDefault();
  const rating = document.getElementById('review-rating').value;
  const comment = document.getElementById('review-comment').value;
  Actions.submitTrainerReview(trainerId, rating, comment);
  store.closeModal();
  showToast('Review submitted and trainer rating updated! ⭐', '🎉');
};

// Milestone 7 Notifications Handlers
window.openNotificationsModal = () => {
  store.openModal('notifications');
};

window.markNotifRead = (id) => {
  Actions.markNotificationRead(id);
};

window.markAllRead = () => {
  Actions.markAllNotificationsRead();
  showToast('All notifications marked as read.', '✓');
};

// Milestone 8 Handlers
window.toggleTrainerVerificationAdmin = (trainerId, isVerified) => {
  Actions.toggleTrainerVerification(trainerId, isVerified);
  showToast(isVerified ? 'Trainer verified and visible in public search.' : 'Trainer unverified and hidden from public search.', '🛡️');
};

window.toggleFeatureFlag = (key, checked) => {
  Actions.toggleFeatureFlag(key, checked);
  showToast(`Feature flag "${key}" set to ${checked}`, '🚩');
};

window.filterTrainersByName = (query) => {
  const q = query.toLowerCase().trim();
  const cards = document.querySelectorAll('#trainers-list-container > .trainer-card');
  cards.forEach(card => {
    const text = card.innerText.toLowerCase();
    card.style.display = text.includes(q) ? 'block' : 'none';
  });
};

window.openUserProfile = () => {
  const user = store.getCurrentUser();
  alert(`User Profile:\n\nName: ${user.name}\nRole: ${user.role}\nEmail: ${user.email}\nStatus: ${user.status}`);
};

// Stage 1A Legacy Handlers
window.openConsultationModal = (trainerId) => {
  store.openModal('consultation', { trainerId });
};

window.submitConsultation = (e, trainerId) => {
  e.preventDefault();
  const goal = document.getElementById('consult-goal').value;
  const notes = document.getElementById('consult-notes').value;
  Actions.sendConsultationRequest(trainerId, goal, notes);
  store.closeModal();
  showToast('Consultation request sent to trainer!', '🚀');
};

window.openPaymentModal = (packageId) => {
  store.openModal('payment', { packageId });
};

window.submitMockPayment = (e, packageId) => {
  e.preventDefault();
  const ref = document.getElementById('payment-ref').value;
  Actions.selectPackageAndSubmitPayment(packageId, ref);
  store.closeModal();
  showToast('Payment submitted for verification!', '💳');
};

window.verifyPayment = (paymentId, approve) => {
  Actions.verifyPayment(paymentId, approve);
  showToast(approve ? 'Payment verified! Package activated with 10 sessions.' : 'Payment rejected.', approve ? '🎉' : '❌');
};

window.acceptClient = (relationshipId) => {
  Actions.acceptClientRequest(relationshipId);
  showToast('Client accepted and approved for package purchases!', '✓');
};

window.openWorkoutLoggerModal = (sessionId, workoutId) => {
  store.openModal('workout-logger', { sessionId, workoutId });
};

window.finishSessionAndDeductCredit = (sessionId, workoutId) => {
  Actions.completeSessionAndLogWorkout(sessionId, workoutId);
  store.closeModal();
  showToast('Session Completed! Exactly 1 PT credit deducted.', '🏆');
};

window.openPackageBuilderModal = () => {
  store.openModal('package-builder');
};

window.updateSuggestedValidity = (sessions) => {
  const num = parseInt(sessions, 10) || 10;
  const tag = document.getElementById('pkg-validity-suggested-tag');
  const valInput = document.getElementById('pkg-validity');
  if (tag) tag.innerText = `Suggested: ${num * 4} Days (4x)`;
  if (valInput) valInput.value = num * 4;
};

window.submitCreatePackage = (e) => {
  e.preventDefault();
  const name = document.getElementById('pkg-name').value;
  const desc = document.getElementById('pkg-desc').value;
  const sessions = document.getElementById('pkg-sessions').value;
  const price = document.getElementById('pkg-price').value;
  const validity = document.getElementById('pkg-validity').value;

  Actions.createTrainerPackage(name, desc, sessions, price, validity);
  store.closeModal();
  showToast(`Custom package "${name}" created with ${validity} days validity!`, '🏷️');
};

window.assignWorkoutToClient = (clientId, templateId = 'tmpl-upper-hypertrophy') => {
  Actions.assignWorkout(clientId, templateId);
  showToast('Workout routine assigned to client!', '📋');
};

window.toggleTrainerSharing = (checked) => {
  Actions.toggleClientPersonalInfoSharing(checked);
  showToast(checked ? 'Health information shared with trainer.' : 'Health information set to private.', '🔒');
};

window.promptTrainerCode = () => {
  const code = prompt('Enter 6-Character Trainer Code (e.g. TRN001, MAYA02, or LEO007):', 'TRN001');
  if (code) {
    const trainer = store.getState().trainers.find(t => t.trainer_code.toUpperCase() === code.toUpperCase().trim());
    if (trainer) {
      window.openConsultationModal(trainer.id);
    } else {
      alert(`No trainer found with code: ${code}`);
    }
  }
};

// Initialize Application
store.subscribe(renderApp);
document.documentElement.setAttribute('data-theme', store.getState().currentTheme);
renderApp();
console.log('⚡ FitTrainer Stage 1B Master Prototype initialized successfully.');
