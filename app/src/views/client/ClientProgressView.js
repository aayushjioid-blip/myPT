// Client Progress & Privacy Settings View

import { store } from '../../state/store.js';

export function renderClientProgressView() {
  const state = store.getState();
  const client = store.getCurrentUser();
  const measurements = state.progress_measurements.filter(m => m.client_id === client.id);
  const isShared = client.share_personal_info_with_trainer;

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div>
        <h2 class="text-2xl font-extrabold">Body Metrics & Progress</h2>
        <p class="text-xs text-muted">Track body transformation trends and manage trainer sharing permissions.</p>
      </div>

      <!-- Rule Adherence 2: Optional Personal Information & Explicit Sharing Toggle -->
      <div class="card" style="background: rgba(139, 92, 246, 0.08); border-color: rgba(139, 92, 246, 0.3);">
        <div class="flex justify-between items-center" style="margin-bottom: 0.5rem;">
          <div class="flex items-center gap-2">
            <span style="font-size: 1.2rem;">🔒</span>
            <div class="font-bold text-sm">Medical & Health Privacy</div>
          </div>
          <span class="badge ${isShared ? 'badge-primary' : 'badge-subtle'}">
            ${isShared ? 'Shared' : 'Private to You'}
          </span>
        </div>

        <p class="text-xs text-muted" style="margin-bottom: 0.75rem;">
          Health information, injuries, and medical intake are strictly optional. Your trainer only accesses your data if you explicitly opt in.
        </p>

        <div class="flex items-center justify-between card" style="padding: 0.75rem; background: var(--bg-surface);">
          <span class="text-xs font-semibold">Share with my trainer</span>
          <label style="position: relative; display: inline-block; width: 44px; height: 24px;">
            <input 
              type="checkbox" 
              ${isShared ? 'checked' : ''} 
              onchange="window.toggleTrainerSharing(this.checked)"
              style="opacity: 0; width: 0; height: 0;" />
            <span style="position: absolute; cursor: pointer; inset: 0; background-color: ${isShared ? '#10B981' : '#374151'}; border-radius: 24px; transition: .3s;">
              <span style="position: absolute; content: ''; height: 18px; width: 18px; left: ${isShared ? '22px' : '3px'}; bottom: 3px; background-color: white; border-radius: 50%; transition: .3s;"></span>
            </span>
          </label>
        </div>
      </div>

      <!-- Metric Highlights -->
      <div class="stat-grid">
        <div class="stat-box">
          <span class="stat-label">Current Weight</span>
          <span class="stat-value text-primary">64.5 <small class="text-xs text-muted">kg</small></span>
          <span class="text-xs text-primary font-bold">↓ 3.5 kg total lost</span>
        </div>

        <div class="stat-box">
          <span class="stat-label">Body Fat %</span>
          <span class="stat-value text-blue">21.8 <small class="text-xs text-muted">%</small></span>
          <span class="text-xs text-blue font-bold">↓ 2.7% reduction</span>
        </div>
      </div>

      <!-- Measurement Trend History -->
      <div class="text-xs font-bold text-muted uppercase tracking-wider">
        Measurement History
      </div>

      <div class="flex flex-col gap-2">
        ${measurements.map(m => `
          <div class="card" style="padding: 0.85rem;">
            <div class="flex justify-between items-center" style="margin-bottom: 0.35rem;">
              <span class="font-bold text-sm">${m.date}</span>
              <span class="badge badge-primary">${m.weight} kg</span>
            </div>
            <div class="flex gap-3 text-xs text-muted">
              <span>Waist: <strong>${m.waist} cm</strong></span>
              <span>Chest: <strong>${m.chest} cm</strong></span>
              <span>Body Fat: <strong>${m.body_fat}%</strong></span>
            </div>
          </div>
        `).join('')}
      </div>

      <!-- Progress Photos Mock Box -->
      <div class="card" style="border-style: dashed; text-align: center; padding: 1.5rem;">
        <div style="font-size: 1.8rem; margin-bottom: 0.35rem;">📸</div>
        <div class="font-bold text-sm">Private Progress Photos</div>
        <p class="text-xs text-muted" style="margin: 0.25rem 0 0.75rem 0;">
          Encrypted and accessible only by you and your assigned trainer.
        </p>
        <button class="btn btn-secondary btn-sm" onclick="alert('Photo upload simulator: Front / Side / Back views stored in private bucket.')">
          + Add Progress Photo
        </button>
      </div>
    </div>
  `;
}
