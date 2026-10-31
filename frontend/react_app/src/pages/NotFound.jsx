import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';
import { FileQuestion, Home } from 'lucide-react';

export default function NotFound() {
  const { isAuthenticated, role } = useAuth();

  const getHomePath = () => {
    if (!isAuthenticated) return '/login';
    if (role === 'admin') return '/admin';
    if (role === 'staff') return '/staff';
    return '/student';
  };

  return (
    <div className="auth-page-wrapper">
      <div className="auth-card" style={{ textAlign: 'center' }}>
        <div style={{ display: 'inline-flex', padding: '1rem', background: 'var(--slate-100)', color: 'var(--slate-500)', borderRadius: '50%', marginBottom: '1rem' }}>
          <FileQuestion size={40} />
        </div>
        <h1>404 — Page Not Found</h1>
        <p style={{ color: 'var(--slate-600)', marginBottom: '1.5rem', fontSize: '0.9375rem' }}>
          The requested page or journey step could not be found.
        </p>

        <Link to={getHomePath()} className="btn btn-primary" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.5rem' }}>
          <Home size={18} />
          Go to Home
        </Link>
      </div>
    </div>
  );
}
