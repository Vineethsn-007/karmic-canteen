// src/components/Admin/ReportsDashboard.jsx
import React, { useState, useEffect } from 'react';
import { collection, getDocs, doc, getDoc, setDoc } from 'firebase/firestore';
import { db } from '../../firebase/config';
import './ReportsDashboard.css';

const ReportsDashboard = () => {
  const [selectedDate, setSelectedDate] = useState('');
  const [report, setReport] = useState(null);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState({ type: '', text: '' });
  const [allReports, setAllReports] = useState([]);
  const [menu, setMenu] = useState(null);

  useEffect(() => {
    // Set tomorrow as default (since employees select for tomorrow)
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    setSelectedDate(tomorrow.toISOString().split('T')[0]);
    fetchAllReports();
  }, []);

  useEffect(() => {
    if (selectedDate) {
      loadReportForDate(selectedDate);
    }
  }, [selectedDate]);

  const fetchAllReports = async () => {
    try {
      const reportsRef = collection(db, 'reports');
      const snapshot = await getDocs(reportsRef);
      const reports = snapshot.docs.map(doc => ({
        date: doc.id,
        ...doc.data()
      }));
      setAllReports(reports.sort((a, b) => b.date.localeCompare(a.date)));
    } catch (error) {
      console.error('Error fetching reports:', error);
    }
  };

  const loadReportForDate = async (date) => {
    try {
      setLoading(true);
      
      // Load report
      const reportRef = doc(db, 'reports', date);
      const reportSnap = await getDoc(reportRef);

      // Load menu
      const menuRef = doc(db, 'menus', date);
      const menuSnap = await getDoc(menuRef);

      if (reportSnap.exists()) {
        setReport(reportSnap.data());
      } else {
        setReport(null);
      }

      if (menuSnap.exists()) {
        setMenu(menuSnap.data());
      } else {
        setMenu(null);
      }
    } catch (error) {
      console.error('Error loading report:', error);
      showMessage('error', 'Failed to load report');
    } finally {
      setLoading(false);
    }
  };

  const generateReport = async () => {
    if (!selectedDate) {
      showMessage('error', 'Please select a date');
      return;
    }

    try {
      setLoading(true);
      
      // Fetch meal selections for the date
      const selectionsRef = collection(db, 'mealSelections', selectedDate, 'users');
      const snapshot = await getDocs(selectionsRef);

      const counts = { breakfast: 0, lunch: 0, snacks: 0 };
      const participants = [];

      snapshot.forEach(doc => {
        const data = doc.data();
        if (data.breakfast) counts.breakfast++;
        if (data.lunch) counts.lunch++;
        if (data.snacks) counts.snacks++;
        
        participants.push({
          email: data.email,
          breakfast: data.breakfast || false,
          lunch: data.lunch || false,
          snacks: data.snacks || false
        });
      });

      const reportData = {
        ...counts,
        totalParticipants: participants.length,
        generatedAt: new Date().toISOString(),
        participants
      };

      // Save report
      const reportRef = doc(db, 'reports', selectedDate);
      await setDoc(reportRef, reportData);

      setReport(reportData);
      showMessage('success', 'Report generated successfully!');
      fetchAllReports();
    } catch (error) {
      console.error('Error generating report:', error);
      showMessage('error', 'Failed to generate report');
    } finally {
      setLoading(false);
    }
  };

  const exportToCSV = () => {
    if (!report) return;

    const csvRows = [];
    csvRows.push(['Email', 'Breakfast', 'Lunch', 'Snacks']);

    // Initialize counters
    let breakfastCount = 0;
    let lunchCount = 0;
    let snacksCount = 0;

    // Add participant rows and count selections
    report.participants?.forEach(p => {
      csvRows.push([
        p.email,
        p.breakfast ? 'Yes' : 'No',
        p.lunch ? 'Yes' : 'No',
        p.snacks ? 'Yes' : 'No'
      ]);

      // Count selections
      if (p.breakfast) breakfastCount++;
      if (p.lunch) lunchCount++;
      if (p.snacks) snacksCount++;
    });

    // Add empty row for separation
    csvRows.push([]);

    // Add summary section
    csvRows.push(['SUMMARY']);
    csvRows.push(['Total employees', report.totalParticipants || 0]);
    csvRows.push(['Breakfast Count', breakfastCount]);
    csvRows.push(['Lunch Count', lunchCount]);
    csvRows.push(['Snacks Count', snacksCount]);
    csvRows.push(['Total Meals', breakfastCount + lunchCount + snacksCount]);

    const csvContent = csvRows.map(row => row.join(',')).join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `meal-report-${selectedDate}.csv`;
    a.click();
    window.URL.revokeObjectURL(url);
  };

  const showMessage = (type, text) => {
    setMessage({ type, text });
    setTimeout(() => setMessage({ type: '', text: '' }), 5000);
  };

  const formatDate = (dateStr) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', { 
      weekday: 'long', 
      month: 'short', 
      day: 'numeric',
      year: 'numeric'
    });
  };

  const getTotal = () => {
    if (!report) return 0;
    return report.breakfast + report.lunch + report.snacks;
  };

  return (
    <div className="reports-dashboard">
      {message.text && (
        <div className={`message ${message.type}`}>
          {message.type === 'success' && '✓'}
          {message.type === 'error' && '⚠'}
          {' '}{message.text}
        </div>
      )}

      <div className="report-controls">
        <div className="date-selector">
          <label>📅 Select Date</label>
          <input
            type="date"
            value={selectedDate}
            onChange={(e) => setSelectedDate(e.target.value)}
          />
          <span className="selected-date-display">
            {selectedDate && formatDate(selectedDate)}
          </span>
        </div>

        <div className="control-buttons">
          <button
            className="btn btn-primary"
            onClick={generateReport}
            disabled={loading}
          >
            {loading ? 'Generating...' : '🔄 Generate Report'}
          </button>
          
          {report && (
            <button
              className="btn btn-secondary"
              onClick={exportToCSV}
            >
              📥 Export CSV
            </button>
          )}
        </div>
      </div>

      {loading && !report ? (
        <div className="loading-state">
          <div className="spinner"></div>
          <p>Loading report...</p>
        </div>
      ) : !report ? (
        <div className="no-report">
          <div className="empty-state">
            <span className="empty-icon">📊</span>
            <h3>No Report Available</h3>
            <p>Generate a report to see meal selection statistics for {formatDate(selectedDate)}</p>
            <p className="small-text">Click "Generate Report" above to create one</p>
          </div>
        </div>
      ) : (
        <>
          <div className="stats-grid">
            <div className="stat-card breakfast">
              <div className="stat-icon">🌅</div>
              <div className="stat-content">
                <h4>Breakfast</h4>
                <p className="stat-number">{report.breakfast}</p>
                <span className="stat-label">employees</span>
              </div>
            </div>

            <div className="stat-card lunch">
              <div className="stat-icon">🌞</div>
              <div className="stat-content">
                <h4>Lunch</h4>
                <p className="stat-number">{report.lunch}</p>
                <span className="stat-label">employees</span>
              </div>
            </div>

            <div className="stat-card snacks">
              <div className="stat-icon">🌙</div>
              <div className="stat-content">
                <h4>Snacks</h4>
                <p className="stat-number">{report.snacks}</p>
                <span className="stat-label">employees</span>
              </div>
            </div>

            <div className="stat-card total">
              <div className="stat-icon">📊</div>
              <div className="stat-content">
                <h4>Total Meals</h4>
                <p className="stat-number">{getTotal()}</p>
                <span className="stat-label">across all categories</span>
              </div>
            </div>
          </div>

          {menu && (
            <div className="menu-reference">
              <h3>📋 Menu for this day</h3>
              <div className="menu-items-display">
                <div className="menu-column">
                  <h4>🌅 Breakfast</h4>
                  <ul>
                    {menu.breakfast?.map((item, i) => <li key={i}>{item}</li>) || <li>No items</li>}
                  </ul>
                </div>
                <div className="menu-column">
                  <h4>🌞 Lunch</h4>
                  <ul>
                    {menu.lunch?.map((item, i) => <li key={i}>{item}</li>) || <li>No items</li>}
                  </ul>
                </div>
                <div className="menu-column">
                  <h4>🌙 Snacks</h4>
                  <ul>
                    {menu.snacks?.map((item, i) => <li key={i}>{item}</li>) || <li>No items</li>}
                  </ul>
                </div>
              </div>
            </div>
          )}

          {report.participants && report.participants.length > 0 && (
            <div className="participants-table">
              <h3>👥 Participant Details ({report.totalParticipants})</h3>
              <div className="table-wrapper">
                <table>
                  <thead>
                    <tr>
                      <th>#</th>
                      <th>Email</th>
                      <th>🌅 Breakfast</th>
                      <th>🌞 Lunch</th>
                      <th>🌙 Snacks</th>
                    </tr>
                  </thead>
                  <tbody>
                    {report.participants.map((p, index) => (
                      <tr key={index}>
                        <td>{index + 1}</td>
                        <td>{p.email}</td>
                        <td>
                          <span className={`badge ${p.breakfast ? 'yes' : 'no'}`}>
                            {p.breakfast ? '✓' : '×'}
                          </span>
                        </td>
                        <td>
                          <span className={`badge ${p.lunch ? 'yes' : 'no'}`}>
                            {p.lunch ? '✓' : '×'}
                          </span>
                        </td>
                        <td>
                          <span className={`badge ${p.snacks ? 'yes' : 'no'}`}>
                            {p.snacks ? '✓' : '×'}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </>
      )}

      {/* Recent Reports */}
      {allReports.length > 0 && (
        <div className="recent-reports">
          <h3>📚 Recent Reports</h3>
          <div className="reports-list">
            {allReports.slice(0, 5).map(r => (
              <div 
                key={r.date} 
                className="report-card-small"
                onClick={() => setSelectedDate(r.date)}
              >
                <div className="report-date">
                  <strong>{formatDate(r.date)}</strong>
                  <span className="date-code">{r.date}</span>
                </div>
                <div className="report-summary">
                  <span>🌅 {r.breakfast}</span>
                  <span>🌞 {r.lunch}</span>
                  <span>🌙 {r.snacks}</span>
                  <span className="total-badge">{r.breakfast + r.lunch + r.snacks} total</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default ReportsDashboard;
