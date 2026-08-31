// Trainer Workout Library & Template Builder View

import { store } from '../../state/store.js';

export function renderTrainerWorkoutsView() {
  const state = store.getState();
  const templates = state.workout_templates;
  const exercises = state.exercises;

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div class="flex justify-between items-center">
        <div>
          <h2 class="text-2xl font-extrabold">Workout Studio</h2>
          <p class="text-xs text-muted">Build reusable routines and exercise libraries.</p>
        </div>
        <button class="btn btn-primary btn-sm" onclick="alert('Custom Exercise Creator: Add to your personal library.')">
          + Exercise
        </button>
      </div>

      <!-- Workout Templates -->
      <div class="text-xs font-bold text-muted uppercase tracking-wider">
        Workout Templates (${templates.length})
      </div>

      <div class="flex flex-col gap-3">
        ${templates.map(tmpl => `
          <div class="card card-glow">
            <div class="flex justify-between items-start" style="margin-bottom: 0.5rem;">
              <div>
                <div class="font-bold text-base">${tmpl.name}</div>
                <div class="text-xs text-muted">${tmpl.description}</div>
              </div>
              <span class="badge badge-primary">${tmpl.exercises.length} Exercises</span>
            </div>

            <div class="flex flex-col gap-1" style="margin: 0.5rem 0;">
              ${tmpl.exercises.map((ex, idx) => `
                <div class="flex justify-between text-xs" style="padding: 0.3rem 0; border-bottom: 1px solid var(--border-color);">
                  <span class="font-semibold">${idx + 1}. ${ex.name}</span>
                  <span class="text-muted font-mono">${ex.sets} sets × ${ex.reps} reps @ ${ex.weight}kg</span>
                </div>
              `).join('')}
            </div>

            <div class="flex gap-2" style="margin-top: 0.5rem;">
              <button class="btn btn-secondary btn-sm flex-1" onclick="window.assignWorkoutToClient('usr-client-1')">
                Assign to Sarah 📋
              </button>
              <button class="btn btn-primary btn-sm flex-1" onclick="window.openWorkoutLoggerModal('', '')">
                Test Live Run ⏱️
              </button>
            </div>
          </div>
        `).join('')}
      </div>

      <!-- Global & Custom Exercise Catalog -->
      <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin-top: 0.5rem;">
        Exercise Directory (${exercises.length})
      </div>

      <div class="flex flex-col gap-2">
        ${exercises.slice(0, 6).map(ex => `
          <div class="card" style="padding: 0.75rem;">
            <div class="flex justify-between items-center">
              <div>
                <div class="font-bold text-sm">${ex.name}</div>
                <div class="text-xs text-muted">${ex.category} • ${ex.equipment}</div>
              </div>
              <span class="badge badge-subtle">${ex.target}</span>
            </div>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}
