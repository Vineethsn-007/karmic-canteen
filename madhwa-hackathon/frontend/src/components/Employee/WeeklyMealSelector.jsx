import React, { useState, useEffect } from 'react';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { db } from '../../firebase/config';
import { useAuth } from '../../context/AuthContext';
import './WeeklyMealSelector.css';

const WeeklyMealSelector = () => {
  const { currentUser } = useAuth();
  const [weekDays, setWeekDays] = useState([]);
  const [weeklySelections, setWeeklySelections] = useState({});
  const [weeklyMenus, setWeeklyMenus] = useState({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState({ type: '', text: '' });
  const [currentWeekStart, setCurrentWeekStart] = useState(null);

  const mealTimings = {
    breakfast: { start: '8:30 AM', end: '10:00 AM' },
    lunch: { start: '1:00 PM', end: '2:30 PM' },
    snacks: { start: '5:00 PM', end: '6:30 PM' },
    dinner: { start: '8:00 PM', end: '9:30 PM' }
  };

  useEffect(() => {
    initializeWeek();
  }, []);

  const initializeWeek = () => {
    const today = new Date();
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    // Get the start of the week (Monday)
    const dayOfWeek = tomorrow.getDay();
    const diff = dayOfWeek === 0 ? -6 : 1 - dayOfWeek; // Adjust for Sunday
    const monday = new Date(tomorrow);
    monday.setDate(tomorrow.getDate() + diff);
    
    setCurrentWeekStart(monday);
    generateWeekDays(monday);
  };

  const generateWeekDays = async (startDate) => {
    const days = [];
    const selections = {};
    const menus = {};
    
    // Generate 6 working days (Monday to Saturday, excluding Sunday)
    for (let i = 0; i < 7; i++) {
      const date = new Date(startDate);
      date.setDate(startDate.getDate() + i);
      
      // Skip Sunday
      if (date.getDay() === 0) continue;
      
      const dateStr = date.toISOString().split('T')[0];
      days.push({
        date: dateStr,
        dayName: date.toLocaleDateString('en-US', { weekday: 'short' }),
        dayNumber: date.getDate(),
        month: date.toLocaleDateString('en-US', { month: 'short' }),
        isPast: date < new Date()
      });
      
      // Initialize selections for this day
      selections[dateStr] = {
        breakfast: false,
        lunch: false,
        snacks: false,
        dinner: false
      };
    }
    
    setWeekDays(days);
    setWeeklySelections(selections);
    
    // Load menus and existing selections
    await loadWeeklyData(days);
    setLoading(false);
  };

  const loadWeeklyData = async (days) => {
    try {
      const menusData = {};
      const selectionsData = {};
      
      for (const day of days) {
        // Load menu
        const menuRef = doc(db, 'menus', day.date);
        const menuSnap = await getDoc(menuRef);
        if (menuSnap.exists()) {
          menusData[day.date] = menuSnap.data();
        }
        
        // Load existing selections
        const selectionRef = doc(db, 'mealSelections', day.date, 'users', currentUser.uid);
        const selectionSnap = await getDoc(selectionRef);
        if (selectionSnap.exists()) {
          const data = selectionSnap.data();
          selectionsData[day.date] = {
            breakfast: data.breakfast || false,
            lunch: data.lunch || false,
            snacks: data.snacks || false,
            dinner: data.dinner || false
          };
        }
      }
      
      setWeeklyMenus(menusData);
      setWeeklySelections(prev => ({
        ...prev,
        ...selectionsData
      }));
    } catch (error) {
      console.error('Error loading weekly data:', error);
      showMessage('error', 'Failed to load weekly data');
    }
  };

  const handleMealToggle = (dateStr, mealType) => {
    // Check if edit is allowed (before 12:30 PM previous day)
    const mealDate = new Date(dateStr);
    const now = new Date();
    const previousDay = new Date(mealDate);
    previousDay.setDate(mealDate.getDate() - 1);
    previousDay.setHours(12, 30, 0, 0);
    
    if (now > previousDay && !weeklySelections[dateStr]?.[mealType]) {
      showMessage('error', `Deadline passed! You can only edit before 12:30 PM on ${previousDay.toLocaleDateString()}`);
      return;
    }
    
    setWeeklySelections(prev => ({
      ...prev,
      [dateStr]: {
        ...prev[dateStr],
        [mealType]: !prev[dateStr][mealType]
      }
    }));
  };

  const handleSaveWeekly = async () => {
    try {
      setSaving(true);
      showMessage('info', 'Saving weekly selections...');
      
      let savedCount = 0;
      for (const day of weekDays) {
        const dateStr = day.date;
        const selections = weeklySelections[dateStr];
        
        if (selections) {
          const selectionRef = doc(db, 'mealSelections', dateStr, 'users', currentUser.uid);
          await setDoc(selectionRef, {
            ...selections,
            date: dateStr,
            userId: currentUser.uid,
            userEmail: currentUser.email,
            timestamp: new Date().toISOString()
          });
          savedCount++;
        }
      }
      
      showMessage('success', `✓ Saved selections for ${savedCount} days!`);
    } catch (error) {
      console.error('Error saving weekly selections:', error);
      showMessage('error', 'Failed to save selections');
    } finally {
      setSaving(false);
    }
  };

  const showMessage = (type, text) => {
    setMessage({ type, text });
    setTimeout(() => setMessage({ type: '', text: '' }), 5000);
  };

  const getSelectedCountForDay = (dateStr) => {
    const selections = weeklySelections[dateStr];
    if (!selections) return 0;
    return Object.values(selections).filter(val => val).length;
  };

  const getTotalSelectedMeals = () => {
    let total = 0;
    Object.values(weeklySelections).forEach(daySelections => {
      total += Object.values(daySelections).filter(val => val).length;
    });
    return total;
  };

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Loading weekly menu...</p>
      </div>
    );
  }

  return (
    <div className="weekly-meal-selector">
      <div className="weekly-header">
        <h2>📅 Weekly Meal Selection</h2>
        <p className="subtitle">Select your meals for the week (Monday - Saturday)</p>
        <div className="deadline-notice">
          ⏰ <strong>Important:</strong> You can edit selections until 12:30 PM of the previous day
        </div>
      </div>

      {message.text && (
        <div className={`message ${message.type}`}>
          {message.type === 'success' && '✓'}
          {message.type === 'error' && '⚠'}
          {message.type === 'info' && 'ℹ'}
          {' '}{message.text}
        </div>
      )}

      <div className="week-calendar">
        {weekDays.map(day => (
          <div key={day.date} className={`day-card ${day.isPast ? 'past' : ''}`}>
            <div className="day-header">
              <div className="day-info">
                <span className="day-name">{day.dayName}</span>
                <span className="day-number">{day.dayNumber}</span>
                <span className="day-month">{day.month}</span>
              </div>
              <div className="day-count">
                {getSelectedCountForDay(day.date)}/4 meals
              </div>
            </div>

            <div className="day-meals">
              {['breakfast', 'lunch', 'snacks', 'dinner'].map(mealType => {
                const menu = weeklyMenus[day.date];
                const hasMenu = menu && menu[mealType] && menu[mealType].length > 0;
                const isSelected = weeklySelections[day.date]?.[mealType];
                
                return (
                  <div 
                    key={mealType}
                    className={`meal-item ${isSelected ? 'selected' : ''} ${!hasMenu ? 'no-menu' : ''}`}
                    onClick={() => hasMenu && handleMealToggle(day.date, mealType)}
                  >
                    <div className="meal-icon-small">
                      {mealType === 'breakfast' && '☕'}
                      {mealType === 'lunch' && '🍛'}
                      {mealType === 'snacks' && '🍪'}
                      {mealType === 'dinner' && '🍽️'}
                    </div>
                    <div className="meal-info">
                      <span className="meal-name">{mealType.charAt(0).toUpperCase() + mealType.slice(1)}</span>
                      <span className="meal-time">{mealTimings[mealType].start}</span>
                    </div>
                    {isSelected && <span className="check-mark">✓</span>}
                  </div>
                );
              })}
            </div>
          </div>
        ))}
      </div>

      <div className="weekly-summary">
        <div className="summary-stats">
          <div className="stat-item">
            <span className="stat-label">Total Meals Selected</span>
            <span className="stat-value">{getTotalSelectedMeals()}</span>
          </div>
          <div className="stat-item">
            <span className="stat-label">Working Days</span>
            <span className="stat-value">{weekDays.length}</span>
          </div>
        </div>
        
        <button
          className="btn btn-primary btn-large"
          onClick={handleSaveWeekly}
          disabled={saving || getTotalSelectedMeals() === 0}
        >
          {saving ? 'Saving...' : 'Save Weekly Selections'}
        </button>
      </div>
    </div>
  );
};

export default WeeklyMealSelector;
