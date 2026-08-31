// Live Workout & Session Logger Modal

import { store } from '../state/store.js';

export function renderWorkoutLoggerModal(data = {}) {
  const state = store.getState();
  const session = state.sessions.find(s => s.id === data.sessionId) || state.sessions[0];
  const workout = state.workouts.find(w => w.id === data.workoutId) || state.workouts[0];

  const exercises = (workout && workout.exercises) ? workout.exercises : [
    { id: 'wo-ex-0', name: 'Barbell Bench Press', sets: 3, repetitions: 10, weight_kg: 60, is_completed: true },
    { id: 'wo-ex-1', name: 'Lat Pulldown', sets: 3, repetitions: 12, weight_kg: 50, is_completed: true },
    { id: 'wo-ex-2', name: 'Dumbbell Lateral Raise', sets: 3, repetitions: 15, weight_kg: 10, is_completed: true }
  ];

  return `
    <div class="modal-overlay" onclick="if(event.target === this) window.closeModal()">
      <div class="modal-content animate-slide-up" style="max-width: 520px;">
        <div class="flex items-center justify-between" style="margin-bottom: 0.75rem;">
          <div>
            <div class="badge badge-primary" style="margin-bottom: 0.25rem;">Live Session</div>
            <h3 style="font-size: 1.2rem;">${workout ? workout.name : 'Upper Body Hypertrophy Focus'}</h3>
          </div>
          <button class="btn btn-ghost btn-sm" onclick="window.closeModal()">✕</button>
        </div>

        <div class="flex justify-between items-center card" style="padding: 0.75rem 1rem; margin-bottom: 1rem; background: var(--bg-input);">
          <div class="flex items-center gap-2">
            <span style="font-size: 1.2rem;">⏱️</span>
            <div>
              <div class="text-xs text-muted">Session Duration</div>
              <div class="font-mono font-bold" id="workout-stopwatch">45:20</div>
            </div>
          </div>
          <div class="badge badge-blue">1 Credit Consume on Finish</div>
        </div>

        <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin-bottom: 0.5rem;">
          Exercise Checklist & Logging
        </div>

        <div class="flex flex-col gap-3" style="margin-bottom: 1.5rem;" id="exercise-logging-list">
          ${exercises.map((ex, idx) => `
            <div class="card" style="padding: 0.85rem;">
              <div class="flex justify-between items-center" style="margin-bottom: 0.5rem;">
                <div class="font-bold text-sm">${idx + 1}. ${ex.name}</div>
                <div class="badge badge-subtle">${ex.sets} Sets × ${ex.repetitions} Reps</div>
              </div>

              <div class="set-row">
                <div class="text-xs text-muted font-bold">SET</div>
                <div class="text-xs text-muted font-bold">WEIGHT (KG)</div>
                <div class="text-xs text-muted font-bold">REPS</div>
                <div></div>
              </div>

              <div class="set-row">
                <div class="font-bold text-xs">1</div>
                <input type="number" class="input" style="padding: 0.35rem 0.5rem; height: 32px;" value="${ex.weight_kg || 60}" />
                <input type="number" class="input" style="padding: 0.35rem 0.5rem; height: 32px;" value="${ex.repetitions || 10}" />
                <button class="set-check-btn completed" title="Set completed">✓</button>
              </div>
            </div>
          `).join('')}
        </div>

        <div class="flex gap-2">
          <button type="button" class="btn btn-secondary flex-1" onclick="window.closeModal()">Pause / Save</button>
          <button 
            type="button" 
            class="btn btn-primary flex-1 font-bold" 
            onclick="window.finishSessionAndDeductCredit('${session ? session.id : ''}', '${workout ? workout.id : ''}')">
            Complete Session 🏆
          </button>
        </div>
      </div>
    </div>
  `;
}
