import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';
import { ShieldAlert, ArrowLeft } from 'lucide-react';

export default function Unauthorized() {
  const { user, role } = useAuth();
  const navigate = useNavigate();

  const getHomePath = () => {
    if (role === 'admin') return '/admin';
    if (role === 'staff') return '/staff';
    return '/student';
  };

  return (
    <div className="auth-page-wrapper">
      <div className="auth-card" style={{ textAlign: 'center' }}>
        <div style={{ display: 'inline-flex', padding: '1rem', background: 'var(--danger-50)', color: 'var(--danger-500)', borderRadius: '50%', marginBottom: '1rem' }}>
          <ShieldAlert size={40} />
        </div>
        <h1>403 — Access Denied</h1>
        <p style={{ color: 'var(--slate-600)', marginBottom: '1.5rem', fontSize: '0.9375rem' }}>
          Your current account role (<strong>{role || 'unassigned'}</strong>) does not have authorization to view this institutional portal.
        </p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          <Link to={getHomePath()} className="btn btn-primary">
            Return to My Portal
          </Link>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => navigate(-1)}
          >
            <ArrowLeft size={16} /> Go Back
          </button>
        </div>
      </div>
    </div>
  );
}
