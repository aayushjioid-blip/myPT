// Trainer Inbound Requests & Payment Verification Queue View

import { store } from '../../state/store.js';

export function renderTrainerRequestsView() {
  const state = store.getState();
  const trainer = store.getCurrentTrainerProfile() || state.trainers[0];

  // Inbound consultation/interest requests
  const pendingRequests = state.relationships.filter(r => r.trainer_id === trainer.id && r.status === 'REQUESTED');

  // Pending offline payments
  const pendingPayments = state.payments.filter(p => p.trainer_id === trainer.id && p.payment_status === 'PENDING_VERIFICATION');

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div>
        <h2 class="text-2xl font-extrabold">Inbound & Payments Queue</h2>
        <p class="text-xs text-muted">Review client consultation requests and verify offline payments.</p>
      </div>

      <!-- SECTION 1: Offline Payment Verification Queue (RULE 4) -->
      <div class="flex justify-between items-center" style="margin-top: 0.5rem;">
        <span class="text-xs font-bold text-primary uppercase tracking-wider">
          Payment Verification Queue (${pendingPayments.length})
        </span>
      </div>

      <div class="flex flex-col gap-3">
        ${pendingPayments.length > 0 ? pendingPayments.map(p => {
          const clientObj = state.users.find(u => u.id === p.client_id) || { name: 'Sarah Jenkins', email: 'client@test.local' };
          const pkgObj = state.packages.find(pkg => pkg.id === p.package_id) || { name: '10 PT Sessions Starter Pack', sessions: 10, price: 499 };

          return `
            <div class="card card-glow" style="border-color: var(--color-accent-amber);">
              <div class="flex justify-between items-start" style="margin-bottom: 0.75rem;">
                <div>
                  <span class="badge badge-amber" style="margin-bottom: 0.25rem;">Payment Verification Required</span>
                  <div class="font-bold text-base">${clientObj.name}</div>
                  <div class="text-xs text-muted">${clientObj.email}</div>
                </div>
                <div class="text-right">
                  <div class="text-xl font-bold text-primary">$${p.amount}</div>
                  <div class="text-xs text-muted font-mono">${p.payment_method}</div>
                </div>
              </div>

              <div class="card" style="padding: 0.75rem; background: var(--bg-input); margin-bottom: 0.75rem;">
                <div class="flex justify-between items-center text-xs">
                  <span class="text-muted">Package:</span>
                  <span class="font-semibold">${pkgObj.name} (${pkgObj.sessions} Sessions)</span>
                </div>
                <div class="flex justify-between items-center text-xs" style="margin-top: 0.25rem;">
                  <span class="text-muted">Transaction Ref:</span>
                  <span class="font-mono font-bold text-amber">${p.transaction_reference}</span>
                </div>
              </div>

              <div class="flex gap-2">
                <button 
                  class="btn btn-danger btn-sm flex-1" 
                  onclick="window.verifyPayment('${p.id}', false)">
                  Reject ✕
                </button>
                <button 
                  class="btn btn-primary btn-sm flex-1 font-bold" 
                  onclick="window.verifyPayment('${p.id}', true)">
                  Verify & Activate Package (10 Sessions) ✓
                </button>
              </div>
            </div>
          `;
        }).join('') : `
          <div class="card" style="padding: 1.25rem; text-align: center;">
            <div class="text-xs text-muted">No pending payments waiting for verification.</div>
          </div>
        `}
      </div>

      <!-- SECTION 2: Client Consultation & Connection Requests -->
      <div class="flex justify-between items-center" style="margin-top: 1rem;">
        <span class="text-xs font-bold text-muted uppercase tracking-wider">
          Consultation Requests (${pendingRequests.length})
        </span>
      </div>

      <div class="flex flex-col gap-3">
        ${pendingRequests.length > 0 ? pendingRequests.map(r => {
          const clientObj = state.users.find(u => u.id === r.client_id) || { name: 'Client' };

          return `
            <div class="card card-glow">
              <div class="flex justify-between items-start" style="margin-bottom: 0.5rem;">
                <div class="flex items-center gap-3">
                  <div class="trainer-avatar">${clientObj.name.charAt(0)}</div>
                  <div>
                    <div class="font-bold text-base">${clientObj.name}</div>
                    <div class="text-xs text-muted font-mono">Goal: ${r.goals || 'General Fitness'}</div>
                  </div>
                </div>
                <span class="badge badge-amber">Pending</span>
              </div>

              ${r.notes ? `
                <div class="text-xs text-muted" style="background: var(--bg-input); padding: 0.5rem; border-radius: 8px; margin-bottom: 0.75rem;">
                  "${r.notes}"
                </div>
              ` : ''}

              <div class="flex gap-2">
                <button class="btn btn-secondary btn-sm flex-1" onclick="alert('Client declined.')">Decline</button>
                <button class="btn btn-primary btn-sm flex-1 font-bold" onclick="window.acceptClient('${r.id}')">
                  Accept & Approve Client ✓
                </button>
              </div>
            </div>
          `;
        }).join('') : `
          <div class="card" style="padding: 1.25rem; text-align: center;">
            <div class="text-xs text-muted">No pending client requests.</div>
          </div>
        `}
      </div>
    </div>
  `;
}
