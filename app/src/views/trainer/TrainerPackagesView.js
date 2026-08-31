// Trainer Package Management View

import { store } from '../../state/store.js';

export function renderTrainerPackagesView() {
  const state = store.getState();
  const packages = state.packages;

  return `
    <div class="animate-fade-in flex flex-col gap-4">
      <div class="flex justify-between items-center">
        <div>
          <h2 class="text-2xl font-extrabold">Packages & Pricing</h2>
          <p class="text-xs text-muted">Manage training packages, session counts, and validity rules.</p>
        </div>
        <button class="btn btn-primary btn-sm" onclick="window.openPackageBuilderModal()">
          + New Package
        </button>
      </div>

      <!-- Rule Adherence 3: Suggested 4x formula with custom validity notice -->
      <div class="card" style="background: rgba(16, 185, 129, 0.08); border-color: rgba(16, 185, 129, 0.3); padding: 0.85rem;">
        <div class="flex items-center gap-2">
          <span style="font-size: 1.2rem;">💡</span>
          <div class="text-xs text-muted">
            <strong class="text-primary">Flexible Validity Rule</strong>: The system suggests <code>Sessions × 4</code> as standard validity, but you can set custom days (e.g. 30, 45, 60, 90 days) for any package.
          </div>
        </div>
      </div>

      <!-- Active Packages List -->
      <div class="flex flex-col gap-3">
        ${packages.map(pkg => `
          <div class="package-card card-glow">
            <div class="flex justify-between items-start">
              <div>
                <div class="font-bold text-base">${pkg.name}</div>
                <div class="text-xs text-muted">
                  ${pkg.sessions} PT Sessions • <strong>${pkg.validity_days} Days Validity</strong>
                </div>
              </div>
              <div class="package-price">$${pkg.price}</div>
            </div>

            <p class="text-xs text-muted">${pkg.description}</p>

            <div class="flex justify-between items-center text-xs text-muted" style="padding-top: 0.5rem; border-top: 1px solid var(--border-color);">
              <span>Validity Mode: <strong>${pkg.validity_mode}</strong></span>
              <span class="badge badge-primary">ACTIVE</span>
            </div>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}
