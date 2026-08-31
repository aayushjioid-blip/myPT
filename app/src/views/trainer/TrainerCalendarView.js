// Trainer Calendar & Session Approval View

import { store } from '../../state/store.js';

export function renderTrainerCalendarView() {
  const state = store.getState();
  const trainer = store.getCurrentTrainerProfile() || state.trainers[0];
  const trainerSessions = state.sessions.filter(s => s.trainer_id === trainer.id);

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div class="flex justify-between items-center">
        <div>
          <h2 class="text-2xl font-extrabold">Trainer Calendar</h2>
          <p class="text-xs text-muted">Weekly timetable, slot capacity, and session approvals.</p>
        </div>
        <span class="badge badge-primary">4-Hr Policy</span>
      </div>

      <!-- Working Hours & Capacity Summary -->
      <div class="card" style="padding: 0.85rem; background: var(--bg-input);">
        <div class="flex justify-between items-center text-xs">
          <span>Working Schedule: <strong>Mon - Fri (09:00 - 19:00)</strong></span>
          <span class="text-primary font-bold">Max Capacity: 2 / slot</span>
        </div>
      </div>

      <!-- Scheduled Sessions List -->
      <div class="text-xs font-bold text-muted uppercase tracking-wider">
        Booked & Pending Sessions (${trainerSessions.length})
      </div>

      <div class="flex flex-col gap-2">
        ${trainerSessions.length > 0 ? trainerSessions.map(s => {
          const clientObj = state.users.find(u => u.id === s.client_id) || { name: 'Client' };

          return `
            <div class="card">
              <div class="flex justify-between items-start" style="margin-bottom: 0.5rem;">
                <div>
                  <div class="font-bold text-base">${clientObj.name}</div>
                  <div class="text-xs text-muted font-mono">${s.scheduled_start.replace('T', ' at ')}</div>
                </div>
                <span class="badge ${
                  s.status === 'CONFIRMED' ? 'badge-primary' : 
                  s.status === 'COMPLETED' ? 'badge-blue' : 'badge-amber'
                }">
                  ${s.status}
                </span>
              </div>

              <div class="flex gap-2" style="margin-top: 0.5rem; padding-top: 0.5rem; border-top: 1px solid var(--border-color);">
                ${s.status === 'REQUESTED' ? `
                  <button class="btn btn-primary btn-sm flex-1 font-bold" onclick="window.acceptBooking('${s.id}')">
                    Accept Booking ✓
                  </button>
                ` : s.status === 'CONFIRMED' ? `
                  <button class="btn btn-primary btn-sm flex-1 font-bold" onclick="window.openWorkoutLoggerModal('${s.id}')">
                    Start Session ⏱️
                  </button>
                ` : `
                  <span class="text-xs text-primary font-bold">✓ Session Completed (Credit Deducted)</span>
                `}
              </div>
            </div>
          `;
        }).join('') : `
          <div class="card" style="text-align: center; padding: 1.5rem;">
            <div class="text-xs text-muted">No sessions booked yet on your calendar.</div>
          </div>
        `}
      </div>
    </div>
  `;
}
