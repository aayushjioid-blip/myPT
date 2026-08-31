// Top App Header Component

import { store } from '../state/store.js';

export function renderTopHeader() {
  const state = store.getState();
  const user = store.getCurrentUser();
  const unreadCount = state.notifications.filter(n => n.user_id === user.id && !n.read).length;
  const isDark = state.currentTheme === 'dark';

  return `
    <header class="app-header">
      <div class="brand-title">
        <span>⚡ FitTrainer</span>
      </div>

      <div class="flex items-center gap-2">
        <!-- Theme Toggle -->
        <button 
          class="btn btn-ghost btn-sm" 
          onclick="window.toggleTheme()" 
          title="Toggle Light/Dark Theme"
          style="padding: 0.4rem; border-radius: 50%;">
          ${isDark ? '☀️' : '🌙'}
        </button>

        <!-- Notification Bell -->
        <button 
          class="btn btn-ghost btn-sm" 
          onclick="window.openNotificationsModal()" 
          title="Notifications"
          style="padding: 0.4rem; border-radius: 50%; position: relative;">
          🔔
          ${unreadCount > 0 ? `<span class="nav-badge-count" style="top:-2px; right:-2px;">${unreadCount}</span>` : ''}
        </button>

        <!-- Current User Avatar Pill -->
        <div 
          class="badge badge-subtle flex items-center gap-1" 
          style="padding: 0.35rem 0.65rem; border-radius: 20px; font-size: 0.75rem; text-transform:none; cursor: pointer;"
          onclick="window.openUserProfile()">
          <span>${user.avatar || '👤'}</span>
          <span class="font-semibold">${user.name.split(' ')[0]}</span>
        </div>
      </div>
    </header>
  `;
}
