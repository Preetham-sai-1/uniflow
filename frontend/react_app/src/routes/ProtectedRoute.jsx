import React from 'react';
import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';
import { Spinner } from '../components/common/Components.jsx';

export default function ProtectedRoute() {
  const { isAuthenticated, loading } = useAuth();
  const location = useLocation();

  if (loading) {
    return (
      <div className="loading-screen">
        <Spinner size="lg" />
        <p style={{ color: 'var(--slate-500)', fontSize: '0.875rem' }}>Verifying session...</p>
      </div>
    );
  }

  if (!isAuthenticated) {
    // Preserve requested route for redirect after login
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return <Outlet />;
}
