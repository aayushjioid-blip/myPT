// FitTrainer Own Workout Builder Modal (Milestone 1)

import { store } from '../state/store.js';

export function renderOwnWorkoutBuilderModal() {
  const state = store.getState();
  const exercises = state.exercises;

  return `
    <div class="modal-backdrop animate-fade-in" onclick="if(event.target === this) window.closeModal()">
      <div class="modal-content" style="max-width: 500px; max-height: 90vh; overflow-y: auto;">
        <div class="flex justify-between items-center" style="margin-bottom: 0.75rem;">
          <div class="flex items-center gap-2">
            <span style="font-size: 1.3rem;">🏃</span>
            <div class="font-extrabold text-base">Build "Own Workout"</div>
          </div>
          <button class="btn btn-secondary btn-sm" onclick="window.closeModal()">✕</button>
        </div>

        <!-- 0 Credit Guarantee Banner -->
        <div class="card" style="background: rgba(59, 130, 246, 0.08); border-color: rgba(59, 130, 246, 0.3); padding: 0.75rem; margin-bottom: 1rem;">
          <div class="flex items-center gap-2">
            <span>🛡️</span>
            <span class="text-xs text-muted">
              <strong class="text-blue">0 PT Credits Deducted</strong>: Self-workouts are 100% free and never consume session credits.
            </span>
          </div>
        </div>

        <form id="own-workout-form" onsubmit="window.submitOwnWorkoutForm(event)">
          <div class="form-group">
            <label class="form-label">Workout Routine Name *</label>
            <input type="text" class="input" id="own-wo-name" placeholder="e.g. Saturday Core & Legs Power" value="Self-Trained Upper Power" required />
          </div>

          <div class="form-group">
            <label class="form-label">Notes & Objectives (Optional)</label>
            <input type="text" class="input" id="own-wo-notes" placeholder="e.g. 45 min tempo lifting and core focus" value="High intensity superset workout" />
          </div>

          <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin: 1rem 0 0.5rem 0;">
            Select Exercises (Choose 2-5)
          </div>

          <!-- Dynamic Exercise Selector Checklist -->
          <div class="flex flex-col gap-2" style="max-height: 240px; overflow-y: auto; padding: 0.25rem;">
            ${exercises.slice(0, 8).map((ex, idx) => `
              <div class="card flex items-center justify-between" style="padding: 0.6rem 0.75rem; background: var(--bg-input);">
                <div class="flex items-center gap-2">
                  <input type="checkbox" class="own-ex-checkbox" value="${ex.id}" id="ex-check-${ex.id}" ${idx < 3 ? 'checked' : ''} />
                  <label for="ex-check-${ex.id}" class="text-xs font-semibold cursor-pointer">
                    ${ex.name} <span class="text-muted font-normal">(${ex.category})</span>
                  </label>
                </div>
                <span class="badge badge-subtle" style="font-size: 0.65rem;">${ex.equipment}</span>
              </div>
            `).join('')}
          </div>

          <div class="flex gap-2" style="margin-top: 1.25rem;">
            <button type="button" class="btn btn-secondary flex-1" onclick="window.closeModal()">Cancel</button>
            <button type="submit" class="btn btn-primary flex-1 font-bold">
              Complete & Log (0 Credits) 🔥
            </button>
          </div>
        </form>
      </div>
    </div>
  `;
}
