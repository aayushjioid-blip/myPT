// Floating Role Switcher & Developer HUD

import { store } from '../state/store.js';

export function renderRoleSwitcherHUD() {
  const state = store.getState();
  const currentUser = store.getCurrentUser();

  const roles = [
    { role: 'CLIENT', id: 'usr-client-1', label: 'Client (Sarah)', icon: '🏃‍♀️' },
    { role: 'TRAINER', id: 'usr-trn-1', label: 'Trainer (Alex)', icon: '🏋️' },
    { role: 'HEAD_TRAINER', id: 'usr-headtrn-1', label: 'Head Trainer', icon: '👑' },
    { role: 'GYM_MANAGER', id: 'usr-gymmgr-1', label: 'Gym Manager', icon: '🏢' },
    { role: 'SUPER_ADMIN', id: 'usr-admin-1', label: 'Super Admin', icon: '🛡️' }
  ];

  return `
    <div class="role-hud animate-fade-in" id="role-hud">
      <div style="font-size: 0.75rem; font-weight: 700; color: var(--text-subtle); padding-left: 0.35rem; display: flex; align-items: center; gap: 0.25rem;">
        <span style="display:inline-block; width:6px; height:6px; background:#10B981; border-radius:50%;"></span>
        ROLE:
      </div>
      ${roles.map(r => `
        <button 
          class="hud-role-btn ${currentUser.id === r.id ? 'active' : ''}" 
          onclick="window.switchRole('${r.id}')"
          title="Switch to ${r.label}">
          <span>${r.icon}</span>
          <span>${r.label.split(' ')[0]}</span>
        </button>
      `).join('')}
      <button 
        class="hud-role-btn" 
        style="color: var(--color-accent-amber);" 
        onclick="window.resetSeedData()"
        title="Reset mock state data">
        🔄 Reset
      </button>
    </div>
  `;
}
