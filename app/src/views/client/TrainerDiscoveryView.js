// Trainer Discovery, Public Profiles & Reviews View (Milestone 6)

import { store } from '../../state/store.js';

export function renderTrainerDiscoveryView() {
  const state = store.getState();
  const flags = state.feature_flags;
  const client = store.getCurrentUser();

  // RULE ADHERENCE: Only verified trainers appear in public discovery!
  const verifiedTrainers = state.trainers.filter(t => t.verification_status === 'VERIFIED');

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div>
        <h2 class="text-2xl font-extrabold">Discover Trainers</h2>
        <p class="text-xs text-muted">Browse certified personal trainers, verified reviews, and ratings.</p>
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

      <!-- Feature Flag Gated: Advanced Filters (RULE 1) -->
      ${flags.advanced_trainer_search ? `
        <div class="card" style="padding: 0.75rem; background: var(--bg-input);">
          <div class="flex justify-between items-center" style="margin-bottom: 0.5rem;">
            <span class="text-xs font-bold text-primary uppercase">⚡ Advanced Filters (Feature Flag Active)</span>
          </div>
          <div class="filter-bar">
            <span class="filter-chip active">All Specializations</span>
            <span class="filter-chip">Fat Loss</span>
            <span class="filter-chip">Hypertrophy</span>
            <span class="filter-chip">Mobility & Calisthenics</span>
            <span class="filter-chip">Strength</span>
          </div>
        </div>
      ` : `
        <!-- Standard filter indicator when flag is disabled -->
        <div class="text-xs text-subtle flex items-center gap-1">
          <span>🔒 Advanced search filters hidden (Feature Flag: <code>advanced_trainer_search = false</code>)</span>
        </div>
      `}

      <!-- Verified Trainers List -->
      <div class="flex flex-col gap-3" id="trainers-list-container">
        ${verifiedTrainers.map(trainer => {
          const rel = state.relationships.find(r => r.client_id === client.id && r.trainer_id === trainer.id);
          const status = rel ? rel.status : 'NOT_CONNECTED';
          const trainerReviews = state.reviews.filter(r => r.trainer_id === trainer.id);

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

              <!-- Specializations & Skills -->
              <div class="flex flex-wrap gap-1">
                ${trainer.specializations.map(s => `
                  <span class="badge badge-subtle" style="font-size: 0.65rem;">${s}</span>
                `).join('')}
                ${(trainer.skills || []).map(sk => `
                  <span class="badge badge-purple" style="font-size: 0.65rem;">${sk}</span>
                `).join('')}
              </div>

              <!-- Client Reviews Snippet (Milestone 6) -->
              <div class="card" style="padding: 0.6rem 0.75rem; background: var(--bg-input); margin-top: 0.35rem;">
                <div class="flex justify-between items-center" style="margin-bottom: 0.35rem;">
                  <span class="text-xs font-bold text-muted uppercase">Verified Client Reviews (${trainerReviews.length})</span>
                  <button class="btn btn-secondary btn-sm" style="font-size: 0.65rem; padding: 2px 8px;" onclick="window.openReviewModal('${trainer.id}')">
                    + Write Review ⭐
                  </button>
                </div>

                ${trainerReviews.length > 0 ? `
                  <div class="text-xs text-muted italic" style="line-height: 1.3;">
                    "${trainerReviews[0].comment}"
                    <span class="font-semibold text-primary">— ${trainerReviews[0].client_name} (⭐ ${trainerReviews[0].rating})</span>
                  </div>
                ` : `
                  <div class="text-xs text-subtle">No client reviews yet. Be the first to leave a review!</div>
                `}
              </div>

              <!-- Footer CTA -->
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

      <!-- Unverified Trainer Direct Code Notice -->
      <div class="card" style="padding: 0.85rem; background: var(--bg-surface-elevated); border-style: dashed;">
        <div class="text-xs text-muted">
          ℹ️ <strong>Unverified Trainer Access</strong>: Independent trainers without admin verification (e.g. Leo Novak) do not appear in public search, but clients can connect instantly using their direct trainer code (e.g. <code>LEO007</code>).
        </div>
      </div>
    </div>
  `;
}
