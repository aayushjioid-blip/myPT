// Client Workout Tracker & "Own Workout" Logger View

import { store } from '../../state/store.js';

export function renderClientWorkoutView() {
  const state = store.getState();
  const client = store.getCurrentUser();
  const clientWorkouts = state.workouts.filter(w => w.client_id === client.id);

  // Active or Assigned Workout
  const pendingWorkout = clientWorkouts.find(w => w.status === 'PENDING');
  const completedWorkouts = clientWorkouts.filter(w => w.status === 'COMPLETED');

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div class="flex justify-between items-center">
        <div>
          <h2 class="text-2xl font-extrabold">Workout Studio</h2>
          <p class="text-xs text-muted">Execute assigned routines or log your own workouts.</p>
        </div>
        <button class="btn btn-secondary btn-sm" onclick="window.promptLogOwnWorkout()">
          + Own Workout
        </button>
      </div>

      <!-- Own Workout Zero-Credit Guarantee Banner -->
      <div class="card" style="background: rgba(59, 130, 246, 0.08); border-color: rgba(59, 130, 246, 0.3); padding: 0.85rem;">
        <div class="flex items-center gap-2">
          <span style="font-size: 1.2rem;">🛡️</span>
          <div class="text-xs text-muted">
            <strong class="text-blue">Zero Credit Guarantee</strong>: "Own Workouts" logged by you never consume personal training credits!
          </div>
        </div>
      </div>

      <!-- Pending / Assigned Workout -->
      <div class="text-xs font-bold text-muted uppercase tracking-wider">
        Assigned for Today
      </div>

      ${pendingWorkout ? `
        <div class="card card-glow">
          <div class="flex justify-between items-start" style="margin-bottom: 0.5rem;">
            <div>
              <span class="badge badge-primary" style="margin-bottom: 0.25rem;">Trainer Assigned</span>
              <div class="font-bold text-base">${pendingWorkout.name}</div>
              <div class="text-xs text-muted">${pendingWorkout.description}</div>
            </div>
          </div>

          <div class="flex flex-col gap-2" style="margin: 0.75rem 0;">
            ${pendingWorkout.exercises.map((ex, idx) => `
              <div class="flex justify-between items-center text-xs" style="padding: 0.4rem 0; border-bottom: 1px solid var(--border-color);">
                <span class="font-semibold">${idx + 1}. ${ex.name}</span>
                <span class="text-muted font-mono">${ex.sets} sets × ${ex.repetitions} reps @ ${ex.weight_kg}kg</span>
              </div>
            `).join('')}
          </div>

          <button 
            class="btn btn-primary btn-full font-bold" 
            onclick="window.openWorkoutLoggerModal('', '${pendingWorkout.id}')">
            Start Workout Session 🔥
          </button>
        </div>
      ` : `
        <div class="card" style="padding: 1.5rem; text-align: center;">
          <div style="font-size: 1.8rem; margin-bottom: 0.4rem;">🎯</div>
          <div class="font-bold text-sm">No Assigned Workouts Pending</div>
          <p class="text-xs text-muted" style="margin: 0.35rem 0 1rem 0;">
            You are all caught up! Feel free to log an independent workout.
          </p>
          <button class="btn btn-secondary btn-sm" onclick="window.promptLogOwnWorkout()">
            Log "Own Workout" (0 Credits) 🏃
          </button>
        </div>
      `}

      <!-- Workout History -->
      <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin-top: 0.5rem;">
        Workout History (${completedWorkouts.length})
      </div>

      <div class="flex flex-col gap-2">
        ${completedWorkouts.length > 0 ? completedWorkouts.map(w => `
          <div class="card" style="padding: 0.85rem;">
            <div class="flex justify-between items-center">
              <div>
                <div class="flex items-center gap-2">
                  <span class="font-bold text-sm">${w.name}</span>
                  <span class="badge ${w.workout_type === 'OWN_WORKOUT' ? 'badge-blue' : 'badge-primary'}" style="font-size: 0.65rem;">
                    ${w.workout_type === 'OWN_WORKOUT' ? 'Own Workout (0 PT)' : 'PT Session'}
                  </span>
                </div>
                <div class="text-xs text-muted font-mono">${w.completed_at ? w.completed_at.split('T')[0] : 'Today'} • ${w.exercises ? w.exercises.length : 3} exercises logged</div>
              </div>
              <span class="text-primary font-bold text-sm">✓ Done</span>
            </div>
          </div>
        `).join('') : `
          <div class="text-xs text-muted" style="padding: 0.5rem 0;">No completed workouts yet. Complete a workout to start your history log!</div>
        `}
      </div>
    </div>
  `;
}
