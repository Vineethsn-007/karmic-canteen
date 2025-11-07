// src/components/Admin/AdminSettings.jsx
import React, { useState, useEffect } from 'react';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { db } from '../../firebase/config';
import './AdminSettings.css';

const AdminSettings = () => {
  const [deadlineHour, setDeadlineHour] = useState(21);
  const [deadlineMinute, setDeadlineMinute] = useState(0);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState({ type: '', text: '' });

  useEffect(() => {
    fetchSettings();
  }, []);

  const fetchSettings = async () => {
    try {
      setLoading(true);
      const settingsRef = doc(db, 'settings', 'deadline');
      const settingsSnap = await getDoc(settingsRef);

      if (settingsSnap.exists()) {
        const data = settingsSnap.data();
        setDeadlineHour(data.deadlineHour || 21);
        setDeadlineMinute(data.deadlineMinute || 0);
      }
    } catch (error) {
      console.error('Error fetching settings:', error);
      showMessage('error', 'Failed to load settings');
    } finally {
      setLoading(false);
    }
  };

  const handleSaveSettings = async (e) => {
    e.preventDefault();

    try {
      setSaving(true);
      const settingsRef = doc(db, 'settings', 'deadline');

      await setDoc(settingsRef, {
        deadlineHour: parseInt(deadlineHour),
        deadlineMinute: parseInt(deadlineMinute),
        updatedAt: new Date().toISOString()
      });

      showMessage('success', 'Deadline time updated successfully!');
    } catch (error) {
      console.error('Error saving settings:', error);
      showMessage('error', 'Failed to save settings. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  const showMessage = (type, text) => {
    setMessage({ type, text });
    setTimeout(() => setMessage({ type: '', text: '' }), 5000);
  };

  const formatTime = (hour, minute) => {
    const h = parseInt(hour);
    const m = parseInt(minute);
    const period = h >= 12 ? 'PM' : 'AM';
    const displayHour = h === 0 ? 12 : h > 12 ? h - 12 : h;
    return `${displayHour}:${m.toString().padStart(2, '0')} ${period}`;
  };

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Loading settings...</p>
      </div>
    );
  }

  return (
    <div className="admin-settings">
      <div className="settings-header">
        <h2>⚙️ System Settings</h2>
        <p className="subtitle">Configure meal selection deadline time</p>
      </div>

      {message.text && (
        <div className={`message ${message.type}`}>
          {message.type === 'success' ? '✓' : '⚠'} {message.text}
        </div>
      )}

      <div className="settings-card">
        <div className="setting-section">
          <div className="section-header">
            <h3>📅 Daily Meal Selection Deadline</h3>
            <p className="section-description">
              Set the time by which employees must submit their meal preferences for the next day.
              After this time, the selection form will be locked.
            </p>
          </div>

          <form onSubmit={handleSaveSettings}>
            <div className="time-picker-container">
              <div className="time-display">
                <div className="time-icon">⏰</div>
                <div className="time-text">
                  <span className="label">Current Deadline:</span>
                  <span className="time-value">{formatTime(deadlineHour, deadlineMinute)}</span>
                </div>
              </div>

              <div className="time-inputs">
                <div className="input-group">
                  <label htmlFor="hour">Hour (0-23)</label>
                  <input
                    id="hour"
                    type="number"
                    min="0"
                    max="23"
                    value={deadlineHour}
                    onChange={(e) => setDeadlineHour(e.target.value)}
                    required
                  />
                  <span className="input-hint">24-hour format</span>
                </div>

                <div className="time-separator">:</div>

                <div className="input-group">
                  <label htmlFor="minute">Minute (0-59)</label>
                  <input
                    id="minute"
                    type="number"
                    min="0"
                    max="59"
                    value={deadlineMinute}
                    onChange={(e) => setDeadlineMinute(e.target.value)}
                    required
                  />
                  <span className="input-hint">Minutes</span>
                </div>
              </div>

              <div className="quick-presets">
                <p className="presets-label">Quick Presets:</p>
                <div className="preset-buttons">
                  <button
                    type="button"
                    className="btn btn-secondary btn-sm"
                    onClick={() => { setDeadlineHour(18); setDeadlineMinute(0); }}
                  >
                    6:00 PM
                  </button>
                  <button
                    type="button"
                    className="btn btn-secondary btn-sm"
                    onClick={() => { setDeadlineHour(20); setDeadlineMinute(0); }}
                  >
                    8:00 PM
                  </button>
                  <button
                    type="button"
                    className="btn btn-secondary btn-sm"
                    onClick={() => { setDeadlineHour(21); setDeadlineMinute(0); }}
                  >
                    9:00 PM
                  </button>
                  <button
                    type="button"
                    className="btn btn-secondary btn-sm"
                    onClick={() => { setDeadlineHour(22); setDeadlineMinute(0); }}
                  >
                    10:00 PM
                  </button>
                </div>
              </div>
            </div>

            <div className="save-section">
              <button
                type="submit"
                className="btn btn-primary btn-large"
                disabled={saving}
              >
                {saving ? 'Saving...' : 'Save Settings'}
              </button>
            </div>
          </form>

          <div className="info-box">
            <div className="info-icon">💡</div>
            <div className="info-content">
              <strong>How it works:</strong>
              <ul>
                <li>Employees can select meals until the deadline time each day</li>
                <li>After the deadline, the selection form becomes read-only</li>
                <li>The deadline applies to selections for the next day's meals</li>
                <li>Changes to this setting take effect immediately</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdminSettings;
