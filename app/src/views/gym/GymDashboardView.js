// Gym Manager & Head Trainer Console View (Milestones 4 & 5)

import { store } from '../../state/store.js';

export function renderGymDashboardView() {
  const state = store.getState();
  const user = store.getCurrentUser();
  const gym = state.gyms[0];
  const staffTrainers = state.trainers;
  const relationships = state.relationships;
  const isHeadTrainer = user.role === 'HEAD_TRAINER';

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div class="flex justify-between items-center">
        <div>
          <div class="text-xs text-muted font-semibold uppercase">Gym Facility & Operations</div>
          <h2 class="text-2xl font-extrabold">${gym ? gym.name : 'IronCore Fitness'} 🏢</h2>
        </div>
        <span class="badge ${isHeadTrainer ? 'badge-purple' : 'badge-primary'}">
          ${user.role}
        </span>
      </div>

      <!-- Facility KPIs (Milestone 8 Metrics Integration) -->
      <div class="stat-grid">
        <div class="stat-box">
          <span class="stat-label">Staff Trainers</span>
          <span class="stat-value text-purple">${staffTrainers.length}</span>
          <span class="text-xs text-muted">94% active roster</span>
        </div>

        <div class="stat-box">
          <span class="stat-label">Gym Active Clients</span>
          <span class="stat-value text-primary">${state.users.filter(u => u.role === 'CLIENT').length * 12}</span>
          <span class="text-xs text-muted">Floor Occupancy: 28/40</span>
        </div>
      </div>

      <!-- Head Trainer Client Reassignment Console (MILESTONE 4) -->
      <div class="card card-glow" style="background: rgba(139, 92, 246, 0.08); border-color: rgba(139, 92, 246, 0.3);">
        <div class="flex justify-between items-center" style="margin-bottom: 0.5rem;">
          <div class="font-bold text-sm text-purple">👑 Head Trainer Client Reassignment</div>
          <span class="badge badge-purple">Gym Level Authority</span>
        </div>
        <p class="text-xs text-muted" style="margin-bottom: 0.75rem;">
          Reassign clients between staff trainers due to leave or specialization. All workout logs and remaining credits are seamlessly preserved.
        </p>

        <div class="flex flex-col gap-2">
          ${relationships.filter(r => r.status === 'ACCEPTED').length > 0 ? 
            relationships.filter(r => r.status === 'ACCEPTED').map(rel => {
              const client = state.users.find(u => u.id === rel.client_id) || { name: 'Sarah Jenkins' };
              const trainer = state.trainers.find(t => t.id === rel.trainer_id) || state.trainers[0];
              const clientPkg = state.client_packages.find(cp => cp.client_id === rel.client_id && cp.status === 'ACTIVE');

              return `
                <div class="card" style="padding: 0.75rem; background: var(--bg-surface);">
                  <div class="flex justify-between items-center">
                    <div>
                      <div class="font-bold text-sm">${client.name}</div>
                      <div class="text-xs text-muted">Assigned: <strong class="text-primary">${trainer.name}</strong> • ${clientPkg ? `${clientPkg.remaining_sessions} credits` : 'Active'}</div>
                    </div>
                    <button class="btn btn-secondary btn-sm font-bold" onclick="window.openClientReassignmentModal('${rel.id}')">
                      Reassign Trainer ➔
                    </button>
                  </div>
                </div>
              `;
            }).join('') : `
              <div class="card" style="padding: 0.75rem; background: var(--bg-surface);">
                <div class="flex justify-between items-center">
                  <div>
                    <div class="font-bold text-sm">Sarah Jenkins</div>
                    <div class="text-xs text-muted">Assigned: Alex Rivera • 9 Session Credits</div>
                  </div>
                  <button class="btn btn-secondary btn-sm font-bold" onclick="window.openClientReassignmentModal('')">
                    Reassign Trainer ➔
                  </button>
                </div>
              </div>
            `
          }
        </div>
      </div>

      <!-- Staff Trainers Roster (MILESTONE 5) -->
      <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin-top: 0.25rem;">
        Staff Trainers Roster (${staffTrainers.length})
      </div>

      <div class="flex flex-col gap-2">
        ${staffTrainers.map(t => `
          <div class="card" style="padding: 0.85rem;">
            <div class="flex justify-between items-start">
              <div>
                <div class="flex items-center gap-2">
                  <span class="font-bold text-sm">${t.name}</span>
                  <span class="badge ${t.verification_status === 'VERIFIED' ? 'badge-primary' : 'badge-amber'}" style="font-size: 0.65rem;">
                    ${t.verification_status}
                  </span>
                </div>
                <div class="text-xs text-muted" style="margin-top: 2px;">
                  Code: <strong class="font-mono text-primary">${t.trainer_code}</strong> • ${t.specializations.join(', ')}
                </div>
              </div>
              <div class="text-right">
                <span class="font-bold text-amber text-xs">⭐ ${t.rating}</span>
                <div class="text-xs text-muted">(${t.review_count} reviews)</div>
              </div>
            </div>
          </div>
        `).join('')}
      </div>

      <!-- Gym Facility Info & Capacity (MILESTONE 5) -->
      <div class="card">
        <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin-bottom: 0.5rem;">
          Facility Specs & Amenities
        </div>
        <div class="text-xs text-muted" style="line-height: 1.4;">
          <div><strong>Address:</strong> ${gym ? gym.address : '742 Evergreen Blvd'}</div>
          <div><strong>Hours:</strong> ${gym ? gym.operating_hours : '06:00 - 22:00 Daily'}</div>
          <div><strong>Amenities:</strong> ${gym?.amenities?.join(', ') || 'Olympic Platforms, Sauna'}</div>
        </div>
      </div>
    </div>
  `;
}
