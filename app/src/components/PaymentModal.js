// Offline Payment Modal Component (MVP Manual Verification Flow)

import { store } from '../state/store.js';

export function renderPaymentModal(data = {}) {
  const state = store.getState();
  const pkg = state.packages.find(p => p.id === data.packageId);
  if (!pkg) return '';

  const trainer = state.trainers.find(t => t.id === pkg.trainer_id) || state.trainers[0];

  return `
    <div class="modal-overlay" onclick="if(event.target === this) window.closeModal()">
      <div class="modal-content animate-slide-up">
        <div class="flex items-center justify-between" style="margin-bottom: 1rem;">
          <h3 style="font-size: 1.15rem;">Complete Payment</h3>
          <button class="btn btn-ghost btn-sm" onclick="window.closeModal()">✕</button>
        </div>

        <!-- Package Summary -->
        <div class="card card-glow" style="margin-bottom: 1rem;">
          <div class="flex justify-between items-start">
            <div>
              <div class="text-xs text-primary font-bold uppercase tracking-wider">Selected Package</div>
              <div class="font-bold text-lg">${pkg.name}</div>
              <div class="text-xs text-muted">${pkg.sessions} Personal Training Sessions • ${pkg.validity_days} Days Validity</div>
            </div>
            <div class="package-price">$${pkg.price}</div>
          </div>
        </div>

        <!-- Trainer Offline Payment Information -->
        <div class="card" style="margin-bottom: 1rem; background: var(--bg-input);">
          <div class="text-xs font-bold text-muted uppercase tracking-wider" style="margin-bottom: 0.5rem;">
            Trainer Payment Details
          </div>
          <div class="flex flex-col gap-2">
            <div class="flex justify-between items-center text-sm">
              <span class="text-muted">UPI ID:</span>
              <span class="font-mono font-bold text-primary" style="background: rgba(16, 185, 129, 0.1); padding: 2px 8px; border-radius: 4px;">
                ${trainer.upi_id || 'alex.rivera@upi'}
              </span>
            </div>
            <div class="flex justify-between items-center text-sm">
              <span class="text-muted">Mobile / GPay / PhonePe:</span>
              <span class="font-mono font-semibold">${trainer.mobile_payment_number || '+1-555-8822'}</span>
            </div>
            <div class="flex justify-between items-center text-sm">
              <span class="text-muted">Account Holder:</span>
              <span class="font-semibold">${trainer.name}</span>
            </div>
          </div>
        </div>

        <div class="badge badge-amber" style="width: 100%; justify-content: center; margin-bottom: 1rem; padding: 0.5rem;">
          ⚠️ Pay externally, then submit your transaction reference below.
        </div>

        <form id="payment-form" onsubmit="window.submitMockPayment(event, '${pkg.id}')">
          <div class="form-group">
            <label class="form-label">UPI UTR / Bank Transaction Reference</label>
            <input 
              type="text" 
              class="input font-mono" 
              id="payment-ref" 
              placeholder="e.g. UPI-9847291823" 
              value="UPI-${Math.floor(1000000 + Math.random() * 9000000)}" 
              required />
          </div>

          <div class="flex gap-2" style="margin-top: 1.25rem;">
            <button type="button" class="btn btn-secondary flex-1" onclick="window.closeModal()">Cancel</button>
            <button type="submit" class="btn btn-primary flex-1">I Have Paid ✅</button>
          </div>
        </form>
      </div>
    </div>
  `;
}
