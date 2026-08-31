// FitTrainer Reactive State Store

import { initialSeedData } from './seed-data.js';

const STORAGE_KEY = 'fittrainer_stage1_state';

class StateStore {
  constructor() {
    this.listeners = new Set();
    this.state = this.loadState();
  }

  loadState() {
    try {
      if (typeof localStorage !== 'undefined') {
        const saved = localStorage.getItem(STORAGE_KEY);
        if (saved) {
          return JSON.parse(saved);
        }
      }
    } catch (e) {
      console.warn('Could not load saved state from localStorage:', e);
    }
    
    // Default initial state
    return {
      currentUserId: 'usr-client-1', // Start as Client for E2E flow
      currentTheme: 'dark',
      currentTab: 'home',
      activeModal: null, // { type: '...', data: {} }
      ...JSON.parse(JSON.stringify(initialSeedData))
    };
  }

  saveState() {
    try {
      if (typeof localStorage !== 'undefined') {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(this.state));
      }
    } catch (e) {
      console.warn('Could not persist state to localStorage:', e);
    }
  }

  getState() {
    return this.state;
  }

  getCurrentUser() {
    return this.state.users.find(u => u.id === this.state.currentUserId) || this.state.users[0];
  }

  getCurrentTrainerProfile() {
    const user = this.getCurrentUser();
    if (user.role === 'TRAINER') {
      return this.state.trainers.find(t => t.user_id === user.id);
    }
    return null;
  }

  subscribe(listener) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  notify() {
    this.saveState();
    this.listeners.forEach(listener => {
      try {
        listener(this.state);
      } catch (err) {
        console.error('Error in state listener:', err);
      }
    });
  }

  resetToDefaults() {
    this.state = {
      currentUserId: 'usr-client-1',
      currentTheme: 'dark',
      currentTab: 'home',
      activeModal: null,
      ...JSON.parse(JSON.stringify(initialSeedData))
    };
    this.notify();
  }

  setCurrentUser(userId) {
    this.state.currentUserId = userId;
    this.state.currentTab = 'home';
    this.notify();
  }

  setTheme(theme) {
    this.state.currentTheme = theme;
    if (typeof document !== 'undefined') {
      document.documentElement.setAttribute('data-theme', theme);
    }
    this.notify();
  }

  setCurrentTab(tab) {
    this.state.currentTab = tab;
    this.notify();
  }

  openModal(type, data = {}) {
    this.state.activeModal = { type, data };
    this.notify();
  }

  closeModal() {
    this.state.activeModal = null;
    this.notify();
  }
}

export const store = new StateStore();
