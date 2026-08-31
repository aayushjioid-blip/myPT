// Super Admin Platform Dashboard & Feature Flags Console View

import { store } from '../../state/store.js';

export function renderAdminDashboardView() {
  const state = store.getState();
  const flags = state.feature_flags;
  const unverifiedTrainers = state.trainers.filter(t => t.verification_status === 'UNVERIFIED');

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div class="flex justify-between items-center">
        <div>
          <div class="text-xs text-muted font-semibold uppercase">Platform Administration</div>
          <h2 class="text-2xl font-extrabold">Super Admin 🛡️</h2>
        </div>
        <span class="badge badge-rose">Global Control</span>
      </div>

      <!-- Runtime Feature Flags Console (RULE 1 & SPECS) -->
      <div class="card card-glow" style="border-color: var(--color-accent-rose);">
        <div class="text-xs font-bold text-rose uppercase tracking-wider" style="margin-bottom: 0.75rem;">
          🚩 Runtime Feature Flags (Global Toggles)
        </div>

        <div class="flex flex-col gap-3">
          <!-- Flag 1: Advanced Trainer Search -->
          <div class="flex items-center justify-between card" style="padding: 0.75rem; background: var(--bg-input);">
            <div>
              <div class="font-bold text-xs">advanced_trainer_search</div>
              <div class="text-xs text-muted">Show advanced specialization & location filters in discovery</div>
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
              <div class="text-xs text-muted">Enable automated payment gateway vs offline manual verification</div>
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
              <div class="text-xs text-muted">Enable optional medical & health info collection</div>
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
        </div>
      </div>

      <!-- Trainer Verification Queue (RULE 6) -->
      <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin-top: 0.5rem;">
        Trainer Verification Queue (${unverifiedTrainers.length})
      </div>

      <div class="flex flex-col gap-2">
        ${unverifiedTrainers.length > 0 ? unverifiedTrainers.map(t => `
          <div class="card">
            <div class="flex justify-between items-start" style="margin-bottom: 0.5rem;">
              <div>
                <div class="font-bold text-sm">${t.name}</div>
                <div class="text-xs text-muted font-mono">Code: ${t.trainer_code} • ${t.specializations.join(', ')}</div>
              </div>
              <span class="badge badge-amber">UNVERIFIED</span>
            </div>
            <p class="text-xs text-muted" style="margin-bottom: 0.5rem;">
              Currently hidden from public trainer discovery search.
            </p>
            <button class="btn btn-primary btn-sm btn-full" onclick="alert('Trainer verified! Leo Novak is now visible in public discovery.')">
              Approve for Public Discovery ✓
            </button>
          </div>
        `).join('') : `
          <div class="card" style="text-align: center; padding: 1rem;">
            <div class="text-xs text-muted">All trainers are verified.</div>
          </div>
        `}
      </div>
    </div>
  `;
}
