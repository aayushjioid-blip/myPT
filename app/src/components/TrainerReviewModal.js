// FitTrainer Trainer Review Modal (Milestone 6)

import { store } from '../state/store.js';

export function renderTrainerReviewModal(data = {}) {
  const state = store.getState();
  const trainer = state.trainers.find(t => t.id === data.trainerId) || state.trainers[0];

  return `
    <div class="modal-backdrop animate-fade-in" onclick="if(event.target === this) window.closeModal()">
      <div class="modal-content" style="max-width: 460px;">
        <div class="flex justify-between items-center" style="margin-bottom: 1rem;">
          <div class="flex items-center gap-2">
            <span style="font-size: 1.3rem;">⭐</span>
            <div class="font-extrabold text-base">Review & Rate Trainer</div>
          </div>
          <button class="btn btn-secondary btn-sm" onclick="window.closeModal()">✕</button>
        </div>

        <div class="card" style="padding: 0.75rem; background: var(--bg-input); margin-bottom: 1rem;">
          <div class="font-bold text-sm">${trainer.name}</div>
          <div class="text-xs text-muted">${trainer.bio.slice(0, 70)}...</div>
        </div>

        <form id="review-form" onsubmit="window.submitReviewForm(event, '${trainer.id}')">
          <div class="form-group">
            <label class="form-label">Rating *</label>
            <div class="flex gap-3 items-center" style="margin-top: 0.25rem;">
              <select class="input flex-1" id="review-rating" required>
                <option value="5">⭐⭐⭐⭐⭐ (5.0 - Exceptional)</option>
                <option value="4">⭐⭐⭐⭐ (4.0 - Very Good)</option>
                <option value="3">⭐⭐⭐ (3.0 - Good)</option>
                <option value="2">⭐⭐ (2.0 - Needs Improvement)</option>
                <option value="1">⭐ (1.0 - Poor)</option>
              </select>
            </div>
          </div>

          <div class="form-group">
            <label class="form-label">Your Review & Coaching Feedback *</label>
            <textarea 
              class="input" 
              id="review-comment" 
              rows="3" 
              placeholder="Share how this trainer helped you reach your fitness goals, their punctuality, exercise form coaching, and motivation..."
              required></textarea>
          </div>

          <div class="flex gap-2" style="margin-top: 1rem;">
            <button type="button" class="btn btn-secondary flex-1" onclick="window.closeModal()">Cancel</button>
            <button type="submit" class="btn btn-primary flex-1 font-bold">Post Review ⭐</button>
          </div>
        </form>
      </div>
    </div>
  `;
}
