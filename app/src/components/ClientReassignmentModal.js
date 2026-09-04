// FitTrainer Client Reassignment Modal (Milestones 4 & 5)

import { store } from '../state/store.js';

export function renderClientReassignmentModal(data = {}) {
  const state = store.getState();
  const rel = state.relationships.find(r => r.id === data.relationshipId) || state.relationships[0];
  const client = rel ? state.users.find(u => u.id === rel.client_id) : { name: 'Sarah Jenkins' };
  const currentTrainer = rel ? state.trainers.find(t => t.id === rel.trainer_id) : state.trainers[0];
  const staffTrainers = state.trainers;

  return `
    <div class="modal-backdrop animate-fade-in" onclick="if(event.target === this) window.closeModal()">
      <div class="modal-content" style="max-width: 480px;">
        <div class="flex justify-between items-center" style="margin-bottom: 1rem;">
          <div class="flex items-center gap-2">
            <span style="font-size: 1.3rem;">👑</span>
            <div class="font-extrabold text-base">Reassign Client Trainer</div>
          </div>
          <button class="btn btn-secondary btn-sm" onclick="window.closeModal()">✕</button>
        </div>

        <div class="card" style="background: rgba(139, 92, 246, 0.08); border-color: rgba(139, 92, 246, 0.3); padding: 0.85rem; margin-bottom: 1rem;">
          <div class="text-xs text-muted">
            <strong class="text-purple">Head Trainer / Gym Authority</strong>: Clients cannot independently switch trainers. Reassignment transfers active packages, remaining credits, and historical workout logs securely.
          </div>
        </div>

        <form id="reassign-form" onsubmit="window.submitClientReassignment(event, '${rel ? rel.id : ''}')">
          <div class="card" style="padding: 0.75rem; background: var(--bg-input); margin-bottom: 1rem;">
            <div class="text-xs text-muted">Client to Transfer:</div>
            <div class="font-bold text-sm" style="margin-top: 2px;">${client?.name || 'Sarah Jenkins'} (${client?.email || ''})</div>
            <div class="text-xs text-muted" style="margin-top: 4px;">
              Current Assigned Trainer: <strong>${currentTrainer?.name || 'Alex Rivera'}</strong>
            </div>
          </div>

          <div class="form-group">
            <label class="form-label">Select New Assigned Trainer *</label>
            <select class="input" id="reassign-new-trainer" required>
              ${staffTrainers.map(t => `
                <option value="${t.id}" ${t.id === currentTrainer?.id ? 'disabled' : ''}>
                  ${t.name} (${t.specializations.join(', ')}) ${t.id === currentTrainer?.id ? '(Current)' : ''}
                </option>
              `).join('')}
            </select>
          </div>

          <div class="form-group">
            <label class="form-label">Reassignment Reason / Note *</label>
            <select class="input" id="reassign-reason" required>
              <option value="Trainer Temporary Leave / Unavailability">Trainer Temporary Leave / Unavailability</option>
              <option value="Client Goal Specialization Match (Mobility/Rehab)">Client Goal Specialization Match (Mobility/Rehab)</option>
              <option value="Schedule Timetable Optimization">Schedule Timetable Optimization</option>
              <option value="Head Trainer Routine Rotation">Head Trainer Routine Rotation</option>
            </select>
          </div>

          <div class="flex gap-2" style="margin-top: 1rem;">
            <button type="button" class="btn btn-secondary flex-1" onclick="window.closeModal()">Cancel</button>
            <button type="submit" class="btn btn-primary flex-1 font-bold">
              Execute Reassignment ➔
            </button>
          </div>
        </form>
      </div>
    </div>
  `;
}
