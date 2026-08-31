// Trainer Package Builder Modal (Supports 4x suggestion and custom validity)

export function renderPackageBuilderModal() {
  return `
    <div class="modal-overlay" onclick="if(event.target === this) window.closeModal()">
      <div class="modal-content animate-slide-up">
        <div class="flex items-center justify-between" style="margin-bottom: 1rem;">
          <h3 style="font-size: 1.15rem;">Create Custom Package</h3>
          <button class="btn btn-ghost btn-sm" onclick="window.closeModal()">✕</button>
        </div>

        <form id="create-package-form" onsubmit="window.submitCreatePackage(event)">
          <div class="form-group">
            <label class="form-label">Package Title</label>
            <input type="text" class="input" id="pkg-name" placeholder="e.g. 10 PT Sessions Elite" required />
          </div>

          <div class="form-group">
            <label class="form-label">Description</label>
            <textarea class="input" id="pkg-desc" rows="2" placeholder="Describe inclusions, goal focus, or nutrition support..."></textarea>
          </div>

          <div class="stat-grid" style="margin-bottom: 1rem;">
            <div class="form-group" style="margin:0;">
              <label class="form-label">Number of Sessions</label>
              <input 
                type="number" 
                class="input" 
                id="pkg-sessions" 
                value="10" 
                min="1" 
                max="100" 
                oninput="window.updateSuggestedValidity(this.value)"
                required />
            </div>

            <div class="form-group" style="margin:0;">
              <label class="form-label">Price ($ USD)</label>
              <input type="number" class="input" id="pkg-price" value="500" min="0" step="10" required />
            </div>
          </div>

          <!-- Validity Section with Rule Adherence: Suggests 4x but allows custom -->
          <div class="card" style="margin-bottom: 1.25rem; background: var(--bg-input);">
            <div class="flex justify-between items-center" style="margin-bottom: 0.5rem;">
              <label class="form-label" style="margin:0;">Validity Duration (Days)</label>
              <span class="badge badge-primary" id="pkg-validity-suggested-tag">Suggested: 40 Days (4x)</span>
            </div>
            
            <input type="number" class="input" id="pkg-validity" value="40" min="1" max="365" required />
            
            <div class="text-xs text-muted" style="margin-top: 0.4rem;">
              💡 4x sessions is suggested as standard, but you can enter any custom days (e.g. 30, 45, 60, 90).
            </div>
          </div>

          <div class="flex gap-2">
            <button type="button" class="btn btn-secondary flex-1" onclick="window.closeModal()">Cancel</button>
            <button type="submit" class="btn btn-primary flex-1">Save Package 🏷️</button>
          </div>
        </form>
      </div>
    </div>
  `;
}
