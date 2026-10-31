import React from 'react';
import { Outlet } from 'react-router-dom';
import { Compass } from 'lucide-react';

export default function AuthLayout() {
  return (
    <div className="auth-page-wrapper">
      <div className="auth-card">
        <div className="auth-header">
          <div style={{ display: 'inline-flex', padding: '0.625rem', background: 'var(--primary-50)', borderRadius: 'var(--radius-lg)', color: 'var(--primary-600)', marginBottom: '0.5rem' }}>
            <Compass size={32} />
          </div>
          <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--slate-900)', letterSpacing: '-0.02em' }}>
            UniFlow
          </div>
          <p style={{ fontSize: '0.8125rem', color: 'var(--slate-500)', marginTop: '0.25rem', marginBottom: 0 }}>
            Students don't navigate departments. They navigate journeys.
          </p>
        </div>
        <Outlet />
      </div>
    </div>
  );
}
