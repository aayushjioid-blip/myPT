// Client Dashboard Home View

import { store } from '../../state/store.js';

export function renderClientHomeView() {
  const state = store.getState();
  const client = store.getCurrentUser();

  // Find active package
  const activePackage = state.client_packages.find(cp => cp.client_id === client.id && cp.status === 'ACTIVE');
  const remainingCredits = activePackage ? activePackage.remaining_sessions : 0;
  const totalCredits = activePackage ? activePackage.total_sessions : 10;
  const creditRatio = totalCredits > 0 ? (remainingCredits / totalCredits) : 0;
  const circumference = 2 * Math.PI * 45; // r=45
  const strokeOffset = circumference - (circumference * creditRatio);

  // Find active relationship & trainer
  const relationship = state.relationships.find(r => r.client_id === client.id && r.status === 'ACCEPTED');
  const trainer = relationship ? state.trainers.find(t => t.id === relationship.trainer_id) : null;

  // Next scheduled session
  const nextSession = state.sessions.find(s => s.client_id === client.id && (s.status === 'CONFIRMED' || s.status === 'REQUESTED'));

  // Today's Assigned or Recent Workout
  const latestWorkout = state.workouts.find(w => w.client_id === client.id);

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <!-- Greeting & Status -->
      <div class="flex justify-between items-center">
        <div>
          <div class="text-xs text-muted font-semibold uppercase tracking-wider">Welcome Back</div>
          <h2 class="text-2xl font-extrabold">${client.name.split(' ')[0]} 👋</h2>
        </div>
        <div class="badge ${activePackage ? 'badge-primary' : 'badge-amber'}">
          ${activePackage ? 'Active Member' : 'No Active Package'}
        </div>
      </div>

      <!-- Hero Package & Credits Gauge Card -->
      <div class="hero-card">
        <div class="flex flex-col gap-1 z-10">
          <div class="text-xs text-primary font-bold uppercase tracking-wider">PT Session Balance</div>
          <div class="text-3xl font-extrabold">${remainingCredits} <span class="text-sm text-muted font-normal">/ ${totalCredits} Sessions</span></div>
          <div class="text-xs text-muted" style="margin-top: 0.25rem;">
            ${activePackage ? `Expires: ${activePackage.expiry_date ? activePackage.expiry_date.split('T')[0] : 'In 40 Days'}` : 'Select a package to start'}
          </div>
          <div style="margin-top: 0.75rem;">
            ${activePackage ? `
              <button class="btn btn-primary btn-sm" onclick="window.switchTab('calendar')">Book Next Session 📅</button>
            ` : `
              <button class="btn btn-primary btn-sm" onclick="window.switchTab('packages')">Get PT Package 🏷️</button>
            `}
          </div>
        </div>

        <!-- Circular Credit SVG Gauge -->
        <div class="credit-gauge">
          <svg class="credit-gauge-svg" viewBox="0 0 100 100">
            <circle class="credit-gauge-bg" cx="50" cy="50" r="45" />
            <circle 
              class="credit-gauge-val" 
              cx="50" 
              cy="50" 
              r="45" 
              style="stroke-dasharray: ${circumference}; stroke-dashoffset: ${strokeOffset};" />
          </svg>
          <div class="credit-gauge-center">
            <span style="font-size: 1.4rem; font-weight: 800;">${remainingCredits}</span>
            <span style="font-size: 0.65rem; color: var(--text-muted); text-transform: uppercase;">Left</span>
          </div>
        </div>
      </div>

      <!-- Next Scheduled Session Card -->
      <div class="card">
        <div class="flex justify-between items-center" style="margin-bottom: 0.75rem;">
          <div class="text-xs font-bold text-muted uppercase tracking-wider">Next Session</div>
          ${nextSession ? `<span class="badge ${nextSession.status === 'CONFIRMED' ? 'badge-primary' : 'badge-amber'}">${nextSession.status}</span>` : ''}
        </div>

        ${nextSession ? `
          <div class="flex items-center gap-3">
            <div style="width: 44px; height: 44px; background: rgba(59, 130, 246, 0.15); border-radius: 12px; display:flex; align-items:center; justify-content:center; font-size:1.3rem;">
              📅
            </div>
            <div class="flex-1">
              <div class="font-bold text-sm">Personal Training 1-on-1</div>
              <div class="text-xs text-muted font-mono">${nextSession.scheduled_start.replace('T', ' at ')}</div>
            </div>
            <button class="btn btn-secondary btn-sm" onclick="window.switchTab('calendar')">Details</button>
          </div>
        ` : `
          <div class="flex justify-between items-center">
            <div class="text-sm text-muted">No upcoming sessions booked.</div>
            <button class="btn btn-secondary btn-sm" onclick="window.switchTab('calendar')">Book Slot</button>
          </div>
        `}
      </div>

      <!-- Active Trainer Card -->
      <div class="card">
        <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin-bottom: 0.75rem;">
          Assigned Trainer
        </div>
        ${trainer ? `
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="trainer-avatar">${trainer.name.charAt(0)}</div>
              <div>
                <div class="font-bold text-sm">${trainer.name}</div>
                <div class="text-xs text-muted">⭐ ${trainer.rating} • ${trainer.experience_years} yrs exp</div>
              </div>
            </div>
            <button class="btn btn-ghost btn-sm" onclick="window.switchTab('discover')">Profile</button>
          </div>
        ` : `
          <div class="flex justify-between items-center">
            <div class="text-sm text-muted">No personal trainer connected yet.</div>
            <button class="btn btn-primary btn-sm" onclick="window.switchTab('discover')">Find Trainer 🔍</button>
          </div>
        `}
      </div>

      <!-- Today's Workout Quick Action -->
      <div class="card card-clickable" onclick="window.switchTab('workout')">
        <div class="flex justify-between items-center">
          <div class="flex items-center gap-3">
            <div style="width: 44px; height: 44px; background: rgba(16, 185, 129, 0.15); border-radius: 12px; display:flex; align-items:center; justify-content:center; font-size:1.3rem;">
              💪
            </div>
            <div>
              <div class="font-bold text-sm">${latestWorkout ? latestWorkout.name : 'Upper Body Hypertrophy'}</div>
              <div class="text-xs text-muted">${latestWorkout ? latestWorkout.workout_type : 'Ready to start'} • 4 Exercises</div>
            </div>
          </div>
          <span style="font-size: 1.1rem; color: var(--color-primary);">➔</span>
        </div>
      </div>
    </div>
  `;
}
