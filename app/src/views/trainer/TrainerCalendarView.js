// Trainer Calendar, Working Hours & Capacity Management View (Milestone 3)

import { store } from '../../state/store.js';

export function renderTrainerCalendarView() {
  const state = store.getState();
  const trainer = store.getCurrentTrainerProfile() || state.trainers[0];
  const trainerSessions = state.sessions.filter(s => s.trainer_id === trainer.id);

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div class="flex justify-between items-center">
        <div>
          <h2 class="text-2xl font-extrabold">Trainer Schedule</h2>
          <p class="text-xs text-muted">Manage working hours, slot capacity, and bookings.</p>
        </div>
        <span class="badge badge-primary">4-Hr Policy</span>
      </div>

      <!-- Working Hours & Capacity Configuration Console -->
      <div class="card card-glow">
        <div class="flex justify-between items-center" style="margin-bottom: 0.5rem;">
          <div class="text-xs font-bold text-primary uppercase">⏱️ Working Hours & Capacity</div>
          <span class="badge badge-subtle">Mon - Sat</span>
        </div>

        <div class="flex flex-col gap-2 text-xs">
          <div class="flex justify-between items-center" style="padding: 0.35rem 0; border-bottom: 1px solid var(--border-color);">
            <span>Monday - Friday Shifts:</span>
            <span class="font-bold font-mono text-primary">08:00 AM - 07:00 PM</span>
          </div>
          <div class="flex justify-between items-center" style="padding: 0.35rem 0; border-bottom: 1px solid var(--border-color);">
            <span>Saturday Morning Shift:</span>
            <span class="font-bold font-mono text-primary">09:00 AM - 02:00 PM</span>
          </div>
          <div class="flex justify-between items-center" style="padding: 0.35rem 0;">
            <span>Configured Slot Capacity:</span>
            <span class="badge badge-purple font-bold">2 Clients / Slot</span>
          </div>
        </div>
      </div>

      <!-- Scheduled & Inbound Sessions List -->
      <div class="text-xs font-bold text-muted uppercase tracking-wider">
        Booked & Pending Sessions (${trainerSessions.length})
      </div>

      <div class="flex flex-col gap-2">
        ${trainerSessions.length > 0 ? trainerSessions.map(s => {
          const clientObj = state.users.find(u => u.id === s.client_id) || { name: 'Sarah Jenkins' };

          return `
            <div class="card">
              <div class="flex justify-between items-start" style="margin-bottom: 0.5rem;">
                <div>
                  <div class="flex items-center gap-2">
                    <span class="font-bold text-base">${clientObj.name}</span>
                    ${s.is_recurring ? '<span class="badge badge-purple" style="font-size: 0.6rem;">Recurring</span>' : ''}
                  </div>
                  <div class="text-xs text-muted font-mono" style="margin-top: 2px;">
                    ${s.scheduled_start.replace('T', ' at ')}
                  </div>
                </div>
                <span class="badge ${
                  s.status === 'CONFIRMED' ? 'badge-primary' : 
                  s.status === 'COMPLETED' ? 'badge-blue' : 
                  s.status === 'CANCELLED' ? 'badge-rose' : 'badge-amber'
                }">
                  ${s.status}
                </span>
              </div>

              <div class="flex gap-2" style="margin-top: 0.5rem; padding-top: 0.5rem; border-top: 1px solid var(--border-color);">
                ${s.status === 'REQUESTED' ? `
                  <button class="btn btn-primary btn-sm flex-1 font-bold" onclick="window.acceptBooking('${s.id}')">
                    Accept Booking ✓
                  </button>
                  <button class="btn btn-secondary btn-sm flex-1" style="color: var(--color-accent-rose);" onclick="window.promptRejectBooking('${s.id}')">
                    Decline ✕
                  </button>
                ` : s.status === 'CONFIRMED' ? `
                  <button class="btn btn-primary btn-sm flex-1 font-bold" onclick="window.openWorkoutLoggerModal('${s.id}')">
                    Start Session ⏱️
                  </button>
                  <button class="btn btn-secondary btn-sm flex-1" onclick="window.promptReschedule('${s.id}')">
                    Reschedule 🔄
                  </button>
                ` : s.status === 'COMPLETED' ? `
                  <span class="text-xs text-primary font-bold">✓ Session Completed (Credit Deducted)</span>
                ` : `
                  <span class="text-xs text-rose font-bold">Cancelled</span>
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
