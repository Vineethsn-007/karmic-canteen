// src/components/Layout/Navbar.jsx
import React, { useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import LanguageSwitcher from '../LanguageSwitcher/LanguageSwitcher';
import './Navbar.css';

const Navbar = () => {
  const { currentUser, logout, userRole } = useAuth();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const handleLogout = async () => {
    try {
      await logout();
      navigate('/login');
    } catch (error) {
      console.error('Failed to logout', error);
    }
  };

  // Close mobile menu when user performs action
  const handleMenuItemClick = () => {
    setIsMobileMenuOpen(false);
  };

  return (
    <nav className="navbar">
      <div className="navbar-container">
        {/* Logo & Brand */}
        <div className="navbar-brand">
          <img
            src="/logo.png"
            alt="Karmic Canteen Logo"
            className="navbar-logo"
          />
          <div className="brand-text">
            <h1>{t('common.appName')}</h1>
            <span className={`role-badge ${userRole}`}>
              {userRole === 'admin' ? `👑 ${t('navbar.roleAdmin')}` : `👤 ${t('navbar.roleEmployee')}`}
            </span>
          </div>
        </div>

        {/* Mobile Menu Toggle */}
        <button
          className="mobile-menu-toggle"
          onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
          aria-label="Toggle menu"
          aria-expanded={isMobileMenuOpen}
        >
          <span className="hamburger-icon"></span>
          <span className="hamburger-icon"></span>
          <span className="hamburger-icon"></span>
        </button>

        {/* Navbar Actions */}
        <div className={`navbar-actions ${isMobileMenuOpen ? 'mobile-open' : ''}`}>
          <div className="user-info">
            <span className="user-email" title={currentUser?.email}>
              {currentUser?.email}
            </span>
          </div>
          
          {/* Language Switcher */}
          <LanguageSwitcher />
          
          <button
            onClick={() => {
              handleLogout();
              handleMenuItemClick();
            }}
            className="btn btn-secondary"
            aria-label={t('auth.logout')}
          >
            {t('auth.logout')}
          </button>
        </div>
      </div>
    </nav>
  );
};

export default Navbar;
