// src/components/Employee/EmployeeDashboard.jsx
import React, { useState, useEffect } from 'react';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { db } from '../../firebase/config';
import { useAuth } from '../../context/AuthContext';
import { useTranslation } from 'react-i18next';
import notificationService from '../../utils/notificationService';
import WorkingModeSelector from './WorkingModeSelector';
import WorkingFromHome from './WorkingFromHome';
import WeeklyMealSelector from './WeeklyMealSelector';
import './EmployeeDashboard.css';

const EmployeeDashboard = () => {
  const { currentUser } = useAuth();
  const { t } = useTranslation();
  const [menu, setMenu] = useState(null);
  const [selections, setSelections] = useState({
    breakfast: false,
    lunch: false,
    snacks: false,
    dinner: false
  });
  const [savedSelections, setSavedSelections] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [deadlinePassed, setDeadlinePassed] = useState(false);
  const [message, setMessage] = useState({ type: '', text: '' });
  const [currentTime, setCurrentTime] = useState(new Date());
  const [deadlineHour, setDeadlineHour] = useState(21);
  const [deadlineMinute, setDeadlineMinute] = useState(0);
  const [notificationPermission, setNotificationPermission] = useState('default');
  const [showNotificationBanner, setShowNotificationBanner] = useState(false);
  const [reminderScheduled, setReminderScheduled] = useState(false);
  const [showSuccessPopup, setShowSuccessPopup] = useState(false);
  const [workingMode, setWorkingMode] = useState(null); // 'office' or 'home'
  const [showModeSelector, setShowModeSelector] = useState(false);
  const [showDeadlineWarning, setShowDeadlineWarning] = useState(false);
  const [warningShown, setWarningShown] = useState(false);
  const [viewMode, setViewMode] = useState('daily'); // 'daily' or 'weekly'

  useEffect(() => {
    fetchDeadlineSettings();
    fetchTomorrowMenu();
    loadUserSelections();
    loadWorkingMode();
    initializeNotifications();
  }, []);

  useEffect(() => {
    checkDeadline();

    // Update time every minute
    const timer = setInterval(() => {
      const now = new Date();
      setCurrentTime(now);
      checkDeadline();
      
      // Check if it's midnight (00:00) to refresh the menu for the new day
      if (now.getHours() === 0 && now.getMinutes() === 0) {
        console.log('Midnight detected - refreshing menu for new day');
        fetchTomorrowMenu();
        loadUserSelections();
        loadWorkingMode();
      }
    }, 60000);

    return () => clearInterval(timer);
  }, [deadlineHour, deadlineMinute]);

  const getTomorrowDate = () => {
    // Always get fresh date to ensure it updates at midnight
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dateStr = tomorrow.toISOString().split('T')[0];
    console.log('Tomorrow date:', dateStr); // Debug log
    return dateStr;
  };

  const formatDate = (dateStr) => {
    // Parse the date string as local time to avoid timezone issues
    const [year, month, day] = dateStr.split('-').map(Number);
    const date = new Date(year, month - 1, day);
    return date.toLocaleDateString('en-US', { 
      weekday: 'long', 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric' 
    });
  };

  const fetchDeadlineSettings = async () => {
    try {
      const settingsRef = doc(db, 'settings', 'deadline');
      const settingsSnap = await getDoc(settingsRef);

      if (settingsSnap.exists()) {
        const data = settingsSnap.data();
        setDeadlineHour(data.deadlineHour || 21);
        setDeadlineMinute(data.deadlineMinute || 0);
      }
    } catch (error) {
      console.error('Error fetching deadline settings:', error);
      // Use default values if fetch fails
    }
  };

  const checkDeadline = () => {
    const now = new Date();
    const hours = now.getHours();
    const minutes = now.getMinutes();
    const currentMinutes = hours * 60 + minutes;
    const deadlineMinutes = deadlineHour * 60 + deadlineMinute;

    setDeadlinePassed(currentMinutes >= deadlineMinutes);

    // Show warning 10 minutes before deadline
    const tenMinutesBeforeDeadline = deadlineMinutes - 10;
    if (currentMinutes >= tenMinutesBeforeDeadline && currentMinutes < deadlineMinutes && !warningShown && !deadlinePassed) {
      setShowDeadlineWarning(true);
      setWarningShown(true);
    }
  };

  const getTimeUntilDeadline = () => {
    const now = new Date();
    const deadline = new Date();
    deadline.setHours(deadlineHour, deadlineMinute, 0, 0);

    if (now > deadline) {
      return t('dashboard.deadlinePassed');
    }

    const diff = deadline - now;
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));

    return t('dashboard.remaining', { hours, minutes });
  };

  const fetchTomorrowMenu = async () => {
    try {
      const tomorrow = getTomorrowDate();
      const today = new Date().toISOString().split('T')[0];
      
      // First try to get tomorrow's menu
      const menuRef = doc(db, 'menus', tomorrow);
      const menuSnap = await getDoc(menuRef);

      if (menuSnap.exists()) {
        const menuData = menuSnap.data();
        // Ensure we only show the menu if it's for tomorrow
        if (menuData.date === tomorrow) {
          setMenu(menuData);
          setLoading(false);
          return;
        }
      }
      
      // If we get here, either there's no menu for tomorrow or it's not valid
      // Check if we're accidentally showing today's menu
      const todayMenuRef = doc(db, 'menus', today);
      const todayMenuSnap = await getDoc(todayMenuRef);
      
      if (todayMenuSnap.exists() && todayMenuSnap.data().date === today) {
        console.log('Found today\'s menu but not tomorrow\'s');
      }
      
      // Set menu to null if no valid menu found
      setMenu(null);
      
      // Show appropriate message
      showMessage('info', 'No menu available for tomorrow yet. Please check back later.');
      
    } catch (error) {
      console.error('Error fetching menu:', error);
      showMessage('error', 'Failed to load menu. Please try again later.');
    } finally {
      setLoading(false);
    }
  };

  const loadUserSelections = async () => {
    try {
      const tomorrow = getTomorrowDate();
      const selectionRef = doc(db, 'mealSelections', tomorrow, 'users', currentUser.uid);
      const selectionSnap = await getDoc(selectionRef);

      if (selectionSnap.exists()) {
        const data = selectionSnap.data();
        // Only update if the selection is for tomorrow
        if (data.date === tomorrow) {
          setSelections({
            breakfast: data.breakfast || false,
            lunch: data.lunch || false,
            snacks: data.snacks || false,
            dinner: data.dinner || false
          });
          setSavedSelections({
            breakfast: data.breakfast || false,
            lunch: data.lunch || false,
            snacks: data.snacks || false,
            dinner: data.dinner || false
          });
        } else {
          // If we have old data, reset to default
          resetSelections();
        }
      } else {
        // No selections exist yet, initialize with defaults
        resetSelections();
      }
    } catch (error) {
      console.error('Error loading selections:', error);
    }
  };

  // Load working mode from Firestore
  const loadWorkingMode = async () => {
    try {
      const tomorrow = getTomorrowDate();
      const modeRef = doc(db, 'workingModes', tomorrow, 'users', currentUser.uid);
      const modeSnap = await getDoc(modeRef);

      if (modeSnap.exists()) {
        setWorkingMode(modeSnap.data().mode);
      } else {
        // Show mode selector if not set
        setShowModeSelector(true);
      }
    } catch (error) {
      console.error('Error loading working mode:', error);
      setShowModeSelector(true);
    }
  };

  // Save working mode to Firestore
  const handleModeSelect = async (mode) => {
    try {
      const tomorrow = getTomorrowDate();
      const modeRef = doc(db, 'workingModes', tomorrow, 'users', currentUser.uid);
      
      await setDoc(modeRef, {
        mode: mode,
        userId: currentUser.uid,
        userEmail: currentUser.email,
        timestamp: new Date().toISOString(),
        date: tomorrow
      });

      setWorkingMode(mode);
      setShowModeSelector(false);
      
      if (mode === 'office') {
        showMessage('success', 'Working mode set to Office. You can now select your meals.');
      }
    } catch (error) {
      console.error('Error saving working mode:', error);
      showMessage('error', 'Failed to save working mode. Please try again.');
    }
  };

  // Change working mode
  const handleChangeModeClick = () => {
    if (!deadlinePassed) {
      setShowModeSelector(true);
    }
  };

  const handleMealToggle = (mealType) => {
    if (deadlinePassed) {
      const deadlineTime = formatDeadlineTime();
      showMessage('error', t('dashboard.deadlinePassed'));
      return;
    }

    setSelections(prev => ({
      ...prev,
      [mealType]: !prev[mealType]
    }));
  };

  const formatDeadlineTime = () => {
    const h = parseInt(deadlineHour);
    const m = parseInt(deadlineMinute);
    const period = h >= 12 ? 'PM' : 'AM';
    const displayHour = h === 0 ? 12 : h > 12 ? h - 12 : h;
    return `${displayHour}:${m.toString().padStart(2, '0')} ${period}`;
  };

  // Notification Functions
  const initializeNotifications = async () => {
    if (!notificationService.isSupported()) {
      console.log('Notifications not supported in this browser');
      return;
    }

    const currentPermission = Notification.permission;
    setNotificationPermission(currentPermission);

    // Show banner if permission not yet requested
    if (currentPermission === 'default') {
      setShowNotificationBanner(true);
    }

    // If already granted, schedule morning reminder
    if (currentPermission === 'granted') {
      scheduleMorningReminder();
    }
  };

  const requestNotificationPermission = async () => {
    const granted = await notificationService.requestPermission();
    setNotificationPermission(Notification.permission);
    
    if (granted) {
      setShowNotificationBanner(false);
      scheduleMorningReminder();
      showMessage('success', t('notifications.enableReminders'));
    } else {
      showMessage('error', 'Notification permission denied. You can enable it in browser settings.');
    }
  };

  const scheduleMorningReminder = () => {
    if (reminderScheduled) return;

    notificationService.scheduleMorningReminder(() => {
      const hasMenu = menu !== null;
      notificationService.showMorningReminder(hasMenu);
    });

    setReminderScheduled(true);
    console.log('Morning reminder scheduled for 8:00 AM daily');
  };

  const showConfirmationNotification = () => {
    if (notificationPermission === 'granted') {
      notificationService.showConfirmationNotification(selections);
    }
  };

  const handleSubmit = async () => {
    if (deadlinePassed) {
      const deadlineTime = formatDeadlineTime();
      showMessage('error', `Selection deadline has passed (${deadlineTime})`);
      return;
    }

    try {
      setSaving(true);
      const tomorrow = getTomorrowDate();
      const selectionRef = doc(db, 'mealSelections', tomorrow, 'users', currentUser.uid);

      const selectionData = {
        ...selections,
        userId: currentUser.uid,
        email: currentUser.email,
        timestamp: new Date().toISOString(),
        modified: savedSelections !== null
      };

      await setDoc(selectionRef, selectionData);
      setSavedSelections(selections);
      showMessage('success', 'Meal preferences saved successfully!');
      
      // Show success popup
      setShowSuccessPopup(true);
      
      // Show confirmation notification
      showConfirmationNotification();
    } catch (error) {
      console.error('Error saving selections:', error);
      showMessage('error', 'Failed to save preferences. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  const showMessage = (type, text) => {
    setMessage({ type, text });
    setTimeout(() => setMessage({ type: '', text: '' }), 5000);
  };

  const hasChanges = () => {
    if (!savedSelections) return true;
    return (
      selections.breakfast !== savedSelections.breakfast ||
      selections.lunch !== savedSelections.lunch ||
      selections.snacks !== savedSelections.snacks ||
      selections.dinner !== savedSelections.dinner
    );
  };

  const getSelectedCount = () => {
    return Object.values(selections).filter(val => val).length;
  };

  // Reset selections to default values
  const resetSelections = () => {
    const defaultSelections = {
      breakfast: false,
      lunch: false,
      snacks: false,
      dinner: false
    };
    setSelections({...defaultSelections});
    setSavedSelections({...defaultSelections});
  };

  // Meal timings
  const mealTimings = {
    breakfast: { start: '8:30 AM', end: '10:00 AM' },
    lunch: { start: '1:00 PM', end: '2:30 PM' },
    snacks: { start: '5:00 PM', end: '6:30 PM' },
    dinner: { start: '8:00 PM', end: '9:30 PM' }
  };

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Loading menu...</p>
      </div>
    );
  }

  // Show working mode selector if not set
  if (showModeSelector) {
    return (
      <WorkingModeSelector
        onModeSelect={handleModeSelect}
        currentMode={workingMode}
        canChange={!deadlinePassed}
      />
    );
  }

  // Show working from home screen if user selected home
  if (workingMode === 'home') {
    return (
      <WorkingFromHome
        onChangeMode={handleChangeModeClick}
        canChange={!deadlinePassed}
        deadline={formatDeadlineTime()}
      />
    );
  }

  // Show meal selection dashboard for office mode
  return (
    <div className="employee-dashboard">
      <div className="dashboard-header">
        <div>
          <h1>{t('employee.dashboard.title')}</h1>
          <p className="subtitle">{t('employee.dashboard.subtitle')}</p>
        </div>
        <div className="deadline-info">
          <span className={`deadline-badge ${deadlinePassed ? 'expired' : 'active'}`}>
            {deadlinePassed ? '🔒 ' + t('dashboard.deadlinePassed') : `⏰ ${getTimeUntilDeadline()}`}
          </span>
        </div>
      </div>

      {/* Working Mode Indicator */}
      <div className="working-mode-indicator">
        <span className="mode-badge">
          🏢 {t('workingMode.office')}
        </span>
        {!deadlinePassed && (
          <button
            className="btn btn-secondary btn-sm"
            onClick={handleChangeModeClick}
          >
            {t('workingMode.changeToOffice').replace('Office', 'Home')}
          </button>
        )}
      </div>

      {/* Notification Permission Banner */}
      {showNotificationBanner && (
        <div className="notification-banner">
          <div className="notification-banner-content">
            <div className="notification-icon">🔔</div>
            <div className="notification-text">
              <strong>{t('notifications.enable')}</strong>
              <p>{t('notifications.enableReminders')}</p>
            </div>
            <div className="notification-actions">
              <button 
                className="btn btn-primary btn-sm"
                onClick={requestNotificationPermission}
              >
                {t('notifications.enable')}
              </button>
              <button 
                className="btn btn-secondary btn-sm"
                onClick={() => setShowNotificationBanner(false)}
              >
                {t('notifications.maybeLater')}
              </button>
            </div>
          </div>
        </div>
      )}

      {message.text && (
        <div className={`message ${message.type}`}>
          {message.type === 'success' ? '✓' : '⚠'} {message.text}
        </div>
      )}

      <div className="date-card">
        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '15px'}}>
          <h3>📅 {viewMode === 'daily' ? t('dashboard.selectMeals') + ' ' + formatDate(getTomorrowDate()) : 'Weekly Meal Selection'}</h3>
          <div className="view-toggle">
            <button 
              className={`toggle-btn ${viewMode === 'daily' ? 'active' : ''}`}
              onClick={() => setViewMode('daily')}
            >
              📅 Daily
            </button>
            <button 
              className={`toggle-btn ${viewMode === 'weekly' ? 'active' : ''}`}
              onClick={() => setViewMode('weekly')}
            >
              📆 Weekly
            </button>
          </div>
        </div>
      </div>

      {viewMode === 'weekly' ? (
        <WeeklyMealSelector />
      ) : (
        <>
          {!menu ? (
            <div className="no-menu-card">
              <div className="empty-state">
                <span className="empty-icon">🍽️</span>
                <h3>{t('dashboard.noMenu')}</h3>
                <p>{t('dashboard.noMenuText')}</p>
                <p className="small-text">{t('dashboard.contactAdmin')}</p>
              </div>
            </div>
          ) : (
            <>
          <div className="meals-grid">
            {/* Breakfast Card */}
            <div className={`meal-card ${selections.breakfast ? 'selected' : ''}`}>
              <div className="meal-header">
                <div style={{display: 'flex', alignItems: 'center', gap: '12px'}}>
                  <div className="meal-icon">☕</div>
                  <h3>{t('dashboard.breakfast')}</h3>
                </div>
                <div className="meal-timing">
                  🕐 {mealTimings.breakfast.start} - {mealTimings.breakfast.end}
                </div>
              </div>
              
              <div className="menu-items">
                {menu.breakfast && menu.breakfast.length > 0 ? (
                  menu.breakfast.map((item, index) => (
                    <div key={index} className="menu-item">
                      <span className="item-bullet">•</span>
                      <span>{item}</span>
                    </div>
                  ))
                ) : (
                  <p className="no-items">{t('dashboard.noItems')}</p>
                )}
              </div>

              <button
                className={`meal-toggle-btn ${selections.breakfast ? 'active' : ''}`}
                onClick={() => handleMealToggle('breakfast')}
                disabled={deadlinePassed || !menu.breakfast || menu.breakfast.length === 0}
              >
                {selections.breakfast ? 'Remove' : 'Select'}
              </button>
            </div>

            {/* Lunch Card */}
            <div className={`meal-card ${selections.lunch ? 'selected' : ''}`}>
              <div className="meal-header">
                <div style={{display: 'flex', alignItems: 'center', gap: '12px'}}>
                  <div className="meal-icon">🍛</div>
                  <h3>{t('dashboard.lunch')}</h3>
                </div>
                <div className="meal-timing">
                  🕐 {mealTimings.lunch.start} - {mealTimings.lunch.end}
                </div>
              </div>
              
              <div className="menu-items">
                {menu.lunch && menu.lunch.length > 0 ? (
                  menu.lunch.map((item, index) => (
                    <div key={index} className="menu-item">
                      <span className="item-bullet">•</span>
                      <span>{item}</span>
                    </div>
                  ))
                ) : (
                  <p className="no-items">{t('dashboard.noItems')}</p>
                )}
              </div>

              <button
                className={`meal-toggle-btn ${selections.lunch ? 'active' : ''}`}
                onClick={() => handleMealToggle('lunch')}
                disabled={deadlinePassed || !menu.lunch || menu.lunch.length === 0}
              >
                {selections.lunch ? 'Remove' : 'Select'}
              </button>
            </div>

            {/* Snacks Card */}
            <div className={`meal-card ${selections.snacks ? 'selected' : ''}`}>
              <div className="meal-header">
                <div style={{display: 'flex', alignItems: 'center', gap: '12px'}}>
                  <div className="meal-icon">🍪</div>
                  <h3>{t('dashboard.snacks')}</h3>
                </div>
                <div className="meal-timing">
                  🕐 {mealTimings.snacks.start} - {mealTimings.snacks.end}
                </div>
              </div>
              
              <div className="menu-items">
                {menu.snacks && menu.snacks.length > 0 ? (
                  menu.snacks.map((item, index) => (
                    <div key={index} className="menu-item">
                      <span className="item-bullet">•</span>
                      <span>{item}</span>
                    </div>
                  ))
                ) : (
                  <p className="no-items">{t('dashboard.noItems')}</p>
                )}
              </div>

              <button
                className={`meal-toggle-btn ${selections.snacks ? 'active' : ''}`}
                onClick={() => handleMealToggle('snacks')}
                disabled={deadlinePassed || !menu.snacks || menu.snacks.length === 0}
              >
                {selections.snacks ? 'Remove' : 'Select'}
              </button>
            </div>

            {/* Dinner Card */}
            <div className={`meal-card ${selections.dinner ? 'selected' : ''}`}>
              <div className="meal-header">
                <div style={{display: 'flex', alignItems: 'center', gap: '12px'}}>
                  <div className="meal-icon">🍽️</div>
                  <h3>{t('Dinner')}</h3>
                </div>
                <div className="meal-timing">
                  🕐 {mealTimings.dinner.start} - {mealTimings.dinner.end}
                </div>
              </div>
              
              <div className="menu-items">
                {menu.dinner && menu.dinner.length > 0 ? (
                  menu.dinner.map((item, index) => (
                    <div key={index} className="menu-item">
                      <span className="item-bullet">•</span>
                      <span>{item}</span>
                    </div>
                  ))
                ) : (
                  <p className="no-items">{t('dashboard.noItems')}</p>
                )}
              </div>

              <button
                className={`meal-toggle-btn ${selections.dinner ? 'active' : ''}`}
                onClick={() => handleMealToggle('dinner')}
                disabled={deadlinePassed || !menu.dinner || menu.dinner.length === 0}
              >
                {selections.dinner ? 'Remove' : 'Select'}
              </button>
            </div>
          </div>

          <div className="summary-section">
            <div className="summary-card">
              <h3>{t('dashboard.summary')}</h3>
              <div className="summary-stats">
                <div className="stat">
                  <span className="stat-label">{t('dashboard.mealsSelected')}</span>
                  <span className="stat-value">{getSelectedCount()} / 4</span>
                </div>
                {savedSelections && (
                  <div className="stat">
                    <span className="stat-label">{t('dashboard.status')}</span>
                    <span className={`stat-value ${hasChanges() ? 'warning' : 'success'}`}>
                      {hasChanges() ? t('dashboard.unsavedChanges') : t('dashboard.saved')}
                    </span>
                  </div>
                )}
              </div>

              <button
                className="btn btn-primary btn-full save-btn"
                onClick={handleSubmit}
                disabled={deadlinePassed || saving || !hasChanges()}
              >
                {saving ? t('auth.signingIn').replace('Signing', 'Saving') : hasChanges() ? t('dashboard.savePreferences') : t('dashboard.noChanges')}
              </button>

              <p className="help-text">
                💡 {t('dashboard.helpText', { time: formatDeadlineTime() })}
              </p>
            </div>
          </div>
            </>
          )}
        </>
      )}

      {/* Success Popup Modal */}
      {showSuccessPopup && (
        <div className="popup-overlay" onClick={() => setShowSuccessPopup(false)}>
          <div className="popup-modal" onClick={(e) => e.stopPropagation()}>
            <div className="popup-icon">
              <div className="success-checkmark">
                <div className="check-icon">
                  <span className="icon-line line-tip"></span>
                  <span className="icon-line line-long"></span>
                  <div className="icon-circle"></div>
                  <div className="icon-fix"></div>
                </div>
              </div>
            </div>
            <h2 className="popup-title">Success!</h2>
            <p className="popup-message">
              {t('notifications.saved')}
            </p>
            <div className="popup-details">
              <div className="selected-meals-summary">
                <h3>{t('dashboard.mealsSelected')}</h3>
                <div className="meals-list">
                  {selections.breakfast && (
                    <div className="meal-item-popup">
                      <span className="meal-emoji">☕</span>
                      <span>{t('dashboard.breakfast')}</span>
                    </div>
                  )}
                  {selections.lunch && (
                    <div className="meal-item-popup">
                      <span className="meal-emoji">🍛</span>
                      <span>{t('dashboard.lunch')}</span>
                    </div>
                  )}
                  {selections.snacks && (
                    <div className="meal-item-popup">
                      <span className="meal-emoji">🍪</span>
                      <span>{t('dashboard.snacks')}</span>
                    </div>
                  )}
                  {selections.dinner && (
                    <div className="meal-item-popup">
                      <span className="meal-emoji">🍽️</span>
                      <span>Dinner</span>
                    </div>
                  )}
                  {!selections.breakfast && !selections.lunch && !selections.snacks && !selections.dinner && (
                    <p className="no-meals-selected">{t('dashboard.noItems')}</p>
                  )}
                </div>
              </div>
              <div className="popup-info">
                <p>✓ {t('dashboard.saved')} {formatDate(getTomorrowDate())}</p>
                <p>✓ {t('dashboard.helpText', { time: formatDeadlineTime() })}</p>
              </div>
            </div>
            <button 
              className="btn btn-primary popup-close-btn"
              onClick={() => setShowSuccessPopup(false)}
            >
              {t('buttons.done')}
            </button>
          </div>
        </div>
      )}

      {/* Deadline Warning Popup - 10 minutes before */}
      {showDeadlineWarning && (
        <div className="popup-overlay" onClick={() => setShowDeadlineWarning(false)}>
          <div className="popup-modal warning-popup" onClick={(e) => e.stopPropagation()}>
            <div className="popup-icon">
              <div className="warning-icon">⏰</div>
            </div>
            <h2 className="popup-title warning-title">⚠️ Deadline Approaching!</h2>
            <p className="popup-message">
              The meal selection window is closing in <strong>10 minutes</strong>!
            </p>
            <div className="popup-details warning-details">
              <p>📅 Deadline: <strong>{formatDeadlineTime()}</strong></p>
              <p>🍽️ Please complete your meal selection before the deadline.</p>
              {(!selections.breakfast && !selections.lunch && !selections.snacks) && (
                <p className="warning-text">⚠️ You haven't selected any meals yet!</p>
              )}
            </div>
            <button 
              className="btn btn-primary popup-close-btn"
              onClick={() => setShowDeadlineWarning(false)}
            >
              Got it!
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default EmployeeDashboard;
