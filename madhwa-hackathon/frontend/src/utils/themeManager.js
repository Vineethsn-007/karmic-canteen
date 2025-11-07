/**
 * Theme Manager - Dark/Light Mode Toggle
 * Manages theme persistence and transitions
 */

const THEME_STORAGE_KEY = 'karmic-canteen-theme';
const SYSTEM_PREFERS_DARK = window.matchMedia('(prefers-color-scheme: dark)').matches;

export const themeManager = {
  /**
   * Initialize theme on page load
   */
  init: () => {
    const savedTheme = localStorage.getItem(THEME_STORAGE_KEY);
    const theme = savedTheme || (SYSTEM_PREFERS_DARK ? 'dark' : 'light');
    themeManager.setTheme(theme);
  },

  /**
   * Get current theme
   */
  getCurrentTheme: () => {
    return document.documentElement.getAttribute('data-theme') || 'dark';
  },

  /**
   * Set theme with smooth transition
   */
  setTheme: (theme) => {
    const root = document.documentElement;
    const body = document.body;

    // Remove previous theme attribute if it exists
    root.removeAttribute('data-theme');

    // Set theme only if it's light (dark is default)
    if (theme === 'light') {
      root.setAttribute('data-theme', 'light');
    }

    // Add transition class for smooth color change
    body.classList.add('theme-transitioning');
    setTimeout(() => {
      body.classList.remove('theme-transitioning');
    }, 300);

    // Persist theme preference
    localStorage.setItem(THEME_STORAGE_KEY, theme);
  },

  /**
   * Toggle between dark and light
   */
  toggleTheme: () => {
    const currentTheme = themeManager.getCurrentTheme();
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    themeManager.setTheme(newTheme);
    return newTheme;
  },

  /**
   * Reset to system preference
   */
  resetToSystemPreference: () => {
    localStorage.removeItem(THEME_STORAGE_KEY);
    const systemTheme = SYSTEM_PREFERS_DARK ? 'dark' : 'light';
    themeManager.setTheme(systemTheme);
  }
};

export default themeManager;
