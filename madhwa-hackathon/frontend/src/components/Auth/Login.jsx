// src/components/Auth/Login.js
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { useTranslation } from 'react-i18next';
import LanguageSwitcher from '../LanguageSwitcher/LanguageSwitcher';
import './Login.css';

const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();
  const { t } = useTranslation();

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    try {
      setError('');
      setLoading(true);
      await login(email, password);
      
      // Navigation will be handled by App.js based on role
      // User will be automatically redirected after successful login
      
    } catch (err) {
      console.error('Login error:', err);
      
      // User-friendly error messages
      switch (err.code) {
        case 'auth/user-not-found':
          setError(t('auth.noAccount'));
          break;
        case 'auth/wrong-password':
          setError(t('auth.incorrectPassword'));
          break;
        case 'auth/invalid-credential':
          setError(t('auth.invalidCredentials'));
          break;
        case 'auth/too-many-requests':
          setError(t('auth.tooManyAttempts') || 'Too many failed attempts. Please try again later.');
          break;
        case 'auth/network-request-failed':
          setError(t('auth.networkError'));
          break;
        default:
          setError(t('auth.loginError'));
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      {/* Language Selector */}
      <div className="login-language-selector">
        <LanguageSwitcher />
      </div>

      <div className="login-card">
        <div className="login-header">
          <img src="/logo.png" alt="Karmic Canteen Logo" className="login-logo" />
          <h1>{t('common.appName')}</h1>
        </div>
        <p className="subtitle">{t('Good food good taste')}</p>
        
        {error && <div className="error-message">{error}</div>}
        
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>{t('auth.email')}</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder={t('Your email')}
              required
              autoComplete="email"
            />
          </div>
          
          <div className="form-group">
            <label>{t('auth.password')}</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder={t('Your password')}
              required
              autoComplete="current-password"
            />
          </div>
          
          <button 
            type="submit" 
            className="btn btn-primary btn-full"
            disabled={loading}
          >
            {loading ? t('Signing in') : t('Sign In')}
          </button>
        </form>

        {/* Development Helper - Remove in production */}
        {process.env.NODE_ENV === 'development' && (
          <div className="test-credentials">
            <p style={{ fontSize: '12px', color: '#666', marginTop: '16px' }}>
              {t('Test logins')}
            </p>
            <div style={{ display: 'flex', gap: '8px', marginTop: '8px' }}>
              <button
                type="button"
                className="btn btn-secondary"
                onClick={() => {
                  setEmail('jane.smith@karmicsolutions.com');
                  setPassword('karmic123');
                }}
                style={{ fontSize: '12px', padding: '6px 12px', flex: 1 }}
              >
                {t('auth.employee')}
              </button>
              <button
                type="button"
                className="btn btn-secondary"
                onClick={() => {
                  setEmail('john.doe@karmicsolutions.com');
                  setPassword('karmic123');
                }}
                style={{ fontSize: '12px', padding: '6px 12px', flex: 1 }}
              >
                {t('auth.admin')}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Login;
