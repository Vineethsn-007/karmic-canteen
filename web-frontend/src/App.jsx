// src/App.jsx
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import Login from './components/Auth/Login';
import EmployeeDashboard from './components/Employee/EmployeeDashboard';
import AdminDashboard from './components/Admin/AdminDashboard';
import Navbar from './components/Layout/Navbar';
import './App.css';

// Protected Route Component
const ProtectedRoute = ({ children, requiredRole }) => {
  const { currentUser, userRole, loading } = useAuth();

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Loading...</p>
      </div>
    );
  }

  if (!currentUser) {
    return <Navigate to="/login" replace />;
  }

  if (requiredRole && userRole !== requiredRole) {
    // Redirect to correct dashboard based on actual role
    if (userRole === 'admin') {
      return <Navigate to="/admin" replace />;
    } else {
      return <Navigate to="/employee" replace />;
    }
  }

  return children;
};

// Main App Component
function AppContent() {
  const { currentUser, userRole, loading } = useAuth();

  // Show loading spinner while checking auth
  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Loading...</p>
      </div>
    );
  }

  return (
    <Router>
      <div className="app">
        {currentUser && <Navbar />}
        
        <div className="main-content">
          <Routes>
            {/* Public Route - Login */}
            <Route 
              path="/login" 
              element={
                currentUser ? (
                  // Redirect based on role after login
                  userRole === 'admin' ? (
                    <Navigate to="/admin" replace />
                  ) : (
                    <Navigate to="/employee" replace />
                  )
                ) : (
                  <Login />
                )
              } 
            />

            {/* Home Route - Redirects based on role */}
            <Route
              path="/"
              element={
                <ProtectedRoute>
                  {userRole === 'admin' ? (
                    <Navigate to="/admin" replace />
                  ) : (
                    <Navigate to="/employee" replace />
                  )}
                </ProtectedRoute>
              }
            />

            {/* Employee Routes - Only accessible by employees */}
            <Route
              path="/employee/*"
              element={
                <ProtectedRoute requiredRole="employee">
                  <EmployeeDashboard />
                </ProtectedRoute>
              }
            />

            {/* Admin Routes - Only accessible by admins */}
            <Route
              path="/admin/*"
              element={
                <ProtectedRoute requiredRole="admin">
                  <AdminDashboard />
                </ProtectedRoute>
              }
            />

            {/* 404 Route - Redirect to appropriate dashboard */}
            <Route 
              path="*" 
              element={
                currentUser ? (
                  <Navigate to="/" replace />
                ) : (
                  <Navigate to="/login" replace />
                )
              } 
            />
          </Routes>
        </div>
      </div>
    </Router>
  );
}

function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}

export default App;
