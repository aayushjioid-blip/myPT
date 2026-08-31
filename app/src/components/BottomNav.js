// Role-based Bottom Navigation Bar Component

import { store } from '../state/store.js';

export function renderBottomNav() {
  const state = store.getState();
  const user = store.getCurrentUser();
  const currentTab = state.currentTab;

  let tabs = [];

  if (user.role === 'CLIENT') {
    tabs = [
      { id: 'home', label: 'Home', icon: '🏠' },
      { id: 'discover', label: 'Trainers', icon: '🔍' },
      { id: 'packages', label: 'Packages', icon: '📦' },
      { id: 'workout', label: 'Workouts', icon: '💪' },
      { id: 'calendar', label: 'Schedule', icon: '📅' },
      { id: 'progress', label: 'Progress', icon: '📈' }
    ];
  } else if (user.role === 'TRAINER') {
    // Count pending requests and payments for badges
    const pendingReqs = state.relationships.filter(r => r.trainer_id === 'trn-alex' && r.status === 'REQUESTED').length;
    const pendingPays = state.payments.filter(p => p.trainer_id === 'trn-alex' && p.payment_status === 'PENDING_VERIFICATION').length;
    const totalTrainerPending = pendingReqs + pendingPays;

    tabs = [
      { id: 'home', label: 'Dashboard', icon: '📊' },
      { id: 'requests', label: 'Requests', icon: '📥', badge: totalTrainerPending },
      { id: 'clients', label: 'Clients', icon: '👥' },
      { id: 'workouts', label: 'Workouts', icon: '🏋️' },
      { id: 'calendar', label: 'Schedule', icon: '📅' },
      { id: 'packages', label: 'Packages', icon: '🏷️' }
    ];
  } else if (user.role === 'HEAD_TRAINER' || user.role === 'GYM_MANAGER') {
    tabs = [
      { id: 'home', label: 'Gym KPIs', icon: '🏢' },
      { id: 'trainers', label: 'Trainers', icon: '👥' },
      { id: 'clients', label: 'Clients', icon: '📋' },
      { id: 'calendar', label: 'Facility', icon: '📅' },
      { id: 'reports', label: 'Reports', icon: '📑' }
    ];
  } else if (user.role === 'SUPER_ADMIN') {
    tabs = [
      { id: 'home', label: 'Overview', icon: '🛡️' },
      { id: 'trainers', label: 'Trainers', icon: '🏋️' },
      { id: 'flags', label: 'Flags', icon: '🚩' },
      { id: 'settings', label: 'Settings', icon: '⚙️' }
    ];
  }

  return `
    <nav class="bottom-nav">
      ${tabs.map(tab => `
        <button 
          class="nav-item ${currentTab === tab.id ? 'active' : ''}" 
          onclick="window.switchTab('${tab.id}')">
          <span class="nav-icon">${tab.icon}</span>
          <span class="nav-label">${tab.label}</span>
          ${tab.badge > 0 ? `<span class="nav-badge-count">${tab.badge}</span>` : ''}
        </button>
      `).join('')}
    </nav>
  `;
}
