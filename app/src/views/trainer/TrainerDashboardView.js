// Trainer Dashboard & Operations Command Center

import { store } from '../../state/store.js';

export function renderTrainerDashboardView() {
  const state = store.getState();
  const trainer = store.getCurrentTrainerProfile() || state.trainers[0];

  // Pending Actions
  const pendingRequests = state.relationships.filter(r => r.trainer_id === trainer.id && r.status === 'REQUESTED');
  const pendingPayments = state.payments.filter(p => p.trainer_id === trainer.id && p.payment_status === 'PENDING_VERIFICATION');
  const totalPending = pendingRequests.length + pendingPayments.length;

  // Active Sessions
  const todaySessions = state.sessions.filter(s => s.trainer_id === trainer.id && s.status !== 'COMPLETED');
  const completedSessions = state.sessions.filter(s => s.trainer_id === trainer.id && s.status === 'COMPLETED');

  // Low Credit Clients Alert
  const lowCreditClients = state.client_packages.filter(cp => cp.trainer_id === trainer.id && cp.status === 'ACTIVE' && cp.remaining_sessions <= 2);

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <!-- Trainer Header -->
      <div class="flex justify-between items-center">
        <div>
          <div class="text-xs text-muted font-semibold uppercase">Trainer Portal</div>
          <h2 class="text-2xl font-extrabold">${trainer.name} 🏋️</h2>
        </div>
        <div class="badge badge-primary">
          ${trainer.verification_status}
        </div>
      </div>

      <!-- Quick Metrics -->
      <div class="stat-grid">
        <div class="stat-box">
          <span class="stat-label">Active Clients</span>
          <span class="stat-value text-primary">12</span>
          <span class="text-xs text-muted">98% retention</span>
        </div>

        <div class="stat-box">
          <span class="stat-label">Sessions Today</span>
          <span class="stat-value text-blue">${todaySessions.length}</span>
          <span class="text-xs text-muted">${completedSessions.length} completed</span>
        </div>
      </div>

      <!-- Action Required Banner (Requests & Payments) -->
      ${totalPending > 0 ? `
        <div class="card card-glow" style="background: rgba(245, 158, 11, 0.1); border-color: var(--color-accent-amber); cursor: pointer;" onclick="window.switchTab('requests')">
          <div class="flex justify-between items-center">
            <div class="flex items-center gap-3">
              <span style="font-size: 1.5rem;">📥</span>
              <div>
                <div class="font-bold text-sm text-amber">${totalPending} Pending Item(s) Need Review</div>
                <div class="text-xs text-muted">
                  ${pendingRequests.length} Consultation Requests • ${pendingPayments.length} Offline Payments
                </div>
              </div>
            </div>
            <button class="btn btn-primary btn-sm">Review ➔</button>
          </div>
        </div>
      ` : `
        <div class="card" style="padding: 0.85rem; background: var(--bg-surface);">
          <div class="flex items-center gap-2 text-xs text-muted">
            <span class="text-primary">✓</span> All pending client consultation and payment verification queues are clear!
          </div>
        </div>
      `}

      <!-- Low Session Credit Alerts -->
      ${lowCreditClients.length > 0 ? `
        <div class="card" style="border-color: rgba(239, 68, 68, 0.4); background: rgba(239, 68, 68, 0.06);">
          <div class="flex items-center gap-2" style="margin-bottom: 0.35rem;">
            <span style="font-size: 1rem;">⚠️</span>
            <span class="text-xs font-bold text-rose uppercase">Low Credit Warning</span>
          </div>
          <div class="text-xs text-muted">
            Client has <strong>${lowCreditClients[0].remaining_sessions} session(s) left</strong>. Prompt for package renewal soon.
          </div>
        </div>
      ` : ''}

      <!-- Today's Schedule & Sessions -->
      <div class="flex justify-between items-center" style="margin-top: 0.5rem;">
        <span class="text-xs font-bold text-muted uppercase tracking-wider">Today's Sessions (${todaySessions.length})</span>
        <button class="btn btn-ghost btn-sm" onclick="window.switchTab('calendar')">View Calendar ➔</button>
      </div>

      <div class="flex flex-col gap-2">
        ${todaySessions.length > 0 ? todaySessions.map(s => {
          const clientObj = state.users.find(u => u.id === s.client_id) || { name: 'Client' };

          return `
            <div class="card">
              <div class="flex justify-between items-start" style="margin-bottom: 0.5rem;">
                <div class="flex items-center gap-3">
                  <div class="trainer-avatar" style="width:40px; height:40px; font-size:1.1rem;">${clientObj.name.charAt(0)}</div>
                  <div>
                    <div class="font-bold text-sm">${clientObj.name}</div>
                    <div class="text-xs text-muted font-mono">${s.scheduled_start.replace('T', ' at ')}</div>
                  </div>
                </div>
                <span class="badge ${s.status === 'CONFIRMED' ? 'badge-primary' : 'badge-amber'}">${s.status}</span>
              </div>

              <div class="flex gap-2" style="margin-top: 0.5rem; padding-top: 0.5rem; border-top: 1px solid var(--border-color);">
                ${s.status === 'REQUESTED' ? `
                  <button class="btn btn-primary btn-sm flex-1" onclick="window.acceptBooking('${s.id}')">Accept Booking ✓</button>
                ` : `
                  <button class="btn btn-primary btn-sm flex-1 font-bold" onclick="window.openWorkoutLoggerModal('${s.id}')">
                    Start Session ⏱️
                  </button>
                `}
              </div>
            </div>
          `;
        }).join('') : `
          <div class="card" style="text-align: center; padding: 1.5rem;">
            <div class="text-xs text-muted">No pending sessions for today.</div>
          </div>
        `}
      </div>
    </div>
  `;
}
