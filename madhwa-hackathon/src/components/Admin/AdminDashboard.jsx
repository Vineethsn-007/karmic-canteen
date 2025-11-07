// src/components/Admin/AdminDashboard.jsx
import React from 'react';
import { Routes, Route, NavLink, Navigate } from 'react-router-dom';
import AnalyticsDashboard from './AnalyticsDashboard';
import MenuManager from './MenuManager';
import ReportsDashboard from './ReportsDashboard';
import AdminSettings from './AdminSettings';
import './AdminDashboard.css';

const AdminDashboard = () => {
  return (
    <div className="admin-dashboard">
      <div className="admin-header">
        <h1>⚙️ Admin Dashboard</h1>
        <p className="subtitle">Manage menus and view reports</p>
      </div>

      <div className="admin-tabs">
        <NavLink 
          to="/admin/analytics" 
          className={({ isActive }) => isActive ? 'tab active' : 'tab'}
        >
          📊 Analytics
        </NavLink>
        <NavLink 
          to="/admin/menu" 
          className={({ isActive }) => isActive ? 'tab active' : 'tab'}
        >
          🍽️ Menu
        </NavLink>
        <NavLink 
          to="/admin/reports" 
          className={({ isActive }) => isActive ? 'tab active' : 'tab'}
        >
          📈 Reports
        </NavLink>
        <NavLink 
          to="/admin/settings" 
          className={({ isActive }) => isActive ? 'tab active' : 'tab'}
        >
          ⚙️ Settings
        </NavLink>
      </div>

      <div className="admin-content">
        <Routes>
          <Route index element={<Navigate to="analytics" replace />} />
          <Route path="analytics" element={<AnalyticsDashboard />} />
          <Route path="menu" element={<MenuManager />} />
          <Route path="reports" element={<ReportsDashboard />} />
          <Route path="settings" element={<AdminSettings />} />
        </Routes>
      </div>
    </div>
  );
};

export default AdminDashboard;
