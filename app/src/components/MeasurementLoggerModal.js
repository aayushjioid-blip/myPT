// FitTrainer Measurement Logger Modal (Milestone 1)

import { store } from '../state/store.js';

export function renderMeasurementLoggerModal(data = {}) {
  const currentUser = store.getCurrentUser();
  const defaultHeight = currentUser.height_cm || 168;
  const defaultWeight = currentUser.weight_kg || 64.5;
  const today = new Date().toISOString().split('T')[0];

  return `
    <div class="modal-backdrop animate-fade-in" onclick="if(event.target === this) window.closeModal()">
      <div class="modal-content" style="max-width: 480px; max-height: 90vh; overflow-y: auto;">
        <div class="flex justify-between items-center" style="margin-bottom: 1rem;">
          <div class="flex items-center gap-2">
            <span style="font-size: 1.3rem;">📐</span>
            <div class="font-extrabold text-base">Log Body Measurements</div>
          </div>
          <button class="btn btn-secondary btn-sm" onclick="window.closeModal()">✕</button>
        </div>

        <p class="text-xs text-muted" style="margin-bottom: 1rem;">
          Track body composition, circumferences, and private progress photos over time.
        </p>

        <form id="measurement-form" onsubmit="window.submitBodyMeasurement(event)">
          <div class="form-group">
            <label class="form-label">Assessment Date</label>
            <input type="date" class="input" id="m-date" value="${today}" required />
          </div>

          <!-- Primary Stats -->
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem;">
            <div class="form-group">
              <label class="form-label">Weight (kg) *</label>
              <input type="number" step="0.1" class="input" id="m-weight" value="${defaultWeight}" oninput="window.updateModalBmiCalculation()" required />
            </div>

            <div class="form-group">
              <label class="form-label">Height (cm) *</label>
              <input type="number" step="0.5" class="input" id="m-height" value="${defaultHeight}" oninput="window.updateModalBmiCalculation()" required />
            </div>
          </div>

          <!-- Auto-Calculated BMI & Body Fat -->
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem;">
            <div class="form-group">
              <label class="form-label">Calculated BMI</label>
              <input type="text" class="input font-bold text-primary" id="m-bmi-display" value="22.9 (Normal)" readonly />
            </div>

            <div class="form-group">
              <label class="form-label">Body Fat % (Optional)</label>
              <input type="number" step="0.1" class="input" id="m-bodyfat" placeholder="e.g. 21.5" value="21.8" />
            </div>
          </div>

          <!-- Circumferences Section -->
          <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin: 0.75rem 0 0.5rem 0;">
            Body Circumferences (cm)
          </div>

          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.5rem;">
            <div class="form-group">
              <label class="form-label text-xs">Chest</label>
              <input type="number" step="0.5" class="input" id="m-chest" placeholder="cm" value="91.0" />
            </div>
            <div class="form-group">
              <label class="form-label text-xs">Waist</label>
              <input type="number" step="0.5" class="input" id="m-waist" placeholder="cm" value="72.0" />
            </div>
            <div class="form-group">
              <label class="form-label text-xs">Hips</label>
              <input type="number" step="0.5" class="input" id="m-hips" placeholder="cm" value="96.0" />
            </div>
            <div class="form-group">
              <label class="form-label text-xs">Biceps</label>
              <input type="number" step="0.5" class="input" id="m-biceps" placeholder="cm" value="29.2" />
            </div>
            <div class="form-group">
              <label class="form-label text-xs">Thighs</label>
              <input type="number" step="0.5" class="input" id="m-thighs" placeholder="cm" value="55.0" />
            </div>
            <div class="form-group">
              <label class="form-label text-xs">Calves</label>
              <input type="number" step="0.5" class="input" id="m-calves" placeholder="cm" value="36.5" />
            </div>
          </div>

          <!-- Progress Photos Simulator -->
          <div class="form-group" style="margin-top: 0.5rem;">
            <label class="form-label text-xs">Progress Photos (Front, Side, Back)</label>
            <div class="card" style="padding: 0.75rem; text-align: center; background: var(--bg-input); border-style: dashed;">
              <div class="text-xs text-muted" id="photo-upload-status">📸 3 Angles Attached: Front, Side, Back</div>
            </div>
          </div>

          <!-- Notes -->
          <div class="form-group">
            <label class="form-label text-xs">Trainer / Client Check-in Notes</label>
            <textarea class="input" id="m-notes" rows="2" placeholder="e.g. Energy levels great, feeling stronger in morning sessions..."></textarea>
          </div>

          <div class="flex gap-2" style="margin-top: 1rem;">
            <button type="button" class="btn btn-secondary flex-1" onclick="window.closeModal()">Cancel</button>
            <button type="submit" class="btn btn-primary flex-1 font-bold">Save Measurement 💾</button>
          </div>
        </form>
      </div>
    </div>
  `;
}
