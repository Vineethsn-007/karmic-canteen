import React, { useState, useEffect } from 'react';
import { collection, addDoc, getDocs, deleteDoc, doc, query, orderBy, limit } from 'firebase/firestore';
import { db } from '../../firebase/config';
import './FestivalAnnouncements.css';

const FestivalAnnouncements = () => {
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [announcements, setAnnouncements] = useState([]);
  const [loading, setLoading] = useState(false);
  const [statusMessage, setStatusMessage] = useState({ type: '', text: '' });

  useEffect(() => {
    fetchAnnouncements();
  }, []);

  const fetchAnnouncements = async () => {
    try {
      const announcementsRef = collection(db, 'announcements');
      const q = query(announcementsRef, orderBy('timestamp', 'desc'), limit(10));
      const snapshot = await getDocs(q);
      const announcementsList = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setAnnouncements(announcementsList);
    } catch (error) {
      console.error('Error fetching announcements:', error);
    }
  };

  const handleSendAnnouncement = async () => {
    if (!title.trim() || !message.trim()) {
      showMessage('error', 'Please fill in both title and message');
      return;
    }

    try {
      setLoading(true);
      
      // Save announcement to Firestore
      const announcementData = {
        title: title.trim(),
        message: message.trim(),
        timestamp: new Date().toISOString(),
        sentBy: 'admin'
      };

      await addDoc(collection(db, 'announcements'), announcementData);

      // Send browser notification to all users (they'll receive it if they have the app open)
      if ('Notification' in window && Notification.permission === 'granted') {
        new Notification('🎉 ' + title, {
          body: message,
          icon: '/vite.svg',
          tag: 'festival-announcement',
          requireInteraction: true
        });
      }

      showMessage('success', '✓ Announcement sent successfully!');
      setTitle('');
      setMessage('');
      fetchAnnouncements();
    } catch (error) {
      console.error('Error sending announcement:', error);
      showMessage('error', 'Failed to send announcement');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteAnnouncement = async (id) => {
    if (!window.confirm('Are you sure you want to delete this announcement?')) {
      return;
    }

    try {
      await deleteDoc(doc(db, 'announcements', id));
      showMessage('success', 'Announcement deleted');
      fetchAnnouncements();
    } catch (error) {
      console.error('Error deleting announcement:', error);
      showMessage('error', 'Failed to delete announcement');
    }
  };

  const showMessage = (type, text) => {
    setStatusMessage({ type, text });
    setTimeout(() => setStatusMessage({ type: '', text: '' }), 5000);
  };

  const formatDate = (dateStr) => {
    const date = new Date(dateStr);
    return date.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  return (
    <div className="festival-announcements">
      <div className="announcements-header">
        <h2>📢 Festival & Event Announcements</h2>
        <p className="subtitle">Send notifications to all employees</p>
      </div>

      {statusMessage.text && (
        <div className={`message ${statusMessage.type}`}>
          {statusMessage.type === 'success' && '✓'}
          {statusMessage.type === 'error' && '⚠'}
          {' '}{statusMessage.text}
        </div>
      )}

      <div className="announcement-form">
        <h3>📝 Create New Announcement</h3>
        
        <div className="form-group">
          <label>Title</label>
          <input
            type="text"
            placeholder="e.g., Diwali Celebration, Holi Special Menu"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            maxLength={100}
          />
        </div>

        <div className="form-group">
          <label>Message</label>
          <textarea
            placeholder="Enter your announcement message..."
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            rows={5}
            maxLength={500}
          />
          <span className="char-count">{message.length}/500</span>
        </div>

        <button
          className="btn btn-primary btn-large"
          onClick={handleSendAnnouncement}
          disabled={loading || !title.trim() || !message.trim()}
        >
          {loading ? 'Sending...' : '📤 Send Announcement'}
        </button>

        <div className="info-box">
          <strong>ℹ️ Note:</strong> This announcement will be saved and visible to all employees. 
          Users with notifications enabled will receive a browser notification.
        </div>
      </div>

      <div className="announcements-history">
        <h3>📚 Recent Announcements</h3>
        
        {announcements.length === 0 ? (
          <div className="empty-state">
            <p>No announcements yet. Create your first announcement above!</p>
          </div>
        ) : (
          <div className="announcements-list">
            {announcements.map(announcement => (
              <div key={announcement.id} className="announcement-card">
                <div className="announcement-header">
                  <h4>{announcement.title}</h4>
                  <button
                    className="delete-btn"
                    onClick={() => handleDeleteAnnouncement(announcement.id)}
                    title="Delete announcement"
                  >
                    🗑️
                  </button>
                </div>
                <p className="announcement-message">{announcement.message}</p>
                <div className="announcement-footer">
                  <span className="timestamp">📅 {formatDate(announcement.timestamp)}</span>
                  <span className="sent-by">Sent by: {announcement.sentBy}</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default FestivalAnnouncements;
