// Client Booking & Calendar View

import { store } from '../../state/store.js';

export function renderClientCalendarView() {
  const state = store.getState();
  const client = store.getCurrentUser();
  const relationship = state.relationships.find(r => r.client_id === client.id && r.status === 'ACCEPTED');
  const activePackage = state.client_packages.find(cp => cp.client_id === client.id && cp.status === 'ACTIVE');
  const clientSessions = state.sessions.filter(s => s.client_id === client.id);

  // Available Time Slots
  const slots = [
    { time: '09:00', label: '09:00 AM - 10:00 AM', available: true },
    { time: '10:00', label: '10:00 AM - 11:00 AM', available: true },
    { time: '11:00', label: '11:00 AM - 12:00 PM', available: false },
    { time: '16:00', label: '04:00 PM - 05:00 PM', available: true },
    { time: '17:00', label: '05:00 PM - 06:00 PM', available: true },
    { time: '18:00', label: '06:00 PM - 07:00 PM', available: true }
  ];

  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const tomorrowStr = tomorrow.toISOString().split('T')[0];

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div>
        <h2 class="text-2xl font-extrabold">Schedule & Bookings</h2>
        <p class="text-xs text-muted">Book 1-on-1 PT sessions with your personal trainer.</p>
      </div>

      <!-- Booking Card -->
      <div class="card card-glow">
        <div class="flex justify-between items-center" style="margin-bottom: 0.75rem;">
          <span class="text-xs font-bold text-primary uppercase">Book New Session</span>
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
          <form id="booking-form" onsubmit="window.submitSessionBooking(event, '${relationship ? relationship.trainer_id : 'trn-alex'}', '${activePackage.id}')">
            <div class="form-group">
              <label class="form-label">Select Date</label>
              <input type="date" class="input" id="booking-date" value="${tomorrowStr}" min="${new Date().toISOString().split('T')[0]}" required />
            </div>

            <div class="form-group">
              <label class="form-label">Available Time Slots</label>
              <select class="input" id="booking-time" required>
                ${slots.map(s => `
                  <option value="${s.time}" ${!s.available ? 'disabled' : ''}>
                    ${s.label} ${!s.available ? '(Fully Booked)' : ''}
                  </option>
                `).join('')}
              </select>
            </div>

            <button type="submit" class="btn btn-primary btn-full font-bold" style="margin-top: 0.5rem;">
              Request Session Booking 📅
            </button>
          </form>
        `}
      </div>

      <!-- Scheduled Sessions List -->
      <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin-top: 0.5rem;">
        Your Sessions (${clientSessions.length})
      </div>

      <div class="flex flex-col gap-2">
        ${clientSessions.length > 0 ? clientSessions.map(s => `
          <div class="card" style="padding: 0.85rem;">
            <div class="flex justify-between items-center">
              <div>
                <div class="font-bold text-sm">
                  ${s.session_type === 'PERSONAL_TRAINING' ? '🏋️ 1-on-1 PT Session' : '🏃 Own Workout'}
                </div>
                <div class="text-xs text-muted font-mono">${s.scheduled_start.replace('T', ' at ')}</div>
              </div>
              <span class="badge ${
                s.status === 'CONFIRMED' ? 'badge-primary' : 
                s.status === 'COMPLETED' ? 'badge-blue' : 
                s.status === 'REQUESTED' ? 'badge-amber' : 'badge-subtle'
              }">
                ${s.status}
              </span>
            </div>
          </div>
        `).join('') : `
          <div class="text-xs text-muted">No scheduled sessions. Book a slot above!</div>
        `}
      </div>
    </div>
  `;
}
