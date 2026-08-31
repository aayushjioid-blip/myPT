// FitTrainer Main Application Bootstrap & Router

import { store } from './state/store.js';
import { Actions } from './state/actions.js';

// Components
import { renderRoleSwitcherHUD } from './components/RoleSwitcherHUD.js';
import { renderTopHeader } from './components/TopHeader.js';
import { renderBottomNav } from './components/BottomNav.js';
import { renderConsultationModal } from './components/ConsultationModal.js';
import { renderPaymentModal } from './components/PaymentModal.js';
import { renderWorkoutLoggerModal } from './components/WorkoutLoggerModal.js';
import { renderPackageBuilderModal } from './components/PackageBuilderModal.js';

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
  toast.className = 'toast';
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

  // 5. Render Active Modal if any
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
        default:
          modalContainer.innerHTML = '';
      }
    } else {
      modalContainer.innerHTML = '';
    }
  }
}

// Global Window Event Handlers for Interaction
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

window.openConsultationModal = (trainerId) => {
  store.openModal('consultation', { trainerId });
};

window.submitConsultation = (e, trainerId) => {
  e.preventDefault();
  const goal = document.getElementById('consult-goal').value;
  const notes = document.getElementById('consult-notes').value;
  Actions.sendConsultationRequest(trainerId, goal, notes);
  store.closeModal();
  showToast('Consultation request sent to trainer! Switch to Trainer role to accept.', '🚀');
};

window.openPaymentModal = (packageId) => {
  store.openModal('payment', { packageId });
};

window.submitMockPayment = (e, packageId) => {
  e.preventDefault();
  const ref = document.getElementById('payment-ref').value;
  Actions.selectPackageAndSubmitPayment(packageId, ref);
  store.closeModal();
  showToast('Payment submitted for verification! Switch to Trainer role to verify.', '💳');
};

window.verifyPayment = (paymentId, approve) => {
  Actions.verifyPayment(paymentId, approve);
  if (approve) {
    showToast('Payment verified! Package activated with 10 session credits.', '🎉');
  } else {
    showToast('Payment marked rejected.', '❌');
  }
};

window.acceptClient = (relationshipId) => {
  Actions.acceptClientRequest(relationshipId);
  showToast('Client accepted and approved for package purchases!', '✓');
};

window.submitSessionBooking = (e, trainerId, clientPackageId) => {
  e.preventDefault();
  const date = document.getElementById('booking-date').value;
  const time = document.getElementById('booking-time').value;
  Actions.requestSessionBooking(trainerId, clientPackageId, date, time);
  showToast('Session booking request sent to trainer (0 credits deducted on booking).', '📅');
};

window.acceptBooking = (sessionId) => {
  Actions.acceptBookingRequest(sessionId);
  showToast('Session booking confirmed!', '✓');
};

window.openWorkoutLoggerModal = (sessionId, workoutId) => {
  store.openModal('workout-logger', { sessionId, workoutId });
};

window.finishSessionAndDeductCredit = (sessionId, workoutId) => {
  Actions.completeSessionAndLogWorkout(sessionId, workoutId);
  store.closeModal();
  showToast('Session Completed! Exactly 1 PT credit deducted (Balance: 10 ➔ 9).', '🏆');
};

window.promptLogOwnWorkout = () => {
  const name = prompt('Enter routine name for your Own Workout:', 'Chest & Core Self-Workout');
  if (name) {
    Actions.logOwnWorkout(name);
    showToast('Own Workout logged! 0 PT session credits consumed.', '🛡️');
  }
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

window.assignWorkoutToClient = (clientId) => {
  Actions.assignWorkout(clientId, 'tmpl-upper-hypertrophy');
  showToast('Upper Body routine assigned to Sarah Jenkins!', '📋');
};

window.toggleTrainerSharing = (checked) => {
  Actions.toggleClientPersonalInfoSharing(checked);
  showToast(checked ? 'Health information shared with your trainer.' : 'Health information set to private.', '🔒');
};

window.toggleFeatureFlag = (key, checked) => {
  Actions.toggleFeatureFlag(key, checked);
  showToast(`Feature flag "${key}" set to ${checked}`, '🚩');
};

window.promptTrainerCode = () => {
  const code = prompt('Enter 6-Character Trainer Code (e.g. TRN001 or LEO007):', 'TRN001');
  if (code) {
    const trainer = store.getState().trainers.find(t => t.trainer_code.toUpperCase() === code.toUpperCase().trim());
    if (trainer) {
      window.openConsultationModal(trainer.id);
    } else {
      alert(`No trainer found with code: ${code}`);
    }
  }
};

window.openNotificationsModal = () => {
  const state = store.getState();
  const user = store.getCurrentUser();
  const notifs = state.notifications.filter(n => n.user_id === user.id);
  alert(`Notifications for ${user.name}:\n\n` + (notifs.length > 0 ? notifs.map(n => `• [${n.title}] ${n.message}`).join('\n\n') : 'No notifications.'));
};

window.openUserProfile = () => {
  const user = store.getCurrentUser();
  alert(`User Profile:\n\nName: ${user.name}\nRole: ${user.role}\nEmail: ${user.email}\nStatus: ${user.status}`);
};

// Initialize Application
store.subscribe(renderApp);
document.documentElement.setAttribute('data-theme', store.getState().currentTheme);
renderApp();
console.log('⚡ FitTrainer prototype initialized successfully.');
