// src/components/Employee/EmployeeDashboard.jsx
import React, { useState, useEffect } from 'react';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { db } from '../../firebase/config';
import { useAuth } from '../../context/AuthContext';
import './EmployeeDashboard.css';

const EmployeeDashboard = () => {
  const { currentUser } = useAuth();
  const [menu, setMenu] = useState(null);
  const [selections, setSelections] = useState({
    breakfast: false,
    lunch: false,
    snacks: false
  });
  const [savedSelections, setSavedSelections] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [deadlinePassed, setDeadlinePassed] = useState(false);
  const [message, setMessage] = useState({ type: '', text: '' });
  const [currentTime, setCurrentTime] = useState(new Date());

  useEffect(() => {
    fetchTomorrowMenu();
    loadUserSelections();
    checkDeadline();

    // Update time every minute
    const timer = setInterval(() => {
      setCurrentTime(new Date());
      checkDeadline();
    }, 60000);

    return () => clearInterval(timer);
  }, []);

  const getTomorrowDate = () => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    return tomorrow.toISOString().split('T')[0];
  };

  const formatDate = (dateStr) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', { 
      weekday: 'long', 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric' 
    });
  };

  const checkDeadline = () => {
    const now = new Date();
    const hours = now.getHours();
    const minutes = now.getMinutes();
    const currentMinutes = hours * 60 + minutes;
    const deadlineMinutes = 21 * 60; // 9:00 PM = 21:00

    setDeadlinePassed(currentMinutes >= deadlineMinutes);
  };

  const getTimeUntilDeadline = () => {
    const now = new Date();
    const deadline = new Date();
    deadline.setHours(21, 0, 0, 0);

    if (now > deadline) {
      return 'Deadline passed';
    }

    const diff = deadline - now;
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));

    return `${hours}h ${minutes}m remaining`;
  };

  const fetchTomorrowMenu = async () => {
    try {
      const tomorrow = getTomorrowDate();
      const menuRef = doc(db, 'menus', tomorrow);
      const menuSnap = await getDoc(menuRef);

      if (menuSnap.exists()) {
        setMenu(menuSnap.data());
      } else {
        setMenu(null);
      }
    } catch (error) {
      console.error('Error fetching menu:', error);
      showMessage('error', 'Failed to load menu');
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
        setSelections({
          breakfast: data.breakfast || false,
          lunch: data.lunch || false,
          snacks: data.snacks || false
        });
        setSavedSelections({
          breakfast: data.breakfast || false,
          lunch: data.lunch || false,
          snacks: data.snacks || false
        });
      }
    } catch (error) {
      console.error('Error loading selections:', error);
    }
  };

  const handleMealToggle = (mealType) => {
    if (deadlinePassed) {
      showMessage('error', 'Selection deadline has passed (9:00 PM)');
      return;
    }

    setSelections(prev => ({
      ...prev,
      [mealType]: !prev[mealType]
    }));
  };

  const handleSubmit = async () => {
    if (deadlinePassed) {
      showMessage('error', 'Selection deadline has passed (9:00 PM)');
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
      selections.snacks !== savedSelections.snacks
    );
  };

  const getSelectedCount = () => {
    return Object.values(selections).filter(val => val).length;
  };

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Loading menu...</p>
      </div>
    );
  }

  return (
    <div className="employee-dashboard">
      <div className="dashboard-header">
        <div>
          <h1>Meal Selection</h1>
          <p className="subtitle">Select your meals for tomorrow</p>
        </div>
        <div className="deadline-info">
          <span className={`deadline-badge ${deadlinePassed ? 'expired' : 'active'}`}>
            {deadlinePassed ? '🔒 Deadline Passed' : `⏰ ${getTimeUntilDeadline()}`}
          </span>
        </div>
      </div>

      {message.text && (
        <div className={`message ${message.type}`}>
          {message.type === 'success' ? '✓' : '⚠'} {message.text}
        </div>
      )}

      <div className="date-card">
        <h3>📅 Menu for {formatDate(getTomorrowDate())}</h3>
      </div>

      {!menu ? (
        <div className="no-menu-card">
          <div className="empty-state">
            <span className="empty-icon">🍽️</span>
            <h3>No Menu Available</h3>
            <p>The menu for tomorrow hasn't been published yet.</p>
            <p className="small-text">Please check back later or contact the canteen administrator.</p>
          </div>
        </div>
      ) : (
        <>
          <div className="meals-grid">
            {/* Breakfast Card */}
            <div className={`meal-card ${selections.breakfast ? 'selected' : ''}`}>
              <div className="meal-header">
                <div className="meal-icon">🌅</div>
                <h3>Breakfast</h3>
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
                  <p className="no-items">No items available</p>
                )}
              </div>

              <button
                className={`meal-toggle-btn ${selections.breakfast ? 'active' : ''}`}
                onClick={() => handleMealToggle('breakfast')}
                disabled={deadlinePassed || !menu.breakfast || menu.breakfast.length === 0}
              >
                {selections.breakfast ? '✓ Selected' : 'Select'}
              </button>
            </div>

            {/* Lunch Card */}
            <div className={`meal-card ${selections.lunch ? 'selected' : ''}`}>
              <div className="meal-header">
                <div className="meal-icon">🌞</div>
                <h3>Lunch</h3>
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
                  <p className="no-items">No items available</p>
                )}
              </div>

              <button
                className={`meal-toggle-btn ${selections.lunch ? 'active' : ''}`}
                onClick={() => handleMealToggle('lunch')}
                disabled={deadlinePassed || !menu.lunch || menu.lunch.length === 0}
              >
                {selections.lunch ? '✓ Selected' : 'Select'}
              </button>
            </div>

            {/* Snacks Card */}
            <div className={`meal-card ${selections.snacks ? 'selected' : ''}`}>
              <div className="meal-header">
                <div className="meal-icon">🌙</div>
                <h3>Snacks</h3>
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
                  <p className="no-items">No items available</p>
                )}
              </div>

              <button
                className={`meal-toggle-btn ${selections.snacks ? 'active' : ''}`}
                onClick={() => handleMealToggle('snacks')}
                disabled={deadlinePassed || !menu.snacks || menu.snacks.length === 0}
              >
                {selections.snacks ? '✓ Selected' : 'Select'}
              </button>
            </div>
          </div>

          <div className="summary-section">
            <div className="summary-card">
              <h3>Your Selection Summary</h3>
              <div className="summary-stats">
                <div className="stat">
                  <span className="stat-label">Meals Selected:</span>
                  <span className="stat-value">{getSelectedCount()} / 3</span>
                </div>
                {savedSelections && (
                  <div className="stat">
                    <span className="stat-label">Status:</span>
                    <span className={`stat-value ${hasChanges() ? 'warning' : 'success'}`}>
                      {hasChanges() ? '⚠ Unsaved changes' : '✓ Saved'}
                    </span>
                  </div>
                )}
              </div>

              <button
                className="btn btn-primary btn-full save-btn"
                onClick={handleSubmit}
                disabled={deadlinePassed || saving || !hasChanges()}
              >
                {saving ? 'Saving...' : hasChanges() ? 'Save Preferences' : 'No Changes'}
              </button>

              <p className="help-text">
                💡 You can modify your selection until 9:00 PM today
              </p>
            </div>
          </div>
        </>
      )}
    </div>
  );
};

export default EmployeeDashboard;
