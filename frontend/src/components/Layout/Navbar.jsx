// src/components/Layout/Navbar.js
import React from 'react';
import { useAuth } from '../../context/AuthContext';
import './Navbar.css';

const Navbar = () => {
  const { currentUser, logout, userRole } = useAuth();

  const handleLogout = async () => {
    try {
      await logout();
    } catch (error) {
      console.error('Failed to logout', error);
    }
  };

  return (
    <nav className="navbar">
      <div className="navbar-content">
        <div className="navbar-brand">
          <h2>🍽️ Karmic Canteen</h2>
          {userRole && (
            <span className={`role-badge ${userRole}`}>
              {userRole === 'admin' ? '👑 Admin' : '👤 Employee'}
            </span>
          )}
        </div>
        
        <div className="navbar-actions">
          <span className="user-email">{currentUser?.email}</span>
          <button onClick={handleLogout} className="btn btn-secondary">
            Logout
          </button>
        </div>
      </div>
    </nav>
  );
};

export default Navbar;
