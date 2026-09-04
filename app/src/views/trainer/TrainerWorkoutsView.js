// Trainer Workout Studio, Templates & 12-Category Exercise Directory (Milestone 2)

import { store } from '../../state/store.js';

export function renderTrainerWorkoutsView() {
  const state = store.getState();
  const templates = state.workout_templates;
  const exercises = state.exercises;
  const categories = [
    'All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Biceps', 'Triceps',
    'Forearms', 'Glutes', 'Hips', 'Core', 'Calves', 'Full Body'
  ];

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div class="flex justify-between items-center">
        <div>
          <h2 class="text-2xl font-extrabold">Workout Studio</h2>
          <p class="text-xs text-muted">Build reusable routines, exercise catalogs, and assigned programs.</p>
        </div>
        <div class="flex gap-2">
          <button class="btn btn-secondary btn-sm" onclick="window.openCustomExerciseModal()">
            + Exercise 🏋️
          </button>
          <button class="btn btn-primary btn-sm font-bold" onclick="window.openTemplateBuilderModal('')">
            + Template 📋
          </button>
        </div>
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
              <div class="flex items-center gap-1">
                <span class="badge badge-primary">${tmpl.exercises.length} Exercises</span>
                <button class="btn btn-secondary btn-sm" style="padding: 2px 6px; font-size: 0.7rem;" onclick="window.openTemplateBuilderModal('${tmpl.id}')" title="Edit Template">
                  ✏️
                </button>
              </div>
            </div>

            <div class="flex flex-col gap-1" style="margin: 0.5rem 0;">
              ${tmpl.exercises.map((ex, idx) => `
                <div class="flex justify-between text-xs" style="padding: 0.3rem 0; border-bottom: 1px solid var(--border-color);">
                  <span class="font-semibold">${idx + 1}. ${ex.name}</span>
                  <span class="text-muted font-mono">${ex.sets} sets × ${ex.reps || ex.repetitions || 10} reps @ ${ex.weight || ex.weight_kg || 40}kg</span>
                </div>
              `).join('')}
            </div>

            <div class="flex gap-2" style="margin-top: 0.5rem;">
              <button class="btn btn-secondary btn-sm flex-1" onclick="window.assignWorkoutToClient('usr-client-1', '${tmpl.id}')">
                Assign to Sarah 📋
              </button>
              <button class="btn btn-primary btn-sm flex-1" onclick="window.openWorkoutLoggerModal('', '')">
                Test Live Run ⏱️
              </button>
            </div>
          </div>
        `).join('')}
      </div>

      <!-- 12-Category Global + Custom Exercise Directory -->
      <div class="flex justify-between items-center" style="margin-top: 0.5rem;">
        <div class="text-xs font-bold text-muted uppercase tracking-wider">
          Global & Custom Exercise Library (${exercises.length})
        </div>
      </div>

      <!-- Category Filter Chips -->
      <div class="filter-bar" style="overflow-x: auto; white-space: nowrap; padding-bottom: 4px;">
        ${categories.map((c, i) => `
          <span class="filter-chip ${i === 0 ? 'active' : ''}" onclick="window.filterExercisesCategory('${c}', this)">
            ${c}
          </span>
        `).join('')}
      </div>

      <div class="flex flex-col gap-2" id="exercise-catalog-list">
        ${exercises.map(ex => `
          <div class="card" style="padding: 0.75rem;" data-category="${ex.category}">
            <div class="flex justify-between items-start">
              <div>
                <div class="flex items-center gap-2">
                  <span class="font-bold text-sm">${ex.name}</span>
                  ${ex.is_custom ? '<span class="badge badge-purple" style="font-size: 0.6rem;">Custom</span>' : ''}
                </div>
                <div class="text-xs text-muted" style="margin-top: 2px;">
                  <strong class="text-primary">${ex.category}</strong> • ${ex.equipment} • <span class="text-subtle">${ex.target}</span>
                </div>
                ${ex.description ? `<div class="text-xs text-subtle" style="margin-top: 4px; line-height: 1.3;">${ex.description}</div>` : ''}
              </div>
            </div>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}
