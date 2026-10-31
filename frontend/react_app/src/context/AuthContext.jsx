/**
 * src/context/AuthContext.jsx
 *
 * Centralized React Authentication Context.
 * Manages token lifecycle, user state, session persistence, and logout events.
 */

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import * as authApi from '../api/authApi.js';

export const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    try {
      const stored = localStorage.getItem('uniflow_user');
      return stored ? JSON.parse(stored) : null;
    } catch {
      return null;
    }
  });

  const [token, setToken] = useState(() => localStorage.getItem('uniflow_token') || null);
  const [loading, setLoading] = useState(true);
  const [authError, setAuthError] = useState(null);

  // Clear session locally
  const logout = useCallback(() => {
    localStorage.removeItem('uniflow_token');
    localStorage.removeItem('uniflow_user');
    setToken(null);
    setUser(null);
    setAuthError(null);
  }, []);

  // Save session to storage & state
  const saveSession = useCallback((newToken, newUser) => {
    localStorage.setItem('uniflow_token', newToken);
    localStorage.setItem('uniflow_user', JSON.stringify(newUser));
    setToken(newToken);
    setUser(newUser);
    setAuthError(null);
  }, []);

  // Validate stored session on mount
  useEffect(() => {
    let isMounted = true;

    async function initSession() {
      const storedToken = localStorage.getItem('uniflow_token');
      if (!storedToken) {
        if (isMounted) setLoading(false);
        return;
      }

      try {
        const freshUser = await authApi.getCurrentUser();
        if (isMounted) {
          setUser(freshUser);
          localStorage.setItem('uniflow_user', JSON.stringify(freshUser));
        }
      } catch (err) {
        // Token invalid or expired — clear stored session
        if (isMounted) {
          logout();
        }
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    }

    initSession();

    // Listen for auth expiration events dispatched by the Axios interceptor
    const handleAuthExpired = () => logout();
    window.addEventListener('uniflow_auth_expired', handleAuthExpired);

    return () => {
      isMounted = false;
      window.removeEventListener('uniflow_auth_expired', handleAuthExpired);
    };
  }, [logout]);

  // Login handler
  const login = useCallback(
    async (email, password) => {
      setAuthError(null);
      try {
        const data = await authApi.loginUser({ email, password });
        saveSession(data.token, data.user);
        return { success: true, user: data.user };
      } catch (err) {
        const message = err.message || 'Login failed. Please check your credentials.';
        setAuthError(message);
        throw err;
      }
    },
    [saveSession]
  );

  // Student registration handler
  const register = useCallback(
    async ({ name, email, password, studentId }) => {
      setAuthError(null);
      try {
        const data = await authApi.registerStudent({ name, email, password, studentId });
        saveSession(data.token, data.user);
        return { success: true, user: data.user };
      } catch (err) {
        const message = err.message || 'Registration failed. Please check the input fields.';
        setAuthError(message);
        throw err;
      }
    },
    [saveSession]
  );

  const value = {
    user,
    token,
    role: user?.role || null,
    isAuthenticated: Boolean(token && user),
    loading,
    authError,
    setAuthError,
    login,
    register,
    logout,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
