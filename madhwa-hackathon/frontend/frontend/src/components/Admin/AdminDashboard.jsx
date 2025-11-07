// src/components/Admin/AdminDashboard.jsx
import React from 'react';
import { Routes, Route, NavLink, Navigate } from 'react-router-dom';
import MenuManager from './MenuManager';
import ReportsDashboard from './ReportsDashboard';
import './AdminDashboard.css';

const AdminDashboard = () => {
  return (
    <div className="admin-dashboard">
      <div className="admin-header">
        <h1>Admin Dashboard</h1>
        <p className="subtitle">Manage menus and view reports</p>
      </div>

      <div className="admin-tabs">
        <NavLink 
          to="/admin/menu" 
          className={({ isActive }) => isActive ? 'tab active' : 'tab'}
        >
          📋 Menu Management
        </NavLink>
        <NavLink 
          to="/admin/reports" 
          className={({ isActive }) => isActive ? 'tab active' : 'tab'}
        >
          📊 Reports & Analytics
        </NavLink>
      </div>

      <div className="admin-content">
        <Routes>
          <Route index element={<Navigate to="menu" replace />} />
          <Route path="menu" element={<MenuManager />} />
          <Route path="reports" element={<ReportsDashboard />} />
        </Routes>
      </div>
    </div>
  );
};

export default AdminDashboard;
