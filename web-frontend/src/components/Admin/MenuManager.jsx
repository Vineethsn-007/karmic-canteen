// src/components/Admin/MenuManager.jsx
import React, { useState, useEffect } from 'react';
import { doc, setDoc, getDoc, collection, getDocs, deleteDoc } from 'firebase/firestore';
import { db } from '../../firebase/config';
import './MenuManager.css';

const MenuManager = () => {
  const [selectedDate, setSelectedDate] = useState('');
  const [menuItems, setMenuItems] = useState({
    breakfast: [],
    lunch: [],
    snacks: []
  });
  const [currentItem, setCurrentItem] = useState({
    breakfast: '',
    lunch: '',
    snacks: ''
  });
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState({ type: '', text: '' });
  const [existingMenus, setExistingMenus] = useState([]);

  useEffect(() => {
    // Set tomorrow as default date
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    setSelectedDate(tomorrow.toISOString().split('T')[0]);
    
    fetchExistingMenus();
  }, []);

  useEffect(() => {
    if (selectedDate) {
      loadMenuForDate(selectedDate);
    }
  }, [selectedDate]);

  const fetchExistingMenus = async () => {
    try {
      const menusRef = collection(db, 'menus');
      const snapshot = await getDocs(menusRef);
      const menus = snapshot.docs.map(doc => ({
        date: doc.id,
        ...doc.data()
      }));
      setExistingMenus(menus.sort((a, b) => b.date.localeCompare(a.date)));
    } catch (error) {
      console.error('Error fetching menus:', error);
    }
  };

  const loadMenuForDate = async (date) => {
    try {
      setLoading(true);
      const menuRef = doc(db, 'menus', date);
      const menuSnap = await getDoc(menuRef);

      if (menuSnap.exists()) {
        const data = menuSnap.data();
        setMenuItems({
          breakfast: data.breakfast || [],
          lunch: data.lunch || [],
          snacks: data.snacks || []
        });
        showMessage('info', `Loaded existing menu for ${formatDate(date)}`);
      } else {
        // Clear menu items for new date
        setMenuItems({
          breakfast: [],
          lunch: [],
          snacks: []
        });
        showMessage('info', `Creating new menu for ${formatDate(date)}`);
      }
    } catch (error) {
      console.error('Error loading menu:', error);
      showMessage('error', 'Failed to load menu');
    } finally {
      setLoading(false);
    }
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

  const handleAddItem = (mealType) => {
    const item = currentItem[mealType].trim();
    if (!item) {
      showMessage('error', 'Please enter an item name');
      return;
    }

    if (menuItems[mealType].includes(item)) {
      showMessage('error', 'This item already exists in the menu');
      return;
    }

    setMenuItems(prev => ({
      ...prev,
      [mealType]: [...prev[mealType], item]
    }));

    setCurrentItem(prev => ({
      ...prev,
      [mealType]: ''
    }));
  };

  const handleRemoveItem = (mealType, index) => {
    setMenuItems(prev => ({
      ...prev,
      [mealType]: prev[mealType].filter((_, i) => i !== index)
    }));
  };

  const handleSaveMenu = async () => {
    if (!selectedDate) {
      showMessage('error', 'Please select a date');
      return;
    }

    const totalItems = menuItems.breakfast.length + menuItems.lunch.length + menuItems.snacks.length;
    if (totalItems === 0) {
      showMessage('error', 'Please add at least one menu item');
      return;
    }

    try {
      setLoading(true);
      const menuRef = doc(db, 'menus', selectedDate);
      await setDoc(menuRef, menuItems);
      
      showMessage('success', `Menu saved successfully for ${formatDate(selectedDate)}!`);
      fetchExistingMenus(); // Refresh the list
    } catch (error) {
      console.error('Error saving menu:', error);
      showMessage('error', 'Failed to save menu. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteMenu = async (date) => {
    if (!window.confirm(`Are you sure you want to delete the menu for ${formatDate(date)}?`)) {
      return;
    }

    try {
      const menuRef = doc(db, 'menus', date);
      await deleteDoc(menuRef);
      
      showMessage('success', 'Menu deleted successfully');
      fetchExistingMenus();
      
      if (date === selectedDate) {
        setMenuItems({
          breakfast: [],
          lunch: [],
          snacks: []
        });
      }
    } catch (error) {
      console.error('Error deleting menu:', error);
      showMessage('error', 'Failed to delete menu');
    }
  };

  const showMessage = (type, text) => {
    setMessage({ type, text });
    setTimeout(() => setMessage({ type: '', text: '' }), 5000);
  };

  const getTotalItems = () => {
    return menuItems.breakfast.length + menuItems.lunch.length + menuItems.snacks.length;
  };

  return (
    <div className="menu-manager">
      {message.text && (
        <div className={`message ${message.type}`}>
          {message.type === 'success' && '✓'}
          {message.type === 'error' && '⚠'}
          {message.type === 'info' && 'ℹ'}
          {' '}{message.text}
        </div>
      )}

      <div className="menu-editor">
        <div className="editor-header">
          <div className="date-selector">
            <label>📅 Select Date</label>
            <input
              type="date"
              value={selectedDate}
              onChange={(e) => setSelectedDate(e.target.value)}
              min={new Date().toISOString().split('T')[0]}
            />
            <span className="selected-date-display">
              {selectedDate && formatDate(selectedDate)}
            </span>
          </div>

          <div className="menu-stats">
            <div className="stat-box">
              <span className="stat-label">Total Items</span>
              <span className="stat-value">{getTotalItems()}</span>
            </div>
          </div>
        </div>

        <div className="meals-editor">
          {/* Breakfast Section */}
          <div className="meal-section">
            <div className="meal-section-header">
              <h3>🌅 Breakfast</h3>
              <span className="item-count">{menuItems.breakfast.length} items</span>
            </div>

            <div className="add-item-form">
              <input
                type="text"
                placeholder="Add breakfast item (e.g., Idli, Sambar)"
                value={currentItem.breakfast}
                onChange={(e) => setCurrentItem(prev => ({ ...prev, breakfast: e.target.value }))}
                onKeyPress={(e) => e.key === 'Enter' && handleAddItem('breakfast')}
              />
              <button 
                className="btn btn-primary"
                onClick={() => handleAddItem('breakfast')}
              >
                Add
              </button>
            </div>

            <div className="items-list">
              {menuItems.breakfast.length === 0 ? (
                <p className="empty-list">No breakfast items added yet</p>
              ) : (
                menuItems.breakfast.map((item, index) => (
                  <div key={index} className="item-tag">
                    <span>{item}</span>
                    <button 
                      className="remove-btn"
                      onClick={() => handleRemoveItem('breakfast', index)}
                    >
                      ×
                    </button>
                  </div>
                ))
              )}
            </div>
          </div>

          {/* Lunch Section */}
          <div className="meal-section">
            <div className="meal-section-header">
              <h3>🌞 Lunch</h3>
              <span className="item-count">{menuItems.lunch.length} items</span>
            </div>

            <div className="add-item-form">
              <input
                type="text"
                placeholder="Add lunch item (e.g., Rice, Dal, Sabzi)"
                value={currentItem.lunch}
                onChange={(e) => setCurrentItem(prev => ({ ...prev, lunch: e.target.value }))}
                onKeyPress={(e) => e.key === 'Enter' && handleAddItem('lunch')}
              />
              <button 
                className="btn btn-primary"
                onClick={() => handleAddItem('lunch')}
              >
                Add
              </button>
            </div>

            <div className="items-list">
              {menuItems.lunch.length === 0 ? (
                <p className="empty-list">No lunch items added yet</p>
              ) : (
                menuItems.lunch.map((item, index) => (
                  <div key={index} className="item-tag">
                    <span>{item}</span>
                    <button 
                      className="remove-btn"
                      onClick={() => handleRemoveItem('lunch', index)}
                    >
                      ×
                    </button>
                  </div>
                ))
              )}
            </div>
          </div>

          {/* Snacks Section */}
          <div className="meal-section">
            <div className="meal-section-header">
              <h3>🌙 Snacks</h3>
              <span className="item-count">{menuItems.snacks.length} items</span>
            </div>

            <div className="add-item-form">
              <input
                type="text"
                placeholder="Add snacks item (e.g., Tea, Biscuits)"
                value={currentItem.snacks}
                onChange={(e) => setCurrentItem(prev => ({ ...prev, snacks: e.target.value }))}
                onKeyPress={(e) => e.key === 'Enter' && handleAddItem('snacks')}
              />
              <button 
                className="btn btn-primary"
                onClick={() => handleAddItem('snacks')}
              >
                Add
              </button>
            </div>

            <div className="items-list">
              {menuItems.snacks.length === 0 ? (
                <p className="empty-list">No snacks items added yet</p>
              ) : (
                menuItems.snacks.map((item, index) => (
                  <div key={index} className="item-tag">
                    <span>{item}</span>
                    <button 
                      className="remove-btn"
                      onClick={() => handleRemoveItem('snacks', index)}
                    >
                      ×
                    </button>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>

        <div className="save-section">
          <button
            className="btn btn-primary btn-large"
            onClick={handleSaveMenu}
            disabled={loading || getTotalItems() === 0}
          >
            {loading ? 'Saving...' : 'Save Menu'}
          </button>
        </div>
      </div>

      {/* Existing Menus List */}
      <div className="existing-menus">
        <h3>📚 Existing Menus</h3>
        {existingMenus.length === 0 ? (
          <p className="empty-state">No menus created yet</p>
        ) : (
          <div className="menus-list">
            {existingMenus.map(menu => (
              <div key={menu.date} className="menu-card-small">
                <div className="menu-card-header">
                  <h4>{formatDate(menu.date)}</h4>
                  <span className="menu-date-code">{menu.date}</span>
                </div>
                <div className="menu-summary">
                  <span>🌅 {menu.breakfast?.length || 0}</span>
                  <span>🌞 {menu.lunch?.length || 0}</span>
                  <span>🌙 {menu.snacks?.length || 0}</span>
                </div>
                <div className="menu-actions">
                  <button
                    className="btn btn-secondary btn-sm"
                    onClick={() => setSelectedDate(menu.date)}
                  >
                    Edit
                  </button>
                  <button
                    className="btn btn-secondary btn-sm delete-btn"
                    onClick={() => handleDeleteMenu(menu.date)}
                  >
                    Delete
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default MenuManager;
