// FitTrainer Workout Template Builder Modal (Milestone 2)

import { store } from '../state/store.js';

export function renderTemplateBuilderModal(data = {}) {
  const state = store.getState();
  const exercises = state.exercises;
  const isEditing = Boolean(data.templateId);
  const existingTemplate = isEditing ? state.workout_templates.find(t => t.id === data.templateId) : null;

  return `
    <div class="modal-backdrop animate-fade-in" onclick="if(event.target === this) window.closeModal()">
      <div class="modal-content" style="max-width: 500px; max-height: 90vh; overflow-y: auto;">
        <div class="flex justify-between items-center" style="margin-bottom: 1rem;">
          <div class="flex items-center gap-2">
            <span style="font-size: 1.3rem;">📋</span>
            <div class="font-extrabold text-base">
              ${isEditing ? 'Edit Workout Template' : 'Create Workout Template'}
            </div>
          </div>
          <button class="btn btn-secondary btn-sm" onclick="window.closeModal()">✕</button>
        </div>

        <form id="template-builder-form" onsubmit="window.submitTemplateBuilderForm(event, '${data.templateId || ''}')">
          <div class="form-group">
            <label class="form-label">Template Name *</label>
            <input 
              type="text" 
              class="input" 
              id="tmpl-name" 
              placeholder="e.g. Quad Hypertrophy & Calisthenics" 
              value="${existingTemplate ? existingTemplate.name : 'Full Body Functional Strength'}" 
              required />
          </div>

          <div class="form-group">
            <label class="form-label">Description & Coaching Objective *</label>
            <input 
              type="text" 
              class="input" 
              id="tmpl-desc" 
              placeholder="e.g. Progressive overload on compound lifts" 
              value="${existingTemplate ? existingTemplate.description : 'High dynamic intensity workout with compound progressions.'}" 
              required />
          </div>

          <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin: 1rem 0 0.5rem 0;">
            Select Template Exercises (Choose 2-4)
          </div>

          <div class="flex flex-col gap-2" style="max-height: 220px; overflow-y: auto; padding: 0.25rem;">
            ${exercises.slice(0, 10).map((ex, idx) => {
              const isChecked = existingTemplate 
                ? existingTemplate.exercises.some(e => e.exercise_id === ex.id || e.name === ex.name)
                : idx < 3;

              return `
                <div class="card flex items-center justify-between" style="padding: 0.5rem 0.75rem; background: var(--bg-input);">
                  <div class="flex items-center gap-2">
                    <input type="checkbox" class="tmpl-ex-checkbox" value="${ex.id}" id="tmpl-chk-${ex.id}" ${isChecked ? 'checked' : ''} />
                    <label for="tmpl-chk-${ex.id}" class="text-xs font-semibold cursor-pointer">
                      ${ex.name} <span class="text-muted font-normal">(${ex.category})</span>
                    </label>
                  </div>
                  <span class="badge badge-subtle" style="font-size: 0.65rem;">${ex.equipment}</span>
                </div>
              `;
            }).join('')}
          </div>

          <div class="flex gap-2" style="margin-top: 1.25rem;">
            <button type="button" class="btn btn-secondary flex-1" onclick="window.closeModal()">Cancel</button>
            <button type="submit" class="btn btn-primary flex-1 font-bold">
              ${isEditing ? 'Update Template 💾' : 'Save Template 💾'}
            </button>
          </div>
        </form>
      </div>
    </div>
  `;
}
