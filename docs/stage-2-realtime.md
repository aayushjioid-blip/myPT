# FitTrainer (myPT) — Stage 2 Realtime Synchronization Specification

**Project:** FitTrainer (Fitness Trainer Platform)  
**Realtime Engine:** Supabase Realtime Channels (`postgres_changes`)  
**Date:** August 31, 2026  

---

## 1. Realtime Channel Subscriptions

FitTrainer implements live WebSocket listeners for instant client-coach synchronization:

1. **In-App Notifications Channel:**
   ```dart
   _client.channel('public:notifications:user_id=eq.$userId')
     .onPostgresChanges(
       event: PostgresChangeEvent.all,
       schema: 'public',
       table: 'notifications',
       filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
       callback: (payload) => _handleNotificationUpdate(payload),
     ).subscribe();
   ```
2. **Session Bookings Channel:** Listens to status transitions (`REQUESTED` $\to$ `CONFIRMED` $\to$ `IN_PROGRESS` $\to$ `COMPLETED`).
3. **Payments & Ledger Channel:** Notifies client on coach payment verification (+10 credits) and session completions (-1 credit).

---

## 2. Lifecycle & Memory Management

- Subscriptions are managed per active user session and automatically unsubscribed upon user logout.
- Duplicate event debounce guards prevent UI flickering on high-frequency changes.
