// Client Packages & Purchase View

import { store } from '../../state/store.js';

export function renderClientPackagesView() {
  const state = store.getState();
  const client = store.getCurrentUser();
  const relationship = state.relationships.find(r => r.client_id === client.id && r.status === 'ACCEPTED');
  const activePackage = state.client_packages.find(cp => cp.client_id === client.id && cp.status === 'ACTIVE');
  const pendingPayment = state.payments.find(p => p.client_id === client.id && p.payment_status === 'PENDING_VERIFICATION');

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div>
        <h2 class="text-2xl font-extrabold">Training Packages</h2>
        <p class="text-xs text-muted">Purchase session credits with your approved personal trainer.</p>
      </div>

      <!-- Pending Payment Banner -->
      ${pendingPayment ? `
        <div class="card" style="border-color: var(--color-accent-amber); background: rgba(245, 158, 11, 0.1);">
          <div class="flex items-center gap-3">
            <span style="font-size: 1.5rem;">⏳</span>
            <div>
              <div class="font-bold text-sm text-amber">Payment Pending Verification</div>
              <div class="text-xs text-muted">Ref: <code>${pendingPayment.transaction_reference}</code> ($${pendingPayment.amount}). Package will activate once your trainer confirms receipt.</div>
            </div>
          </div>
        </div>
      ` : ''}

      <!-- Active Package Summary if available -->
      ${activePackage ? `
        <div class="hero-card">
          <div class="flex flex-col gap-1">
            <div class="text-xs text-primary font-bold uppercase">Active Package</div>
            <div class="text-2xl font-extrabold">${activePackage.remaining_sessions} Sessions Remaining</div>
            <div class="text-xs text-muted">Total: ${activePackage.total_sessions} • Completed: ${activePackage.completed_sessions}</div>
          </div>
          <button class="btn btn-primary btn-sm" onclick="window.switchTab('calendar')">Book Session 📅</button>
        </div>
      ` : ''}

      <!-- Available Trainer Packages -->
      <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin-top: 0.5rem;">
        Available Packages
      </div>

      ${!relationship ? `
        <div class="card" style="text-align: center; padding: 2rem 1rem;">
          <div style="font-size: 2rem; margin-bottom: 0.5rem;">🔒</div>
          <div class="font-bold">Trainer Approval Required</div>
          <p class="text-xs text-muted" style="margin: 0.5rem 0 1rem 0;">
            Under the trainer-first platform rules, you must connect with a trainer and receive approval before purchasing packages.
          </p>
          <button class="btn btn-primary" onclick="window.switchTab('discover')">Find & Connect with Trainer 🔍</button>
        </div>
      ` : `
        <div class="flex flex-col gap-3">
          ${state.packages.map(pkg => `
            <div class="package-card ${pkg.sessions === 10 ? 'highlight' : ''}">
              <div class="flex justify-between items-start">
                <div>
                  <div class="font-bold text-base">${pkg.name}</div>
                  <div class="text-xs text-muted">${pkg.sessions} One-on-One PT Sessions • ${pkg.validity_days} Days Validity</div>
                </div>
                <div class="package-price">$${pkg.price}</div>
              </div>

              <p class="text-xs text-muted">${pkg.description}</p>

              <div class="flex justify-between items-center" style="margin-top: 0.5rem; padding-top: 0.75rem; border-top: 1px solid var(--border-color);">
                <div class="text-xs font-mono text-primary">~$${(pkg.price / pkg.sessions).toFixed(0)} / session</div>
                <button 
                  class="btn btn-primary btn-sm" 
                  onclick="window.openPaymentModal('${pkg.id}')">
                  Select & Pay Offline 💳
                </button>
              </div>
            </div>
          `).join('')}
        </div>
      `}
    </div>
  `;
}
