// src/utils/notificationService.js

/**
 * Notification Service for Karmic Canteen
 * Handles browser notifications for meal reminders and confirmations
 */

class NotificationService {
  constructor() {
    this.permission = Notification.permission;
    this.reminderTime = { hour: 8, minute: 0 }; // 8:00 AM
  }

  /**
   * Check if browser supports notifications
   */
  isSupported() {
    return 'Notification' in window;
  }

  /**
   * Request notification permission from user
   */
  async requestPermission() {
    if (!this.isSupported()) {
      console.warn('Browser does not support notifications');
      return false;
    }

    if (this.permission === 'granted') {
      return true;
    }

    try {
      const permission = await Notification.requestPermission();
      this.permission = permission;
      return permission === 'granted';
    } catch (error) {
      console.error('Error requesting notification permission:', error);
      return false;
    }
  }

  /**
   * Show a notification
   */
  showNotification(title, options = {}) {
    if (!this.isSupported() || this.permission !== 'granted') {
      console.warn('Notifications not available or not permitted');
      return null;
    }

    const defaultOptions = {
      icon: '/vite.svg', // You can replace with your app icon
      badge: '/vite.svg',
      vibrate: [200, 100, 200],
      requireInteraction: false,
      ...options
    };

    try {
      const notification = new Notification(title, defaultOptions);
      
      // Auto-close after 10 seconds if not interacted with
      setTimeout(() => {
        notification.close();
      }, 10000);

      return notification;
    } catch (error) {
      console.error('Error showing notification:', error);
      return null;
    }
  }

  /**
   * Check if user is working from office
   */
  isWorkingFromOffice() {
    const workingMode = localStorage.getItem('workingMode');
    return workingMode === 'office';
  }

  /**
   * Show morning reminder notification (only for office workers)
   */
  showMorningReminder(hasMenu = true) {
    // Only show notifications to office workers
    if (!this.isWorkingFromOffice()) {
      console.log('Notification skipped: User is not working from office');
      return null;
    }

    const title = '🍽️ Karmic Canteen Reminder';
    const body = hasMenu
      ? "Good morning! Don't forget to select your meals for tomorrow. Deadline is approaching!"
      : "Good morning! The menu for tomorrow hasn't been published yet. Check back later!";

    return this.showNotification(title, {
      body,
      tag: 'morning-reminder',
      icon: '/vite.svg',
      requireInteraction: true,
      actions: [
        { action: 'view', title: 'View Menu' },
        { action: 'dismiss', title: 'Dismiss' }
      ]
    });
  }

  /**
   * Show meal selection confirmation notification
   */
  showConfirmationNotification(selectedMeals) {
    const mealCount = selectedMeals.filter(Boolean).length;
    const mealNames = [];
    
    if (selectedMeals.breakfast) mealNames.push('Breakfast');
    if (selectedMeals.lunch) mealNames.push('Lunch');
    if (selectedMeals.snacks) mealNames.push('Snacks');

    const title = '✅ Meal Selection Confirmed';
    const body = mealCount > 0
      ? `You've selected ${mealCount} meal(s): ${mealNames.join(', ')}. Enjoy your meal tomorrow!`
      : 'Your meal preferences have been saved. You have not selected any meals.';

    return this.showNotification(title, {
      body,
      tag: 'meal-confirmation',
      icon: '/vite.svg',
      requireInteraction: false
    });
  }

  /**
   * Show deadline warning notification (only for office workers)
   */
  showDeadlineWarning(timeRemaining) {
    // Only show notifications to office workers
    if (!this.isWorkingFromOffice()) {
      console.log('Notification skipped: User is not working from office');
      return null;
    }

    const title = '⏰ Deadline Approaching!';
    const body = `Only ${timeRemaining} left to select your meals for tomorrow. Don't miss out!`;

    return this.showNotification(title, {
      body,
      tag: 'deadline-warning',
      icon: '/vite.svg',
      requireInteraction: true
    });
  }

  /**
   * Schedule morning reminder
   * Returns timeout ID that can be cleared
   */
  scheduleMorningReminder(callback) {
    const now = new Date();
    const scheduledTime = new Date();
    scheduledTime.setHours(this.reminderTime.hour, this.reminderTime.minute, 0, 0);

    // If time has passed today, schedule for tomorrow
    if (now > scheduledTime) {
      scheduledTime.setDate(scheduledTime.getDate() + 1);
    }

    const timeUntilReminder = scheduledTime - now;

    console.log(`Morning reminder scheduled for: ${scheduledTime.toLocaleString()}`);

    const timeoutId = setTimeout(() => {
      callback();
      // Reschedule for next day
      this.scheduleMorningReminder(callback);
    }, timeUntilReminder);

    return timeoutId;
  }

  /**
   * Check if it's time for morning reminder (for testing)
   */
  shouldShowMorningReminder() {
    const now = new Date();
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();

    // Show reminder at 8:00 AM (within 1 minute window)
    return currentHour === this.reminderTime.hour && currentMinute === this.reminderTime.minute;
  }

  /**
   * Calculate time until next reminder
   */
  getTimeUntilNextReminder() {
    const now = new Date();
    const scheduledTime = new Date();
    scheduledTime.setHours(this.reminderTime.hour, this.reminderTime.minute, 0, 0);

    if (now > scheduledTime) {
      scheduledTime.setDate(scheduledTime.getDate() + 1);
    }

    const diff = scheduledTime - now;
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));

    return { hours, minutes, totalMs: diff };
  }

  /**
   * Save notification preferences to localStorage
   */
  savePreferences(preferences) {
    localStorage.setItem('notificationPreferences', JSON.stringify(preferences));
  }

  /**
   * Load notification preferences from localStorage
   */
  loadPreferences() {
    const saved = localStorage.getItem('notificationPreferences');
    return saved ? JSON.parse(saved) : {
      morningReminder: true,
      confirmationNotification: true,
      deadlineWarning: true
    };
  }

  /**
   * Clear all scheduled notifications
   */
  clearScheduledNotifications(timeoutIds = []) {
    timeoutIds.forEach(id => clearTimeout(id));
  }
}

// Export singleton instance
export const notificationService = new NotificationService();
export default notificationService;
