// Trainer Clients Roster & 360 View

import { store } from '../../state/store.js';

export function renderTrainerClientsView() {
  const state = store.getState();
  const trainer = store.getCurrentTrainerProfile() || state.trainers[0];
  const relationships = state.relationships.filter(r => r.trainer_id === trainer.id && r.status === 'ACCEPTED');

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div>
        <h2 class="text-2xl font-extrabold">Client Roster</h2>
        <p class="text-xs text-muted">Manage assigned clients, workout programming, and progress logs.</p>
      </div>

      <!-- Clients List -->
      <div class="flex flex-col gap-3">
        ${relationships.length > 0 ? relationships.map(rel => {
          const client = state.users.find(u => u.id === rel.client_id) || { name: 'Sarah Jenkins', email: 'client@test.local' };
          const clientPkg = state.client_packages.find(cp => cp.client_id === client.id && cp.status === 'ACTIVE');
          const isShared = client.share_personal_info_with_trainer;

          return `
            <div class="card card-glow">
              <div class="flex justify-between items-start" style="margin-bottom: 0.75rem;">
                <div class="flex items-center gap-3">
                  <div class="trainer-avatar">${client.name.charAt(0)}</div>
                  <div>
                    <div class="font-bold text-base">${client.name}</div>
                    <div class="text-xs text-muted">${client.email}</div>
                  </div>
                </div>
                <div class="badge ${clientPkg ? 'badge-primary' : 'badge-amber'}">
                  ${clientPkg ? `${clientPkg.remaining_sessions} Sessions Left` : 'No Active Package'}
                </div>
              </div>

              <!-- Medical / Health Privacy Protection Check (RULE 2) -->
              <div class="card" style="padding: 0.75rem; background: var(--bg-input); margin-bottom: 0.75rem;">
                <div class="flex justify-between items-center" style="margin-bottom: 0.35rem;">
                  <span class="text-xs font-bold text-muted uppercase">Health & Intake Information</span>
                  <span class="badge ${isShared ? 'badge-primary' : 'badge-subtle'}" style="font-size: 0.65rem;">
                    ${isShared ? '✓ Shared by Client' : '🔒 Private (Not Shared)'}
                  </span>
                </div>

                ${isShared ? `
                  <div class="text-xs" style="line-height: 1.4;">
                    <div><strong>Injuries:</strong> ${client.injuries || 'None'}</div>
                    <div><strong>Medical:</strong> ${client.medical_info || 'None'}</div>
                    <div><strong>Emergency Contact:</strong> ${client.emergency_contact || 'None'}</div>
                  </div>
                ` : `
                  <div class="text-xs text-subtle italic">
                    Client has not toggled "Share with my trainer". Health information is shielded.
                  </div>
                `}
              </div>

              <div class="flex gap-2">
                <button class="btn btn-secondary btn-sm flex-1" onclick="window.assignWorkoutToClient('${client.id}')">
                  Assign Routine 📝
                </button>
                <button class="btn btn-primary btn-sm flex-1" onclick="window.switchTab('calendar')">
                  Schedule Session 📅
                </button>
              </div>
            </div>
          `;
        }).join('') : `
          <div class="card" style="padding: 2rem 1rem; text-align: center;">
            <div style="font-size: 1.8rem; margin-bottom: 0.4rem;">👥</div>
            <div class="font-bold text-sm">No Active Clients</div>
            <p class="text-xs text-muted" style="margin: 0.25rem 0 1rem 0;">
              Pending consultation requests will appear in your Requests tab.
            </p>
            <button class="btn btn-primary btn-sm" onclick="window.switchTab('requests')">View Inbound Requests</button>
          </div>
        `}
      </div>
    </div>
  `;
}
