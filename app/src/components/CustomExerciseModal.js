// FitTrainer Custom Exercise Creator Modal (Milestone 2)

export function renderCustomExerciseModal() {
  const categories = [
    'Chest', 'Back', 'Legs', 'Shoulders', 'Biceps', 'Triceps',
    'Forearms', 'Glutes', 'Hips', 'Core', 'Calves', 'Full Body'
  ];

  const equipments = [
    'Barbell', 'Dumbbells', 'Cable', 'Kettlebell', 'Machine',
    'Bodyweight', 'Resistance Bands', 'EZ-Bar', 'Medicine Ball', 'TRX / Suspension'
  ];

  return `
    <div class="modal-backdrop animate-fade-in" onclick="if(event.target === this) window.closeModal()">
      <div class="modal-content" style="max-width: 480px;">
        <div class="flex justify-between items-center" style="margin-bottom: 1rem;">
          <div class="flex items-center gap-2">
            <span style="font-size: 1.3rem;">🏋️</span>
            <div class="font-extrabold text-base">Add Custom Exercise</div>
          </div>
          <button class="btn btn-secondary btn-sm" onclick="window.closeModal()">✕</button>
        </div>

        <p class="text-xs text-muted" style="margin-bottom: 1rem;">
          Create a personalized exercise movement to expand your coaching directory and program templates.
        </p>

        <form id="custom-exercise-form" onsubmit="window.submitCustomExerciseForm(event)">
          <div class="form-group">
            <label class="form-label">Exercise Name *</label>
            <input type="text" class="input" id="cust-ex-name" placeholder="e.g. Landmine Single-Arm Press" required />
          </div>

          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem;">
            <div class="form-group">
              <label class="form-label">Muscle Category *</label>
              <select class="input" id="cust-ex-category" required>
                ${categories.map(c => `<option value="${c}">${c}</option>`).join('')}
              </select>
            </div>

            <div class="form-group">
              <label class="form-label">Equipment *</label>
              <select class="input" id="cust-ex-equipment" required>
                ${equipments.map(eq => `<option value="${eq}">${eq}</option>`).join('')}
              </select>
            </div>
          </div>

          <div class="form-group">
            <label class="form-label">Target Muscles & Biomechanics</label>
            <input type="text" class="input" id="cust-ex-target" placeholder="e.g. Anterior Deltoid, Serratus Anterior, Core" required />
          </div>

          <div class="form-group">
            <label class="form-label">Execution Instructions & Form Cues</label>
            <textarea class="input" id="cust-ex-desc" rows="3" placeholder="Step-by-step coaching cues, tempo, and breathing pattern..."></textarea>
          </div>

          <div class="flex gap-2" style="margin-top: 1rem;">
            <button type="button" class="btn btn-secondary flex-1" onclick="window.closeModal()">Cancel</button>
            <button type="submit" class="btn btn-primary flex-1 font-bold">Save Exercise 💾</button>
          </div>
        </form>
      </div>
    </div>
  `;
}
