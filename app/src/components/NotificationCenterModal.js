// FitTrainer Notification Centre Modal (Milestone 7)

import { store } from '../state/store.js';

export function renderNotificationCenterModal() {
  const state = store.getState();
  const user = store.getCurrentUser();
  const userNotifs = state.notifications.filter(n => n.user_id === user.id);
  const unreadCount = userNotifs.filter(n => !n.read).length;

  return `
    <div class="modal-backdrop animate-fade-in" onclick="if(event.target === this) window.closeModal()">
      <div class="modal-content" style="max-width: 480px; max-height: 85vh; display: flex; flex-direction: column;">
        <div class="flex justify-between items-center" style="margin-bottom: 0.75rem;">
          <div class="flex items-center gap-2">
            <span style="font-size: 1.3rem;">🔔</span>
            <div class="font-extrabold text-base">Notification Centre</div>
            ${unreadCount > 0 ? `<span class="badge badge-rose font-bold">${unreadCount} New</span>` : ''}
          </div>
          <button class="btn btn-secondary btn-sm" onclick="window.closeModal()">✕</button>
        </div>

        <div class="flex justify-between items-center" style="margin-bottom: 0.75rem;">
          <span class="text-xs text-muted">In-app activity feed and instant platform updates.</span>
          ${unreadCount > 0 ? `
            <button class="btn btn-secondary btn-sm" style="font-size: 0.65rem; padding: 2px 8px;" onclick="window.markAllRead()">
              Mark all read ✓
            </button>
          ` : ''}
        </div>

        <!-- Notification Feed List -->
        <div class="flex flex-col gap-2" style="overflow-y: auto; flex: 1; padding: 0.25rem;">
          ${userNotifs.length > 0 ? userNotifs.map(n => {
            const icon = 
              n.type === 'BOOKING' ? '📅' :
              n.type === 'PAYMENT' ? '💳' :
              n.type === 'WORKOUT' ? '💪' :
              n.type === 'REVIEW' ? '⭐' :
              n.type === 'WARNING' ? '⚠️' :
              n.type === 'PROGRESS' ? '📊' :
              n.type === 'MANAGEMENT' ? '👑' : '🔔';

            return `
              <div 
                class="card ${!n.read ? 'card-glow' : ''}" 
                style="padding: 0.75rem; background: ${!n.read ? 'var(--bg-surface)' : 'var(--bg-input)'}; border-left: 3px solid ${!n.read ? 'var(--color-primary)' : 'transparent'};"
                onclick="window.markNotifRead('${n.id}')">
                <div class="flex justify-between items-start" style="margin-bottom: 0.25rem;">
                  <div class="flex items-center gap-2">
                    <span>${icon}</span>
                    <span class="font-bold text-xs ${!n.read ? 'text-primary' : ''}">${n.title}</span>
                  </div>
                  <span class="text-xs text-subtle font-mono" style="font-size: 0.65rem;">
                    ${new Date(n.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </span>
                </div>
                <p class="text-xs text-muted" style="margin-left: 1.5rem; line-height: 1.35;">
                  ${n.message}
                </p>
              </div>
            `;
          }).join('') : `
            <div class="card" style="padding: 2rem; text-align: center;">
              <div style="font-size: 1.8rem; margin-bottom: 0.5rem;">✨</div>
              <div class="font-bold text-sm">All Caught Up!</div>
              <div class="text-xs text-muted">You have no unread alerts or notifications.</div>
            </div>
          `}
        </div>

        <div style="margin-top: 1rem;">
          <button class="btn btn-secondary btn-full btn-sm" onclick="window.closeModal()">Close Feed</button>
        </div>
      </div>
    </div>
  `;
}
