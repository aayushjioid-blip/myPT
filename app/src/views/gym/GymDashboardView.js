// Gym Manager & Head Trainer Console View

import { store } from '../../state/store.js';

export function renderGymDashboardView() {
  const state = store.getState();
  const user = store.getCurrentUser();
  const gym = state.gyms[0];

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div class="flex justify-between items-center">
        <div>
          <div class="text-xs text-muted font-semibold uppercase">Gym Facility Management</div>
          <h2 class="text-2xl font-extrabold">${gym ? gym.name : 'IronCore Fitness'} 🏢</h2>
        </div>
        <span class="badge badge-purple">${user.role}</span>
      </div>

      <!-- Facility KPIs -->
      <div class="stat-grid">
        <div class="stat-box">
          <span class="stat-label">Total Staff Trainers</span>
          <span class="stat-value text-purple">8</span>
          <span class="text-xs text-muted">92% utilization</span>
        </div>

        <div class="stat-box">
          <span class="stat-label">Gym Active Clients</span>
          <span class="stat-value text-primary">64</span>
          <span class="text-xs text-muted">14 completed today</span>
        </div>
      </div>

      <!-- Head Trainer Client Reassignment Console -->
      <div class="card card-glow" style="background: rgba(139, 92, 246, 0.08); border-color: rgba(139, 92, 246, 0.3);">
        <div class="flex justify-between items-center" style="margin-bottom: 0.5rem;">
          <div class="font-bold text-sm text-purple">👑 Head Trainer Client Reassignment</div>
          <span class="badge badge-purple">Gym Level Access</span>
        </div>
        <p class="text-xs text-muted" style="margin-bottom: 0.75rem;">
          Reassign clients between staff trainers while preserving complete historical workout logs and credit balances.
        </p>

        <div class="flex flex-col gap-2">
          <div class="card" style="padding: 0.75rem; background: var(--bg-surface);">
            <div class="flex justify-between items-center">
              <div>
                <div class="font-bold text-sm">Sarah Jenkins</div>
                <div class="text-xs text-muted">Current: Alex Rivera (9 Sessions Left)</div>
              </div>
              <button class="btn btn-secondary btn-sm" onclick="alert('Client Reassignment Simulator: Transfer client to another gym trainer. Historical logs preserved.')">
                Transfer Client ➔
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Facility Schedule Overview -->
      <div class="card">
        <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin-bottom: 0.5rem;">
          Facility Booking Capacity (Gym Floor)
        </div>
        <div class="flex flex-col gap-2 text-xs">
          <div class="flex justify-between items-center" style="padding: 0.35rem 0; border-bottom: 1px solid var(--border-color);">
            <span>09:00 - 10:00 AM</span>
            <span class="badge badge-primary">4 / 6 Slots Booked</span>
          </div>
          <div class="flex justify-between items-center" style="padding: 0.35rem 0; border-bottom: 1px solid var(--border-color);">
            <span>10:00 - 11:00 AM</span>
            <span class="badge badge-amber">6 / 6 Slots (Full)</span>
          </div>
          <div class="flex justify-between items-center" style="padding: 0.35rem 0;">
            <span>17:00 - 18:00 PM</span>
            <span class="badge badge-primary">3 / 6 Slots Booked</span>
          </div>
        </div>
      </div>
    </div>
  `;
}
