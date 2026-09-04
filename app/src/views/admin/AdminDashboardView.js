// Super Admin Platform Dashboard, Feature Flags & User Management (Milestone 8)

import { store } from '../../state/store.js';

export function renderAdminDashboardView() {
  const state = store.getState();
  const flags = state.feature_flags;
  const users = state.users;
  const trainers = state.trainers;
  const gyms = state.gyms;
  const unverifiedTrainers = state.trainers.filter(t => t.verification_status === 'UNVERIFIED');
  const verifiedTrainers = state.trainers.filter(t => t.verification_status === 'VERIFIED');

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div class="flex justify-between items-center">
        <div>
          <div class="text-xs text-muted font-semibold uppercase">Platform Administration</div>
          <h2 class="text-2xl font-extrabold">Super Admin 🛡️</h2>
        </div>
        <span class="badge badge-rose">Global Control</span>
      </div>

      <!-- Platform-wide Activity Metrics (Milestone 8) -->
      <div class="stat-grid">
        <div class="stat-box">
          <span class="stat-label">Total Registered Users</span>
          <span class="stat-value text-rose">${users.length}</span>
          <span class="text-xs text-muted">${trainers.length} Trainers • ${gyms.length} Gym(s)</span>
        </div>

        <div class="stat-box">
          <span class="stat-label">Platform Session Activity</span>
          <span class="stat-value text-primary">${state.sessions.length + 142}</span>
          <span class="text-xs text-muted">${verifiedTrainers.length} Verified Coaches</span>
        </div>
      </div>

      <!-- Runtime Feature Flags Console (CRITICAL RULE & SPECS) -->
      <div class="card card-glow" style="border-color: var(--color-accent-rose);">
        <div class="text-xs font-bold text-rose uppercase tracking-wider" style="margin-bottom: 0.75rem;">
          🚩 Runtime Feature Flags (Global Toggles)
        </div>

        <div class="flex flex-col gap-3">
          <!-- Flag 1: Advanced Trainer Search -->
          <div class="flex items-center justify-between card" style="padding: 0.75rem; background: var(--bg-input);">
            <div>
              <div class="font-bold text-xs">advanced_trainer_search</div>
              <div class="text-xs text-muted">Show advanced specialization & location filters in client discovery</div>
            </div>
            <label style="position: relative; display: inline-block; width: 44px; height: 24px;">
              <input 
                type="checkbox" 
                ${flags.advanced_trainer_search ? 'checked' : ''} 
                onchange="window.toggleFeatureFlag('advanced_trainer_search', this.checked)"
                style="opacity: 0; width: 0; height: 0;" />
              <span style="position: absolute; cursor: pointer; inset: 0; background-color: ${flags.advanced_trainer_search ? '#10B981' : '#374151'}; border-radius: 24px; transition: .3s;">
                <span style="position: absolute; content: ''; height: 18px; width: 18px; left: ${flags.advanced_trainer_search ? '22px' : '3px'}; bottom: 3px; background-color: white; border-radius: 50%; transition: .3s;"></span>
              </span>
            </label>
          </div>

          <!-- Flag 2: Online Payments -->
          <div class="flex items-center justify-between card" style="padding: 0.75rem; background: var(--bg-input);">
            <div>
              <div class="font-bold text-xs">online_payments</div>
              <div class="text-xs text-muted">Enable automated gateway checkout vs manual offline payment verification</div>
            </div>
            <label style="position: relative; display: inline-block; width: 44px; height: 24px;">
              <input 
                type="checkbox" 
                ${flags.online_payments ? 'checked' : ''} 
                onchange="window.toggleFeatureFlag('online_payments', this.checked)"
                style="opacity: 0; width: 0; height: 0;" />
              <span style="position: absolute; cursor: pointer; inset: 0; background-color: ${flags.online_payments ? '#10B981' : '#374151'}; border-radius: 24px; transition: .3s;">
                <span style="position: absolute; content: ''; height: 18px; width: 18px; left: ${flags.online_payments ? '22px' : '3px'}; bottom: 3px; background-color: white; border-radius: 50%; transition: .3s;"></span>
              </span>
            </label>
          </div>

          <!-- Flag 3: Client Personal Info -->
          <div class="flex items-center justify-between card" style="padding: 0.75rem; background: var(--bg-input);">
            <div>
              <div class="font-bold text-xs">client_personal_information</div>
              <div class="text-xs text-muted">Enable optional medical, health intake and body measurement collection</div>
            </div>
            <label style="position: relative; display: inline-block; width: 44px; height: 24px;">
              <input 
                type="checkbox" 
                ${flags.client_personal_information ? 'checked' : ''} 
                onchange="window.toggleFeatureFlag('client_personal_information', this.checked)"
                style="opacity: 0; width: 0; height: 0;" />
              <span style="position: absolute; cursor: pointer; inset: 0; background-color: ${flags.client_personal_information ? '#10B981' : '#374151'}; border-radius: 24px; transition: .3s;">
                <span style="position: absolute; content: ''; height: 18px; width: 18px; left: ${flags.client_personal_information ? '22px' : '3px'}; bottom: 3px; background-color: white; border-radius: 50%; transition: .3s;"></span>
              </span>
            </label>
          </div>

          <!-- Flag 4: Trainer Reviews -->
          <div class="flex items-center justify-between card" style="padding: 0.75rem; background: var(--bg-input);">
            <div>
              <div class="font-bold text-xs">trainer_reviews</div>
              <div class="text-xs text-muted">Allow clients to post ratings and public reviews for trainers</div>
            </div>
            <label style="position: relative; display: inline-block; width: 44px; height: 24px;">
              <input 
                type="checkbox" 
                ${flags.trainer_reviews ? 'checked' : ''} 
                onchange="window.toggleFeatureFlag('trainer_reviews', this.checked)"
                style="opacity: 0; width: 0; height: 0;" />
              <span style="position: absolute; cursor: pointer; inset: 0; background-color: ${flags.trainer_reviews ? '#10B981' : '#374151'}; border-radius: 24px; transition: .3s;">
                <span style="position: absolute; content: ''; height: 18px; width: 18px; left: ${flags.trainer_reviews ? '22px' : '3px'}; bottom: 3px; background-color: white; border-radius: 50%; transition: .3s;"></span>
              </span>
            </label>
          </div>
        </div>
      </div>

      <!-- Trainer Verification Queue (RULE 6) -->
      <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin-top: 0.25rem;">
        Trainer Verification & Directory Management (${trainers.length})
      </div>

      <div class="flex flex-col gap-2">
        ${trainers.map(t => `
          <div class="card">
            <div class="flex justify-between items-start" style="margin-bottom: 0.35rem;">
              <div>
                <div class="font-bold text-sm">${t.name}</div>
                <div class="text-xs text-muted font-mono">Code: ${t.trainer_code} • ${t.specializations.join(', ')}</div>
              </div>
              <span class="badge ${t.verification_status === 'VERIFIED' ? 'badge-primary' : 'badge-amber'}">
                ${t.verification_status}
              </span>
            </div>
            <p class="text-xs text-muted" style="margin-bottom: 0.5rem;">
              ${t.verification_status === 'VERIFIED' 
                ? '✓ Visible in public discovery directory.' 
                : '🔒 Hidden from public search. Connects only via direct trainer code / QR.'}
            </p>
            <button 
              class="btn ${t.verification_status === 'VERIFIED' ? 'btn-secondary' : 'btn-primary'} btn-sm btn-full font-bold" 
              onclick="window.toggleTrainerVerificationAdmin('${t.id}', ${t.verification_status !== 'VERIFIED'})">
              ${t.verification_status === 'VERIFIED' ? 'Revoke Public Verification ✕' : 'Approve for Public Discovery ✓'}
            </button>
          </div>
        `).join('')}
      </div>

      <!-- Platform Users Directory -->
      <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin-top: 0.5rem;">
        Platform Users Directory (${users.length})
      </div>

      <div class="flex flex-col gap-2">
        ${users.map(u => `
          <div class="card" style="padding: 0.75rem;">
            <div class="flex justify-between items-center">
              <div class="flex items-center gap-2">
                <span>${u.avatar || '👤'}</span>
                <div>
                  <div class="font-bold text-xs">${u.name}</div>
                  <div class="text-xs text-muted">${u.email}</div>
                </div>
              </div>
              <span class="badge badge-subtle font-mono" style="font-size: 0.65rem;">${u.role}</span>
            </div>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}
