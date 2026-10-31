import React, { useState } from 'react';
import { Link, NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext.jsx';
import { Badge } from '../common/Components.jsx';
import { LogOut, User, Compass, Menu, X } from 'lucide-react';

export default function Navbar() {
  const { user, role, logout } = useAuth();
  const navigate = useNavigate();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const getRoleBadgeVariant = (userRole) => {
    switch (userRole) {
      case 'student': return 'student';
      case 'staff': return 'staff';
      case 'admin': return 'admin';
      default: return 'info';
    }
  };

  const closeMobileMenu = () => setMobileMenuOpen(false);

  return (
    <header className="navbar">
      <div className="navbar-inner">
        {/* Brand */}
        <Link to="/" className="brand" onClick={closeMobileMenu}>
          <div className="brand-icon">
            <Compass size={22} />
          </div>
          <div>
            <span className="brand-text">UniFlow</span>
            <span className="brand-tagline">Campus Journey Engine</span>
          </div>
        </Link>

        {/* Desktop Nav Links based on Role */}
        <nav className="nav-links desktop-only" style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          {role === 'student' && (
            <>
              <NavLink
                to="/student"
                end
                className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}
              >
                Dashboard
              </NavLink>
              <NavLink
                to="/student/services"
                className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}
              >
                Services
              </NavLink>
            </>
          )}

          {role === 'staff' && (
            <>
              <NavLink
                to="/staff"
                end
                className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}
              >
                Review Queue
              </NavLink>
            </>
          )}

          {role === 'admin' && (
            <>
              <NavLink
                to="/admin"
                end
                className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}
              >
                Admin Overview
              </NavLink>
              <NavLink
                to="/staff"
                end
                className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}
              >
                Staff Queue
              </NavLink>
            </>
          )}

          {/* User info & Logout */}
          {user && (
            <div className="user-badge-group" style={{ marginLeft: '1rem', borderLeft: '1px solid var(--slate-200)', paddingLeft: '1rem' }}>
              <div className="user-info">
                <div className="user-name">{user.name}</div>
                <Badge variant={getRoleBadgeVariant(role)}>{role}</Badge>
              </div>
              <button
                type="button"
                className="btn btn-secondary"
                style={{ padding: '0.4rem 0.75rem', fontSize: '0.8125rem' }}
                onClick={handleLogout}
                title="Log out"
                aria-label="Log out"
              >
                <LogOut size={16} />
                <span className="desktop-text">Logout</span>
              </button>
            </div>
          )}
        </nav>
      </div>
    </header>
  );
}
