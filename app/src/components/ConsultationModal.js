// Consultation Request Modal Component

import { store } from '../state/store.js';

export function renderConsultationModal(data = {}) {
  const state = store.getState();
  const trainer = state.trainers.find(t => t.id === data.trainerId) || state.trainers[0];

  return `
    <div class="modal-overlay" onclick="if(event.target === this) window.closeModal()">
      <div class="modal-content animate-slide-up">
        <div class="flex items-center justify-between" style="margin-bottom: 1rem;">
          <h3 style="font-size: 1.15rem;">Request Consultation</h3>
          <button class="btn btn-ghost btn-sm" onclick="window.closeModal()">✕</button>
        </div>

        <div class="flex items-center gap-3 card" style="padding: 0.75rem; margin-bottom: 1rem;">
          <div class="trainer-avatar">${trainer.name.charAt(0)}</div>
          <div>
            <div class="font-bold">${trainer.name}</div>
            <div class="text-xs text-muted">${trainer.certifications.join(' • ')}</div>
          </div>
        </div>

        <p class="text-sm text-muted" style="margin-bottom: 1rem;">
          Express interest to connect with your trainer. Once approved, you can select and purchase training packages.
        </p>

        <form id="consultation-form" onsubmit="window.submitConsultation(event, '${trainer.id}')">
          <div class="form-group">
            <label class="form-label">Primary Fitness Goal</label>
            <select class="input" id="consult-goal" required>
              <option value="Fat Loss & Body Recomposition">Fat Loss & Body Recomposition</option>
              <option value="Muscle Building / Hypertrophy">Muscle Building / Hypertrophy</option>
              <option value="Strength & Powerlifting">Strength & Powerlifting</option>
              <option value="Athletic Conditioning & Mobility">Athletic Conditioning & Mobility</option>
            </select>
          </div>

          <div class="form-group">
            <label class="form-label">Notes for Trainer (Optional)</label>
            <textarea class="input" id="consult-notes" rows="3" placeholder="Tell the trainer about your schedule preferences or target timeline..."></textarea>
          </div>

          <div class="flex gap-2" style="margin-top: 1.25rem;">
            <button type="button" class="btn btn-secondary flex-1" onclick="window.closeModal()">Cancel</button>
            <button type="submit" class="btn btn-primary flex-1">Send Request 🚀</button>
          </div>
        </form>
      </div>
    </div>
  `;
}
