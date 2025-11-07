// src/components/Admin/AnalyticsDashboard.jsx
import React, { useState, useEffect } from 'react';
import { collection, getDocs } from 'firebase/firestore';
import { db } from '../../firebase/config';
import { useTranslation } from 'react-i18next';
import './AnalyticsDashboard.css';

const AnalyticsDashboard = () => {
  const { t } = useTranslation();
  const [analytics, setAnalytics] = useState({
    totalEmployees: 0,
    todayParticipants: 0,
    totalMealsOrdered: 0,
    participationRate: 0,
    breakfastOrders: 0,
    lunchOrders: 0,
    snacksOrders: 0
  });
  const [loading, setLoading] = useState(true);
  const [lastUpdated, setLastUpdated] = useState(new Date());

  useEffect(() => {
    fetchAnalytics();
    // Refresh every 5 minutes
    const interval = setInterval(fetchAnalytics, 300000);
    return () => clearInterval(interval);
  }, []);

  const getTomorrowDate = () => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    return tomorrow.toISOString().split('T')[0];
  };

  const fetchAnalytics = async () => {
    try {
      setLoading(true);
      const tomorrow = getTomorrowDate();

      // Fetch total employees
      const usersSnapshot = await getDocs(collection(db, 'users'));
      const employees = usersSnapshot.docs.filter(doc => doc.data().role === 'employee');
      const totalEmployees = employees.length;

      // Fetch today's meal selections from the correct path
      const selectionsPath = collection(db, 'mealSelections', tomorrow, 'users');
      const selectionsSnapshot = await getDocs(selectionsPath);
      
      let breakfastCount = 0;
      let lunchCount = 0;
      let snacksCount = 0;
      const participatingUsers = new Set();

      selectionsSnapshot.docs.forEach(doc => {
        const data = doc.data();
        if (data.breakfast) {
          breakfastCount++;
          participatingUsers.add(doc.id);
        }
        if (data.lunch) {
          lunchCount++;
          participatingUsers.add(doc.id);
        }
        if (data.snacks) {
          snacksCount++;
          participatingUsers.add(doc.id);
        }
      });

      const todayParticipants = participatingUsers.size;
      const totalMealsOrdered = breakfastCount + lunchCount + snacksCount;
      const participationRate = totalEmployees > 0 
        ? ((todayParticipants / totalEmployees) * 100).toFixed(1)
        : 0;

      setAnalytics({
        totalEmployees,
        todayParticipants,
        totalMealsOrdered,
        participationRate,
        breakfastOrders: breakfastCount,
        lunchOrders: lunchCount,
        snacksOrders: snacksCount
      });

      setLastUpdated(new Date());
      setLoading(false);
    } catch (error) {
      console.error('Error fetching analytics:', error);
      setLoading(false);
    }
  };

  const formatTime = (date) => {
    return date.toLocaleTimeString('en-US', { 
      hour: 'numeric', 
      minute: '2-digit',
      hour12: true 
    });
  };

  const getMealPercentage = (mealCount) => {
    if (analytics.totalMealsOrdered === 0) return 0;
    return ((mealCount / analytics.totalMealsOrdered) * 100).toFixed(0);
  };

  const getChartData = () => {
    const total = analytics.totalMealsOrdered || 1;
    return [
      { 
        name: 'Breakfast', 
        value: analytics.breakfastOrders,
        percentage: (analytics.breakfastOrders / total * 100).toFixed(0),
        color: '#f59e0b'
      },
      { 
        name: 'Lunch', 
        value: analytics.lunchOrders,
        percentage: (analytics.lunchOrders / total * 100).toFixed(0),
        color: '#10b981'
      },
      { 
        name: 'Snacks', 
        value: analytics.snacksOrders,
        percentage: (analytics.snacksOrders / total * 100).toFixed(0),
        color: '#a855f7'
      }
    ];
  };

  if (loading) {
    return (
      <div className="analytics-dashboard">
        <div className="analytics-header">
          <h2>Analytics Dashboard</h2>
        </div>
        <div className="loading-state">Loading analytics...</div>
      </div>
    );
  }

  const chartData = getChartData();

  return (
    <div className="analytics-dashboard">
      <div className="analytics-header">
        <div>
          <h2>Analytics Dashboard</h2>
          <span className="last-updated">Last updated: {formatTime(lastUpdated)}</span>
        </div>
        <button 
          className="btn btn-secondary refresh-btn" 
          onClick={fetchAnalytics}
          disabled={loading}
        >
          🔄 Refresh
        </button>
      </div>

      {/* Stats Cards */}
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#e0f2fe' }}>
            <span style={{ color: '#0284c7' }}>👥</span>
          </div>
          <div className="stat-content">
            <div className="stat-value">{analytics.totalEmployees}</div>
            <div className="stat-label">Total Employees</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#dcfce7' }}>
            <span style={{ color: '#16a34a' }}>✅</span>
          </div>
          <div className="stat-content">
            <div className="stat-value">{analytics.todayParticipants}</div>
            <div className="stat-label">Today's Participants</div>
          </div>
        </div>

        <div className="stat-card full-width">
          <div className="stat-icon" style={{ background: '#fef3c7' }}>
            <span style={{ color: '#d97706' }}>🍽️</span>
          </div>
          <div className="stat-content">
            <div className="stat-value">{analytics.totalMealsOrdered}</div>
            <div className="stat-label">Total Meals Ordered</div>
          </div>
        </div>
      </div>

      {/* Participation Rate */}
      <div className="participation-card">
        <div className="participation-header">
          <h3>Participation Rate</h3>
          <span className="participation-percentage">{analytics.participationRate}%</span>
        </div>
        <div className="progress-bar">
          <div 
            className="progress-fill" 
            style={{ width: `${analytics.participationRate}%` }}
          ></div>
        </div>
        <p className="participation-text">
          {analytics.todayParticipants} of {analytics.totalEmployees} employees participating
        </p>
      </div>

      {/* Meal Distribution Chart */}
      <div className="chart-section">
        <h3>Today's Meal Distribution</h3>
        <div className="donut-chart-container">
          <svg viewBox="0 0 200 200" className="donut-chart">
            <circle
              cx="100"
              cy="100"
              r="80"
              fill="none"
              stroke="#f59e0b"
              strokeWidth="40"
              strokeDasharray={`${(analytics.breakfastOrders / analytics.totalMealsOrdered * 502.65) || 0} 502.65`}
              transform="rotate(-90 100 100)"
            />
            <circle
              cx="100"
              cy="100"
              r="80"
              fill="none"
              stroke="#10b981"
              strokeWidth="40"
              strokeDasharray={`${(analytics.lunchOrders / analytics.totalMealsOrdered * 502.65) || 0} 502.65`}
              strokeDashoffset={`-${(analytics.breakfastOrders / analytics.totalMealsOrdered * 502.65) || 0}`}
              transform="rotate(-90 100 100)"
            />
            <circle
              cx="100"
              cy="100"
              r="80"
              fill="none"
              stroke="#a855f7"
              strokeWidth="40"
              strokeDasharray={`${(analytics.snacksOrders / analytics.totalMealsOrdered * 502.65) || 0} 502.65`}
              strokeDashoffset={`-${((analytics.breakfastOrders + analytics.lunchOrders) / analytics.totalMealsOrdered * 502.65) || 0}`}
              transform="rotate(-90 100 100)"
            />
            <circle cx="100" cy="100" r="60" fill="white" />
            <text x="100" y="110" textAnchor="middle" fontSize="24" fontWeight="bold" fill="#333">
              {analytics.totalMealsOrdered > 0 ? '100%' : '0%'}
            </text>
          </svg>
        </div>

        <div className="chart-legend">
          {chartData.map((item, index) => (
            <div key={index} className="legend-item">
              <span className="legend-color" style={{ background: item.color }}></span>
              <span className="legend-label">{item.name}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Meal Breakdown */}
      <div className="meal-breakdown-section">
        <h3>Meal Breakdown</h3>

        <div className="meal-breakdown-card">
          <div className="meal-icon-wrapper" style={{ background: '#fef3c7' }}>
            <span className="meal-icon">☕</span>
          </div>
          <div className="meal-info">
            <h4>Breakfast</h4>
            <p>{analytics.breakfastOrders} orders</p>
          </div>
          <div className="meal-stats">
            <div className="meal-count">{analytics.breakfastOrders}</div>
            <div className="meal-percentage">{getMealPercentage(analytics.breakfastOrders)}%</div>
          </div>
        </div>

        <div className="meal-breakdown-card">
          <div className="meal-icon-wrapper" style={{ background: '#dcfce7' }}>
            <span className="meal-icon">🍱</span>
          </div>
          <div className="meal-info">
            <h4>Lunch</h4>
            <p>{analytics.lunchOrders} orders</p>
          </div>
          <div className="meal-stats">
            <div className="meal-count">{analytics.lunchOrders}</div>
            <div className="meal-percentage">{getMealPercentage(analytics.lunchOrders)}%</div>
          </div>
        </div>

        <div className="meal-breakdown-card">
          <div className="meal-icon-wrapper" style={{ background: '#f3e8ff' }}>
            <span className="meal-icon">🍪</span>
          </div>
          <div className="meal-info">
            <h4>Snacks</h4>
            <p>{analytics.snacksOrders} orders</p>
          </div>
          <div className="meal-stats">
            <div className="meal-count">{analytics.snacksOrders}</div>
            <div className="meal-percentage">{getMealPercentage(analytics.snacksOrders)}%</div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AnalyticsDashboard;
