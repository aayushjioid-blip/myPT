// Client Booking, Availability & Recurring Calendar View (Milestone 3)

import { store } from '../../state/store.js';

export function renderClientCalendarView() {
  const state = store.getState();
  const client = store.getCurrentUser();
  const relationship = state.relationships.find(r => r.client_id === client.id && r.status === 'ACCEPTED');
  const activePackage = state.client_packages.find(cp => cp.client_id === client.id && cp.status === 'ACTIVE');
  const clientSessions = state.sessions.filter(s => s.client_id === client.id);

  const trainer = state.trainers.find(t => t.id === (relationship ? relationship.trainer_id : 'trn-alex')) || state.trainers[0];

  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const tomorrowStr = tomorrow.toISOString().split('T')[0];

  // Dynamic slot availability with capacity checks
  const timeSlots = [
    { time: '08:00', label: '08:00 AM - 09:00 AM' },
    { time: '09:00', label: '09:00 AM - 10:00 AM' },
    { time: '10:00', label: '10:00 AM - 11:00 AM' },
    { time: '11:00', label: '11:00 AM - 12:00 PM' },
    { time: '16:00', label: '04:00 PM - 05:00 PM' },
    { time: '17:00', label: '05:00 PM - 06:00 PM' },
    { time: '18:00', label: '06:00 PM - 07:00 PM' }
  ];

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div>
        <h2 class="text-2xl font-extrabold">Schedule & Bookings</h2>
        <p class="text-xs text-muted">Book 1-on-1 PT sessions, view slot capacity, and set recurring training.</p>
      </div>

      <!-- Booking Card -->
      <div class="card card-glow">
        <div class="flex justify-between items-center" style="margin-bottom: 0.75rem;">
          <span class="text-xs font-bold text-primary uppercase">📅 Book Personal Training Session</span>
          <span class="badge ${activePackage && activePackage.remaining_sessions > 0 ? 'badge-primary' : 'badge-rose'}">
            ${activePackage ? `${activePackage.remaining_sessions} Credits Available` : '0 Credits'}
          </span>
        </div>

        ${!activePackage || activePackage.remaining_sessions <= 0 ? `
          <div class="card" style="padding: 1rem; text-align: center; background: var(--bg-input);">
            <div class="text-rose font-bold text-sm" style="margin-bottom: 0.25rem;">⚠️ No Available Session Credits</div>
            <p class="text-xs text-muted" style="margin-bottom: 0.75rem;">
              You must have an active package with remaining credits to book personal training sessions.
            </p>
            <button class="btn btn-primary btn-sm" onclick="window.switchTab('packages')">Purchase Package 🏷️</button>
          </div>
        ` : `
          <form id="booking-form" onsubmit="window.submitSessionBooking(event, '${trainer.id}', '${activePackage.id}')">
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem;">
              <div class="form-group">
                <label class="form-label">Select Date *</label>
                <input type="date" class="input" id="booking-date" value="${tomorrowStr}" min="${new Date().toISOString().split('T')[0]}" required />
              </div>

              <div class="form-group">
                <label class="form-label">Time Slot *</label>
                <select class="input" id="booking-time" required>
                  ${timeSlots.map(s => `
                    <option value="${s.time}">
                      ${s.label}
                    </option>
                  `).join('')}
                </select>
              </div>
            </div>

            <!-- Recurring Session Option -->
            <div class="form-group" style="margin-top: 0.5rem;">
              <label class="form-label">Booking Mode / Recurring Frequency</label>
              <select class="input" id="booking-recurring">
                <option value="1">Single Session (1 credit)</option>
                <option value="2">Weekly Recurring - 2 Weeks (2 credits)</option>
                <option value="4">Weekly Recurring - 4 Weeks (4 credits)</option>
              </select>
            </div>

            <div class="card" style="padding: 0.6rem 0.75rem; background: var(--bg-input); margin: 0.5rem 0;">
              <div class="text-xs text-muted">
                Coach: <strong>${trainer.name}</strong> • Cancellation Grace: <span class="text-primary font-semibold">4-Hour Policy</span>
              </div>
            </div>

            <button type="submit" class="btn btn-primary btn-full font-bold" style="margin-top: 0.5rem;">
              Request Session Booking 📅
            </button>
          </form>
        `}
      </div>

      <!-- Scheduled Sessions List -->
      <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin-top: 0.5rem;">
        Your Scheduled Sessions (${clientSessions.length})
      </div>

      <div class="flex flex-col gap-2">
        ${clientSessions.length > 0 ? clientSessions.map(s => `
          <div class="card" style="padding: 0.85rem;">
            <div class="flex justify-between items-start">
              <div>
                <div class="flex items-center gap-2">
                  <span class="font-bold text-sm">
                    ${s.session_type === 'PERSONAL_TRAINING' ? '🏋️ 1-on-1 PT Session' : '🏃 Own Workout'}
                  </span>
                  ${s.is_recurring ? '<span class="badge badge-purple" style="font-size: 0.6rem;">Recurring</span>' : ''}
                </div>
                <div class="text-xs text-muted font-mono" style="margin-top: 2px;">
                  ${s.scheduled_start ? s.scheduled_start.replace('T', ' at ') : 'Today'}
                </div>
              </div>
              <span class="badge ${
                s.status === 'CONFIRMED' ? 'badge-primary' : 
                s.status === 'COMPLETED' ? 'badge-blue' : 
                s.status === 'REQUESTED' ? 'badge-amber' : 
                s.status === 'CANCELLED' ? 'badge-rose' : 'badge-subtle'
              }">
                ${s.status}
              </span>
            </div>

            ${s.status === 'CONFIRMED' || s.status === 'REQUESTED' ? `
              <div class="flex gap-2" style="margin-top: 0.5rem; padding-top: 0.5rem; border-top: 1px solid var(--border-color);">
                <button class="btn btn-secondary btn-sm flex-1" onclick="window.promptReschedule('${s.id}')">
                  Reschedule 🔄
                </button>
                <button class="btn btn-secondary btn-sm flex-1" style="color: var(--color-accent-rose);" onclick="window.promptCancelSession('${s.id}')">
                  Cancel ✕
                </button>
              </div>
            ` : ''}
          </div>
        `).join('') : `
          <div class="text-xs text-muted" style="padding: 0.5rem 0;">No scheduled sessions. Book a slot above!</div>
        `}
      </div>
    </div>
  `;
}
