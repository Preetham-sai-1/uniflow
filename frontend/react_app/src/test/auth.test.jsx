import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { AuthProvider, useAuth } from '../context/AuthContext.jsx';
import Login from '../pages/auth/Login.jsx';
import Register from '../pages/auth/Register.jsx';
import * as authApi from '../api/authApi.js';

// Mock authApi module
vi.mock('../api/authApi.js');

describe('Auth Pages & Validation', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    localStorage.clear();
  });

  describe('Login Form Validation & Execution', () => {
    it('shows validation errors when submitting empty fields', async () => {
      render(
        <MemoryRouter>
          <AuthProvider>
            <Login />
          </AuthProvider>
        </MemoryRouter>
      );

      const submitBtn = screen.getByRole('button', { name: /sign in/i });
      await userEvent.click(submitBtn);

      expect(screen.getByText(/email address is required/i)).toBeInTheDocument();
      expect(screen.getByText(/password is required/i)).toBeInTheDocument();
      expect(authApi.loginUser).not.toHaveBeenCalled();
    });

    it('shows validation error for invalid email format', async () => {
      render(
        <MemoryRouter>
          <AuthProvider>
            <Login />
          </AuthProvider>
        </MemoryRouter>
      );

      const emailInput = screen.getByLabelText(/institutional email/i);
      const passwordInput = screen.getByLabelText(/^password/i);
      const submitBtn = screen.getByRole('button', { name: /sign in/i });

      await userEvent.type(emailInput, 'invalid-email');
      await userEvent.type(passwordInput, 'ValidPassword123');
      await userEvent.click(submitBtn);

      expect(screen.getByText(/please enter a valid email address/i)).toBeInTheDocument();
      expect(authApi.loginUser).not.toHaveBeenCalled();
    });

    it('calls login API and sets session on valid credentials', async () => {
      const mockUser = {
        id: '64a1b2c3d4e5f6a7b8c9d001',
        name: 'Arjun Sharma',
        email: 'arjun@college.edu',
        role: 'student',
      };

      authApi.loginUser.mockResolvedValueOnce({
        token: 'mock.jwt.token',
        user: mockUser,
      });

      render(
        <MemoryRouter>
          <AuthProvider>
            <Login />
          </AuthProvider>
        </MemoryRouter>
      );

      await userEvent.type(screen.getByLabelText(/institutional email/i), 'arjun@college.edu');
      await userEvent.type(screen.getByLabelText(/^password/i), 'SecurePassword123!');
      await userEvent.click(screen.getByRole('button', { name: /sign in/i }));

      await waitFor(() => {
        expect(authApi.loginUser).toHaveBeenCalledWith({
          email: 'arjun@college.edu',
          password: 'SecurePassword123!',
        });
      });

      expect(localStorage.getItem('uniflow_token')).toBe('mock.jwt.token');
      expect(JSON.parse(localStorage.getItem('uniflow_user')).role).toBe('student');
    });

    it('displays error banner on login failure', async () => {
      authApi.loginUser.mockRejectedValueOnce(new Error('Invalid email or password.'));

      render(
        <MemoryRouter>
          <AuthProvider>
            <Login />
          </AuthProvider>
        </MemoryRouter>
      );

      await userEvent.type(screen.getByLabelText(/institutional email/i), 'wrong@college.edu');
      await userEvent.type(screen.getByLabelText(/^password/i), 'WrongPassword!');
      await userEvent.click(screen.getByRole('button', { name: /sign in/i }));

      await waitFor(() => {
        expect(screen.getByText(/invalid email or password/i)).toBeInTheDocument();
      });
    });
  });

  describe('Student Registration Validation', () => {
    it('shows validation errors for empty fields on register', async () => {
      render(
        <MemoryRouter>
          <AuthProvider>
            <Register />
          </AuthProvider>
        </MemoryRouter>
      );

      await userEvent.click(screen.getByRole('button', { name: /create student account/i }));

      expect(screen.getByText(/full name is required/i)).toBeInTheDocument();
      expect(screen.getByText(/institutional email is required/i)).toBeInTheDocument();
      expect(screen.getByText(/password is required/i)).toBeInTheDocument();
      expect(authApi.registerStudent).not.toHaveBeenCalled();
    });

    it('validates password minimum length and confirmation match', async () => {
      render(
        <MemoryRouter>
          <AuthProvider>
            <Register />
          </AuthProvider>
        </MemoryRouter>
      );

      await userEvent.type(screen.getByLabelText(/full name/i), 'Arjun Sharma');
      await userEvent.type(screen.getByLabelText(/institutional email/i), 'arjun@college.edu');
      await userEvent.type(screen.getByLabelText(/^password/i), 'short');
      await userEvent.type(screen.getByLabelText(/confirm password/i), 'different');

      await userEvent.click(screen.getByRole('button', { name: /create student account/i }));

      expect(screen.getByText(/password must be at least 8 characters long/i)).toBeInTheDocument();
      expect(screen.getByText(/passwords do not match/i)).toBeInTheDocument();
      expect(authApi.registerStudent).not.toHaveBeenCalled();
    });

    it('submits student registration with role: student enforced', async () => {
      const mockUser = {
        id: '64a1b2c3d4e5f6a7b8c9d001',
        name: 'Arjun Sharma',
        email: 'arjun@college.edu',
        role: 'student',
      };

      authApi.registerStudent.mockResolvedValueOnce({
        token: 'mock.student.token',
        user: mockUser,
      });

      render(
        <MemoryRouter>
          <AuthProvider>
            <Register />
          </AuthProvider>
        </MemoryRouter>
      );

      await userEvent.type(screen.getByLabelText(/full name/i), 'Arjun Sharma');
      await userEvent.type(screen.getByLabelText(/institutional email/i), 'arjun@college.edu');
      await userEvent.type(screen.getByLabelText(/student roll/i), 'CS2021001');
      await userEvent.type(screen.getByLabelText(/^password/i), 'SecurePass123!');
      await userEvent.type(screen.getByLabelText(/confirm password/i), 'SecurePass123!');

      await userEvent.click(screen.getByRole('button', { name: /create student account/i }));

      await waitFor(() => {
        expect(authApi.registerStudent).toHaveBeenCalledWith({
          name: 'Arjun Sharma',
          email: 'arjun@college.edu',
          studentId: 'CS2021001',
          password: 'SecurePass123!',
        });
      });

      expect(localStorage.getItem('uniflow_token')).toBe('mock.student.token');
    });
  });
});
