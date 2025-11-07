// src/components/Admin/PredictionsDashboard.jsx
import React, { useState, useEffect } from 'react';
import './PredictionsDashboard.css';

const PredictionsDashboard = () => {
  const [loading, setLoading] = useState(false);
  const [predictions, setPredictions] = useState(null);
  const [weeklyPredictions, setWeeklyPredictions] = useState(null);
  const [insights, setInsights] = useState(null);
  const [message, setMessage] = useState({ type: '', text: '' });
  const [apiStatus, setApiStatus] = useState(null);
  const [forecastDays, setForecastDays] = useState(7);

  const API_BASE_URL = 'http://localhost:5000/api';

  useEffect(() => {
    checkApiStatus();
  }, []);

  const checkApiStatus = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/status`);
      const data = await response.json();
      setApiStatus(data);
    } catch (error) {
      console.error('API not available:', error);
      setApiStatus({ status: 'offline' });
    }
  };

  const predictNextDay = async () => {
    try {
      setLoading(true);
      showMessage('info', 'Preparing prediction system...');
      
      // Step 1: Update data if models not trained
      if (apiStatus && !apiStatus.models_trained) {
        showMessage('info', 'Loading data from database...');
        
        const updateResponse = await fetch(`${API_BASE_URL}/update-data`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' }
        });
        
        const updateData = await updateResponse.json();
        
        if (!updateData.success) {
          showMessage('error', 'Failed to load data. Please try again.');
          setLoading(false);
          return;
        }
        
        showMessage('info', `Loaded ${updateData.records} records. Training models... (2-3 minutes)`);
        
        // Step 2: Train models
        const trainResponse = await fetch(`${API_BASE_URL}/train`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' }
        });
        
        const trainData = await trainResponse.json();
        
        if (!trainData.success) {
          showMessage('error', 'Failed to train models. Please try again.');
          setLoading(false);
          return;
        }
        
        showMessage('success', 'Models trained successfully! Generating predictions...');
        await checkApiStatus(); // Refresh status
      } else {
        showMessage('info', 'Generating predictions for tomorrow...');
      }
      
      // Step 3: Generate predictions
      const response = await fetch(`${API_BASE_URL}/predict-next-day`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
      });
      
      const data = await response.json();
      
      if (data.success) {
        setPredictions(data);
        showMessage('success', `✓ Predicted ${data.total_meals} total meals for ${data.date}`);
      } else {
        showMessage('error', data.message || 'Failed to generate predictions');
      }
    } catch (error) {
      console.error('Error:', error);
      showMessage('error', 'Failed to connect to prediction service. Make sure the ML server is running.');
    } finally {
      setLoading(false);
    }
  };

  const predictWeekly = async () => {
    try {
      setLoading(true);
      showMessage('info', `Generating ${forecastDays}-day forecast...`);
      
      const response = await fetch(`${API_BASE_URL}/predict-weekly`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ days: forecastDays })
      });
      
      const data = await response.json();
      
      if (data.success) {
        setWeeklyPredictions(data);
        showMessage('success', `Generated forecast for ${forecastDays} days`);
      } else {
        showMessage('error', data.message || 'Failed to generate forecast');
      }
    } catch (error) {
      console.error('Error:', error);
      showMessage('error', 'Failed to connect to prediction service');
    } finally {
      setLoading(false);
    }
  };

  const getInsights = async () => {
    try {
      setLoading(true);
      showMessage('info', 'Analyzing trends...');
      
      const response = await fetch(`${API_BASE_URL}/insights`);
      const data = await response.json();
      
      if (data.success) {
        setInsights(data.insights);
        showMessage('success', 'Insights generated successfully');
      } else {
        showMessage('error', data.message || 'Failed to generate insights');
      }
    } catch (error) {
      console.error('Error:', error);
      showMessage('error', 'Failed to connect to prediction service');
    } finally {
      setLoading(false);
    }
  };

  const updateData = async () => {
    try {
      setLoading(true);
      showMessage('info', 'Updating data from Firebase...');
      
      const response = await fetch(`${API_BASE_URL}/update-data`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
      });
      
      const data = await response.json();
      
      if (data.success) {
        showMessage('success', `Loaded ${data.records} records successfully. Training models...`);
        
        // Automatically train models after data update
        const trainResponse = await fetch(`${API_BASE_URL}/train`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' }
        });
        
        const trainData = await trainResponse.json();
        
        if (trainData.success) {
          showMessage('success', `Models trained! Ready to generate predictions.`);
          checkApiStatus(); // Refresh status
        } else {
          showMessage('error', 'Data loaded but model training failed');
        }
      } else {
        showMessage('error', data.message || 'Failed to update data');
      }
    } catch (error) {
      console.error('Error:', error);
      showMessage('error', 'Failed to connect to prediction service');
    } finally {
      setLoading(false);
    }
  };

  const trainModels = async () => {
    try {
      setLoading(true);
      showMessage('info', 'Training ML models... This may take a few minutes.');
      
      const response = await fetch(`${API_BASE_URL}/train`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
      });
      
      const data = await response.json();
      
      if (data.success) {
        showMessage('success', `Trained ${data.models_trained} models successfully`);
        checkApiStatus(); // Refresh status
      } else {
        showMessage('error', data.message || 'Failed to train models');
      }
    } catch (error) {
      console.error('Error:', error);
      showMessage('error', 'Failed to connect to prediction service');
    } finally {
      setLoading(false);
    }
  };

  const showMessage = (type, text) => {
    setMessage({ type, text });
    setTimeout(() => setMessage({ type: '', text: '' }), 5000);
  };

  const formatDate = (dateStr) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', { 
      weekday: 'short', 
      month: 'short', 
      day: 'numeric' 
    });
  };

  return (
    <div className="predictions-dashboard">
      <div className="predictions-header">
        <div>
          <h2>🤖 AI Predictions</h2>
          <p className="subtitle">ML-powered meal demand forecasting</p>
        </div>
        
        {apiStatus && (
          <div className={`api-status ${apiStatus.status === 'online' ? 'online' : 'offline'}`}>
            <span className="status-dot"></span>
            <span>{apiStatus.status === 'online' ? 'ML Service Online' : 'ML Service Offline'}</span>
          </div>
        )}
      </div>

      {message.text && (
        <div className={`message ${message.type}`}>
          {message.type === 'success' && '✓'}
          {message.type === 'error' && '⚠'}
          {message.type === 'info' && 'ℹ'}
          {' '}{message.text}
        </div>
      )}

      {/* Setup Instructions */}
      {apiStatus?.status === 'online' && !apiStatus?.models_trained && (
        <div className="setup-notice">
          <div className="setup-icon">ℹ️</div>
          <div className="setup-content">
            <h4>Getting Started</h4>
            <p>The AI prediction system is ready to use:</p>
            <ol>
              <li>Click "Predict Tomorrow" to generate meal demand predictions</li>
              <li>Click "Get Insights" to view historical trends and patterns</li>
              <li>Use "Weekly Forecast" to predict multiple days ahead</li>
            </ol>
          </div>
        </div>
      )}

      {/* Action Buttons */}
      <div className="actions-section">
        <h3>🎯 Quick Actions</h3>
        <div className="actions-grid">
          <button
            className="btn btn-success"
            onClick={predictNextDay}
            disabled={loading || apiStatus?.status !== 'online'}
          >
            🔮 Predict Tomorrow
          </button>
          
          <button
            className="btn btn-info"
            onClick={getInsights}
            disabled={loading || apiStatus?.status !== 'online'}
          >
            📈 Get Insights
          </button>
        </div>
      </div>

      {/* Weekly Forecast Section */}
      <div className="forecast-section">
        <h3>📅 Weekly Forecast</h3>
        <div className="forecast-controls">
          <label>
            Forecast Days:
            <input
              type="number"
              min="1"
              max="30"
              value={forecastDays}
              onChange={(e) => setForecastDays(parseInt(e.target.value))}
              disabled={loading}
            />
          </label>
          <button
            className="btn btn-primary"
            onClick={predictWeekly}
            disabled={loading || apiStatus?.status !== 'online'}
          >
            Generate Forecast
          </button>
        </div>
      </div>

      {/* Next Day Predictions */}
      {predictions && (
        <div className="predictions-card">
          <h3>🔮 Tomorrow's Predictions ({predictions.date})</h3>
          <div className="prediction-summary">
            <div className="summary-item">
              <span className="summary-label">Total Meals:</span>
              <span className="summary-value">{predictions.total_meals}</span>
            </div>
            <div className="summary-item">
              <span className="summary-label">Avg Confidence:</span>
              <span className="summary-value">{(predictions.avg_confidence * 100).toFixed(1)}%</span>
            </div>
          </div>
          
          <div className="predictions-table-container">
            <table className="predictions-table">
              <thead>
                <tr>
                  <th>Item ID</th>
                  <th>Predicted Count</th>
                  <th>Opt-in Rate</th>
                  <th>Confidence</th>
                  <th>Range</th>
                </tr>
              </thead>
              <tbody>
                {predictions.predictions.map((pred, index) => (
                  <tr key={index}>
                    <td>{pred.menu_item_id}</td>
                    <td className="count-cell">{Math.round(pred.predicted_count)}</td>
                    <td>{(pred.predicted_opt_in_rate * 100).toFixed(1)}%</td>
                    <td>
                      <div className="confidence-bar">
                        <div 
                          className="confidence-fill" 
                          style={{ width: `${pred.confidence * 100}%` }}
                        ></div>
                        <span className="confidence-text">{(pred.confidence * 100).toFixed(0)}%</span>
                      </div>
                    </td>
                    <td className="range-cell">
                      {Math.round(pred.lower_bound)} - {Math.round(pred.upper_bound)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Weekly Predictions */}
      {weeklyPredictions && weeklyPredictions.daily_summary && weeklyPredictions.daily_summary.length > 0 && (
        <div className="predictions-card">
          <h3>📅 {forecastDays}-Day Forecast</h3>
          <div className="prediction-summary">
            <div className="summary-item">
              <span className="summary-label">Total Meals:</span>
              <span className="summary-value">{weeklyPredictions.total_meals.toLocaleString()}</span>
            </div>
            <div className="summary-item">
              <span className="summary-label">Avg Confidence:</span>
              <span className="summary-value">{(weeklyPredictions.avg_confidence * 100).toFixed(1)}%</span>
            </div>
          </div>
          
          <div className="weekly-chart">
            {weeklyPredictions.daily_summary.map((day, index) => {
              const maxCount = Math.max(...weeklyPredictions.daily_summary.map(d => d.predicted_count));
              const heightPercent = maxCount > 0 ? (day.predicted_count / maxCount) * 100 : 0;
              
              return (
                <div key={index} className="day-bar">
                  <div className="day-label">{formatDate(day.date)}</div>
                  <div className="bar-container">
                    <div 
                      className="bar-fill" 
                      style={{ 
                        height: `${Math.max(heightPercent, 5)}%`,
                        minHeight: '30px'
                      }}
                    >
                      <span className="bar-value">{Math.round(day.predicted_count)}</span>
                    </div>
                  </div>
                  <div className="day-confidence">{(day.confidence * 100).toFixed(0)}%</div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Insights */}
      {insights && (
        <div className="insights-card">
          <h3>💡 Trend Insights</h3>
          
          {/* Data Period */}
          {insights.data_period && (
            <div className="insight-section">
              <h4>📅 Data Period</h4>
              <div className="insight-grid">
                <div className="insight-item">
                  <span className="insight-label">Period:</span>
                  <span className="insight-value">{insights.data_period.start} to {insights.data_period.end}</span>
                </div>
                <div className="insight-item">
                  <span className="insight-label">Total Days:</span>
                  <span className="insight-value">{insights.data_period.days} days</span>
                </div>
              </div>
            </div>
          )}

          {/* Day of Week Analysis */}
          {insights.day_of_week && (
            <div className="insight-section">
              <h4>📊 Average Meals by Day</h4>
              <div className="day-bars">
                {Object.entries(insights.day_of_week.avg_by_day)
                  .filter(([day]) => day !== 'Sunday') // Exclude Sunday from display
                  .sort((a, b) => b[1] - a[1])
                  .map(([day, avg]) => (
                    <div key={day} className="day-insight-bar">
                      <span className="day-name">{day}</span>
                      <div className="bar-wrapper">
                        <div 
                          className="bar-inner" 
                          style={{ 
                            width: `${(avg / Math.max(...Object.entries(insights.day_of_week.avg_by_day).filter(([d]) => d !== 'Sunday').map(([, v]) => v))) * 100}%` 
                          }}
                        ></div>
                        <span className="bar-label">{avg.toFixed(1)} meals</span>
                      </div>
                    </div>
                  ))}
              </div>
              <div className="insight-highlight">
                <span className="highlight-good">🏆 Best Day: {insights.day_of_week.best_day}</span>
                <span className="highlight-holiday">🏖️ Sunday: Holiday (No Service)</span>
              </div>
            </div>
          )}

          {/* Holiday Impact */}
          {insights.holiday_impact && (
            <div className="insight-section">
              <h4>🎉 Holiday Impact</h4>
              <div className="insight-grid">
                <div className="insight-item">
                  <span className="insight-label">Regular Days:</span>
                  <span className="insight-value">{insights.holiday_impact.avg_meals_regular.toFixed(1)} meals</span>
                </div>
                <div className="insight-item">
                  <span className="insight-label">Holidays:</span>
                  <span className="insight-value">{insights.holiday_impact.avg_meals_holiday.toFixed(1)} meals</span>
                </div>
              </div>
            </div>
          )}

          {/* Top Items */}
          {insights.top_items && (
            <div className="insight-section">
              <h4>⭐ Top Menu Items</h4>
              <div className="top-items-list">
                {insights.top_items.slice(0, 5).map((item, index) => (
                  <div key={index} className="top-item">
                    <span className="item-rank">#{index + 1}</span>
                    <span className="item-id">Item {item.menu_item_id}</span>
                    <span className="item-count">{item.total_count.toLocaleString()} orders</span>
                    <span className="item-avg">{item.avg_count.toFixed(1)} avg/day</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Trends */}
          {insights.trends && (
            <div className="insight-section">
              <h4>📈 Trends</h4>
              <div className="trend-summary">
                <p>{insights.trends.summary}</p>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Offline Message */}
      {apiStatus?.status === 'offline' && (
        <div className="offline-message">
          <div className="offline-icon">🔌</div>
          <h3>ML Service Offline</h3>
          <p>The prediction service is not running. To start it:</p>
          <ol>
            <li>Navigate to the <code>canteen_management_system</code> folder</li>
            <li>Run <code>python app.py</code> or double-click <code>START.bat</code></li>
            <li>The service will start on <code>http://localhost:5000</code></li>
          </ol>
        </div>
      )}

      {loading && (
        <div className="loading-overlay">
          <div className="spinner"></div>
          <p>Processing...</p>
        </div>
      )}
    </div>
  );
};

export default PredictionsDashboard;
