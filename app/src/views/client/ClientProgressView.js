// Client Progress & Body Composition Tracking View (Milestone 1)

import { store } from '../../state/store.js';

export function renderClientProgressView() {
  const state = store.getState();
  const client = store.getCurrentUser();
  const measurements = state.progress_measurements.filter(m => m.client_id === client.id);
  const isShared = client.share_personal_info_with_trainer;

  const latest = measurements[0] || {
    weight: 64.5,
    bmi: 22.9,
    body_fat: 21.8,
    chest: 91.0,
    waist: 72.0,
    hips: 96.0,
    biceps: 29.2,
    thighs: 55.0,
    calves: 36.5
  };

  const oldest = measurements[measurements.length - 1] || latest;
  const weightChange = (latest.weight - oldest.weight).toFixed(1);
  const fatChange = (latest.body_fat - oldest.body_fat).toFixed(1);

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div class="flex justify-between items-center">
        <div>
          <h2 class="text-2xl font-extrabold">Body Metrics & Progress</h2>
          <p class="text-xs text-muted">Comprehensive 8-point measurements, BMI, and photo tracking.</p>
        </div>
        <button class="btn btn-primary btn-sm font-bold" onclick="window.openMeasurementModal()">
          + Log Entry 📐
        </button>
      </div>

      <!-- Rule 2 & 4: Optional Personal Info & Explicit Privacy Opt-In Toggle -->
      <div class="card" style="background: rgba(139, 92, 246, 0.08); border-color: rgba(139, 92, 246, 0.3);">
        <div class="flex justify-between items-center" style="margin-bottom: 0.5rem;">
          <div class="flex items-center gap-2">
            <span style="font-size: 1.2rem;">🔒</span>
            <div class="font-bold text-sm">Medical & Metric Privacy Shield</div>
          </div>
          <span class="badge ${isShared ? 'badge-primary' : 'badge-subtle'}">
            ${isShared ? 'Shared with Trainer' : 'Private to You'}
          </span>
        </div>

        <p class="text-xs text-muted" style="margin-bottom: 0.75rem;">
          Health information, body metrics, and progress photos are strictly optional. Your trainer only accesses your data if you explicitly enable sharing.
        </p>

        <div class="flex items-center justify-between card" style="padding: 0.75rem; background: var(--bg-surface);">
          <span class="text-xs font-semibold">Share progress metrics with my trainer</span>
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

      <!-- Primary KPI Gauges -->
      <div class="stat-grid">
        <div class="stat-box">
          <span class="stat-label">Current Weight</span>
          <span class="stat-value text-primary">${latest.weight} <small class="text-xs text-muted">kg</small></span>
          <span class="text-xs ${parseFloat(weightChange) <= 0 ? 'text-primary' : 'text-rose'} font-bold">
            ${parseFloat(weightChange) <= 0 ? '↓' : '↑'} ${Math.abs(weightChange)} kg change
          </span>
        </div>

        <div class="stat-box">
          <span class="stat-label">BMI & Body Fat</span>
          <span class="stat-value text-blue">${latest.bmi} <small class="text-xs text-muted">BMI</small></span>
          <span class="text-xs text-blue font-bold">${latest.body_fat}% Fat (${fatChange}% change)</span>
        </div>
      </div>

      <!-- Visual Progress Trend Chart (SVG Sparkline) -->
      <div class="card">
        <div class="flex justify-between items-center" style="margin-bottom: 0.75rem;">
          <span class="text-xs font-bold text-muted uppercase">Weight Trendline (kg)</span>
          <span class="badge badge-subtle font-mono">${measurements.length} check-ins</span>
        </div>

        <div style="width: 100%; height: 120px; position: relative;">
          <svg viewBox="0 0 300 100" style="width: 100%; height: 100%; overflow: visible;">
            <defs>
              <linearGradient id="grad-weight" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stop-color="#10B981" stop-opacity="0.3"/>
                <stop offset="100%" stop-color="#10B981" stop-opacity="0.0"/>
              </linearGradient>
            </defs>
            <!-- Gridlines -->
            <line x1="0" y1="20" x2="300" y2="20" stroke="rgba(255,255,255,0.05)" stroke-width="1"/>
            <line x1="0" y1="50" x2="300" y2="50" stroke="rgba(255,255,255,0.05)" stroke-width="1"/>
            <line x1="0" y1="80" x2="300" y2="80" stroke="rgba(255,255,255,0.05)" stroke-width="1"/>
            
            <!-- Area & Line -->
            <polygon points="20,20 150,55 280,85 280,100 20,100" fill="url(#grad-weight)" />
            <polyline points="20,20 150,55 280,85" fill="none" stroke="#10B981" stroke-width="3" stroke-linecap="round"/>
            
            <!-- Data Points -->
            <circle cx="20" cy="20" r="5" fill="#10B981" />
            <text x="20" y="12" fill="#10B981" font-size="9" text-anchor="middle" font-weight="bold">68.0 kg</text>
            
            <circle cx="150" cy="55" r="5" fill="#10B981" />
            <text x="150" y="47" fill="#10B981" font-size="9" text-anchor="middle" font-weight="bold">66.2 kg</text>
            
            <circle cx="280" cy="85" r="6" fill="#059669" stroke="#fff" stroke-width="2" />
            <text x="280" y="77" fill="#10B981" font-size="9" text-anchor="middle" font-weight="bold">64.5 kg</text>
          </svg>
        </div>
      </div>

      <!-- 8-Point Circumferences Breakdown -->
      <div class="card">
        <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin-bottom: 0.75rem;">
          Latest Body Circumferences (8-Point Scan)
        </div>

        <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 0.5rem; text-align: center;">
          <div class="card" style="padding: 0.5rem; background: var(--bg-input);">
            <div class="text-xs text-muted">Chest</div>
            <div class="font-extrabold text-sm text-primary">${latest.chest} cm</div>
          </div>
          <div class="card" style="padding: 0.5rem; background: var(--bg-input);">
            <div class="text-xs text-muted">Waist</div>
            <div class="font-extrabold text-sm text-primary">${latest.waist} cm</div>
          </div>
          <div class="card" style="padding: 0.5rem; background: var(--bg-input);">
            <div class="text-xs text-muted">Hips</div>
            <div class="font-extrabold text-sm text-primary">${latest.hips} cm</div>
          </div>
          <div class="card" style="padding: 0.5rem; background: var(--bg-input);">
            <div class="text-xs text-muted">Biceps</div>
            <div class="font-extrabold text-sm text-primary">${latest.biceps} cm</div>
          </div>
          <div class="card" style="padding: 0.5rem; background: var(--bg-input);">
            <div class="text-xs text-muted">Thighs</div>
            <div class="font-extrabold text-sm text-primary">${latest.thighs} cm</div>
          </div>
          <div class="card" style="padding: 0.5rem; background: var(--bg-input);">
            <div class="text-xs text-muted">Calves</div>
            <div class="font-extrabold text-sm text-primary">${latest.calves} cm</div>
          </div>
        </div>
      </div>

      <!-- Measurement History Log Table -->
      <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin-top: 0.25rem;">
        Historical Log (${measurements.length})
      </div>

      <div class="flex flex-col gap-2">
        ${measurements.map(m => `
          <div class="card" style="padding: 0.85rem;">
            <div class="flex justify-between items-center" style="margin-bottom: 0.35rem;">
              <span class="font-bold text-sm">${m.date}</span>
              <span class="badge badge-primary font-mono">${m.weight} kg • ${m.bmi} BMI</span>
            </div>
            <div class="flex flex-wrap gap-2 text-xs text-muted" style="margin-top: 0.25rem;">
              <span>Waist: <strong>${m.waist}cm</strong></span>
              <span>Chest: <strong>${m.chest}cm</strong></span>
              <span>Hips: <strong>${m.hips}cm</strong></span>
              <span>Fat: <strong>${m.body_fat}%</strong></span>
            </div>
            ${m.notes ? `<div class="text-xs text-subtle italic" style="margin-top: 0.35rem;">"${m.notes}"</div>` : ''}
          </div>
        `).join('')}
      </div>

      <!-- Private Progress Photos Carousel Box -->
      <div class="card" style="padding: 1.25rem;">
        <div class="flex justify-between items-center" style="margin-bottom: 0.5rem;">
          <div class="flex items-center gap-2">
            <span>📸</span>
            <div class="font-bold text-sm">Private Transformation Photos</div>
          </div>
          <span class="badge badge-subtle">3 Uploads</span>
        </div>
        <p class="text-xs text-muted" style="margin-bottom: 0.75rem;">
          Private gallery encrypted for personal transformation review.
        </p>

        <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 0.5rem; text-align: center;">
          <div class="card" style="padding: 1rem 0.5rem; background: var(--bg-input); border-style: dashed;">
            <div style="font-size: 1.5rem;">🧍</div>
            <div class="text-xs font-bold" style="margin-top: 0.25rem;">Front</div>
            <div class="text-xs text-primary font-mono" style="font-size: 0.65rem;">Aug 2026</div>
          </div>
          <div class="card" style="padding: 1rem 0.5rem; background: var(--bg-input); border-style: dashed;">
            <div style="font-size: 1.5rem;">🚶</div>
            <div class="text-xs font-bold" style="margin-top: 0.25rem;">Side Profile</div>
            <div class="text-xs text-primary font-mono" style="font-size: 0.65rem;">Aug 2026</div>
          </div>
          <div class="card" style="padding: 1rem 0.5rem; background: var(--bg-input); border-style: dashed;">
            <div style="font-size: 1.5rem;">🏋️</div>
            <div class="text-xs font-bold" style="margin-top: 0.25rem;">Back Lats</div>
            <div class="text-xs text-primary font-mono" style="font-size: 0.65rem;">Aug 2026</div>
          </div>
        </div>
      </div>
    </div>
  `;
}
