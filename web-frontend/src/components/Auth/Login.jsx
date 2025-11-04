// src/components/Auth/Login.js
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import './Login.css';

const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

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
          setError('No account found with this email.');
          break;
        case 'auth/wrong-password':
          setError('Incorrect password. Please try again.');
          break;
        case 'auth/invalid-credential':
          setError('Invalid email or password.');
          break;
        case 'auth/too-many-requests':
          setError('Too many failed attempts. Please try again later.');
          break;
        case 'auth/network-request-failed':
          setError('Network error. Please check your connection.');
          break;
        default:
          setError('Failed to login. Please check your credentials.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="login-card">
        <h1>🍽️ Karmic Canteen</h1>
        <p className="subtitle">Sign in with your credentials</p>
        
        {error && <div className="error-message">{error}</div>}
        
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="your.email@karmicsolutions.com"
              required
              autoComplete="email"
            />
          </div>
          
          <div className="form-group">
            <label>Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
              autoComplete="current-password"
            />
          </div>
          
          <button 
            type="submit" 
            className="btn btn-primary btn-full"
            disabled={loading}
          >
            {loading ? 'Signing in...' : 'Sign In'}
          </button>
        </form>

        {/* Development Helper - Remove in production */}
        {process.env.NODE_ENV === 'development' && (
          <div className="test-credentials">
            <p style={{ fontSize: '12px', color: '#666', marginTop: '16px' }}>
              Quick Test Login:
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
                Employee (Jane)
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
                Admin (John)
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Login;
