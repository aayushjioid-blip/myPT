# Flutter State Management Decision & Rationale

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 1.0  
**Phase:** Stage 1.5 — Flutter Foundation  
**Date:** August 31, 2026  

---

## 1. Selected State Management Approach

### Decision: **Provider with `ChangeNotifier` / `ValueNotifier` (MVVM Pattern)**

FitTrainer selects the standard, official **Provider** pattern (`provider: ^6.1.2`) utilizing modular `ChangeNotifier` controllers and Dependency Injection at the root widget tree.

---

## 2. Evaluation of Alternatives & Rationale

| State Management Option | Strengths | Drawbacks | Evaluation for FitTrainer |
| :--- | :--- | :--- | :--- |
| **Provider (`ChangeNotifier`)** | • Official Flutter recommended standard.<br>• Clean separation of UI from business logic (MVVM).<br>• Zero code-generation build steps required.<br>• Direct 1-to-1 mapping with repository dependency injection.<br>• Lightweight and intuitive for mobile & web. | • Manual `notifyListeners()` calls required in view models. | ✅ **SELECTED**: Offers the cleanest path from mock repositories to Supabase without code-generation complexity or heavy boilerplate. |
| **Riverpod** | • Compile-time safety.<br>• No `BuildContext` dependency. | • Higher learning curve and syntax divergence across versions. | ❌ Rejected for Stage 1.5 to maintain simplicity and rapid developer iteration. |
| **BLoC / Cubit** | • Strict event-driven streams.<br>• Predictable state transitions. | • Heavy ceremony (Events, States, Transitions) for straightforward CRUD and UI toggles. | ❌ Rejected due to excessive boilerplate for prototype phase. |

---

## 3. Architecture & Separation of Concerns

Under this model:
1. **Widgets (Views)**: Pure presentation. Consume state via `context.watch<T>()` or `Consumer<T>()`, and dispatch user intents via `context.read<T>().action()`.
2. **Controllers / ViewModels (`ChangeNotifier`)**: Hold UI state, invoke domain use cases/services, and call `notifyListeners()` on state transitions.
3. **Domain Layer**: Completely agnostic of `ChangeNotifier` or Flutter widgets.
4. **Repositories**: Injected via `Provider` at the root of `MaterialApp`.

```
┌─────────────────────────┐
│     Flutter Widget      │  (Builds UI based on ViewModel state)
└───────────┬─────────────┘
            │ context.read<ViewModel>().action()
            ▼
┌─────────────────────────┐
│       ViewModel         │  (Extends ChangeNotifier, manages screen state)
└───────────┬─────────────┘
            │ Calls domain contract
            ▼
┌─────────────────────────┐
│  Abstract Repository    │  (Defines interface: ITrainerRepository)
└───────────┬─────────────┘
            │ Implemented by
            ▼
┌─────────────────────────┐
│ Mock / Supabase Repo    │  (Provides data to ViewModel)
└─────────────────────────┘
```

---

## 4. Transition to Supabase in Stage 2

Because ViewModels depend strictly on **abstract repository interfaces** (`ITrainerRepository`, `IBookingRepository`, `ICreditLedgerRepository`), transitioning to Supabase in Stage 2 involves simply swapping the provider injection in `lib/app.dart`:

```dart
// STAGE 1.5 (Mock Injection):
Provider<ITrainerRepository>(create: (_) => MockTrainerRepository(mockDataStore)),

// STAGE 2 (Supabase Injection):
Provider<ITrainerRepository>(create: (_) => SupabaseTrainerRepository(supabaseClient)),
```

Zero UI widgets or ViewModels will require modification during backend integration.
