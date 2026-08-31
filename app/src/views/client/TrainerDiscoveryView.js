// Trainer Discovery & Public Profile View

import { store } from '../../state/store.js';

export function renderTrainerDiscoveryView() {
  const state = store.getState();
  const flags = state.feature_flags;
  const client = store.getCurrentUser();

  // RULE ADHERENCE 6: Only verified trainers appear in public discovery!
  const verifiedTrainers = state.trainers.filter(t => t.verification_status === 'VERIFIED');

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div>
        <h2 class="text-2xl font-extrabold">Discover Trainers</h2>
        <p class="text-xs text-muted">Browse certified personal trainers or connect via QR code.</p>
      </div>

      <!-- Search & Connection Bar -->
      <div class="flex gap-2">
        <input 
          type="text" 
          class="input flex-1" 
          placeholder="🔍 Search trainer by name..." 
          id="trainer-search-input" 
          oninput="window.filterTrainersByName(this.value)" />
        <button class="btn btn-secondary" onclick="window.promptTrainerCode()" title="Enter 6-digit Trainer Code">
          # Code
        </button>
      </div>

      <!-- Feature Flag Gated: Advanced Filters -->
      ${flags.advanced_trainer_search ? `
        <div class="card" style="padding: 0.75rem; background: var(--bg-input);">
          <div class="flex justify-between items-center" style="margin-bottom: 0.5rem;">
            <span class="text-xs font-bold text-primary uppercase">⚡ Advanced Filters (Feature Flag Active)</span>
          </div>
          <div class="filter-bar">
            <span class="filter-chip active">All Specializations</span>
            <span class="filter-chip">Fat Loss</span>
            <span class="filter-chip">Hypertrophy</span>
            <span class="filter-chip">Mobility & Rehab</span>
            <span class="filter-chip">Strength</span>
          </div>
        </div>
      ` : `
        <!-- Minimal standard filter as required by user correction 1 -->
        <div class="text-xs text-subtle flex items-center gap-1">
          <span>🔒 Advanced search filters hidden (Feature Flag: <code>advanced_trainer_search = false</code>)</span>
        </div>
      `}

      <!-- Verified Trainers List -->
      <div class="flex flex-col gap-3" id="trainers-list-container">
        ${verifiedTrainers.map(trainer => {
          const rel = state.relationships.find(r => r.client_id === client.id && r.trainer_id === trainer.id);
          const status = rel ? rel.status : 'NOT_CONNECTED';

          return `
            <div class="trainer-card card-glow">
              <div class="flex justify-between items-start">
                <div class="flex items-center gap-3">
                  <div class="trainer-avatar">${trainer.name.charAt(0)}</div>
                  <div>
                    <div class="flex items-center gap-1">
                      <span class="font-bold">${trainer.name}</span>
                      <span class="badge badge-primary" style="font-size: 0.65rem; padding: 1px 6px;">✓ Verified</span>
                    </div>
                    <div class="text-xs text-muted">${trainer.experience_years}+ Years Experience • ${trainer.location}</div>
                  </div>
                </div>
                <div class="text-right">
                  <div class="font-bold text-amber">⭐ ${trainer.rating}</div>
                  <div class="text-xs text-subtle">(${trainer.review_count} reviews)</div>
                </div>
              </div>

              <p class="text-xs text-muted" style="line-height: 1.4;">
                ${trainer.bio}
              </p>

              <div class="flex flex-wrap gap-1">
                ${trainer.specializations.map(s => `
                  <span class="badge badge-subtle" style="font-size: 0.65rem;">${s}</span>
                `).join('')}
              </div>

              <div class="flex justify-between items-center" style="margin-top: 0.25rem; padding-top: 0.75rem; border-top: 1px solid var(--border-color);">
                <div class="text-xs text-muted">
                  Code: <strong class="font-mono text-primary">${trainer.trainer_code}</strong>
                </div>

                ${status === 'ACCEPTED' ? `
                  <div class="flex gap-2">
                    <span class="badge badge-primary">✓ Connected</span>
                    <button class="btn btn-primary btn-sm" onclick="window.switchTab('packages')">View Packages 📦</button>
                  </div>
                ` : status === 'REQUESTED' ? `
                  <span class="badge badge-amber">⏳ Request Pending</span>
                ` : `
                  <button class="btn btn-primary btn-sm" onclick="window.openConsultationModal('${trainer.id}')">
                    Request Consultation 🚀
                  </button>
                `}
              </div>
            </div>
          `;
        }).join('')}
      </div>

      <!-- Unverified Trainer Note -->
      <div class="card" style="padding: 0.85rem; background: var(--bg-surface-elevated); border-style: dashed;">
        <div class="text-xs text-muted">
          ℹ️ <strong>Unverified Trainer Access</strong>: Trainers without admin verification (e.g. Leo Novak) do not appear in public search, but clients can connect instantly using their direct trainer code (e.g. <code>LEO007</code>).
        </div>
      </div>
    </div>
  `;
}
