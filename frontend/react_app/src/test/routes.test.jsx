import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import { AuthProvider } from '../context/AuthContext.jsx';
import AppRoutes from '../routes/AppRoutes.jsx';
import * as authApi from '../api/authApi.js';
import * as requestsApi from '../api/requestsApi.js';
import * as staffApi from '../api/staffApi.js';
import * as adminApi from '../api/adminApi.js';

vi.mock('../api/authApi.js');
vi.mock('../api/requestsApi.js', () => ({
  getRequests: vi.fn().mockResolvedValue({ items: [], pagination: {} }),
  getRequestById: vi.fn(),
  submitRequest: vi.fn(),
  confirmPayment: vi.fn(),
  approveStep: vi.fn(),
  rejectStep: vi.fn(),
}));
vi.mock('../api/staffApi.js', () => ({
  getStaffQueue: vi.fn().mockResolvedValue([]),
  approveStaffStep: vi.fn(),
  rejectStaffStep: vi.fn(),
}));
vi.mock('../api/adminApi.js', () => ({
  getAdminStats: vi.fn().mockResolvedValue({ requests: { total: 0, pending: 0, completed: 0, rejected: 0 } }),
  getAllRequests: vi.fn().mockResolvedValue({ items: [], pagination: {} }),
}));

function renderWithRouter(initialEntry = '/') {
  return render(
    <MemoryRouter initialEntries={[initialEntry]}>
      <AuthProvider>
        <AppRoutes />
      </AuthProvider>
    </MemoryRouter>
  );
}

describe('Routing & Role-Based Access Control', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    localStorage.clear();
  });

  describe('Unauthenticated Access', () => {
    it('redirects unauthenticated user from /student to /login', async () => {
      renderWithRouter('/student');

      await waitFor(() => {
        expect(screen.getByRole('heading', { name: /sign in to your account/i })).toBeInTheDocument();
      });
    });

    it('redirects unauthenticated user from /staff to /login', async () => {
      renderWithRouter('/staff');

      await waitFor(() => {
        expect(screen.getByRole('heading', { name: /sign in to your account/i })).toBeInTheDocument();
      });
    });

    it('redirects unauthenticated user from /admin to /login', async () => {
      renderWithRouter('/admin');

      await waitFor(() => {
        expect(screen.getByRole('heading', { name: /sign in to your account/i })).toBeInTheDocument();
      });
    });

    it('renders 404 page for non-existent route', async () => {
      renderWithRouter('/some/completely/unknown/page');

      await waitFor(() => {
        expect(screen.getByRole('heading', { name: /404 — page not found/i })).toBeInTheDocument();
      });
    });
  });

  describe('Student Role Permissions', () => {
    beforeEach(() => {
      const studentUser = {
        id: '64a1b2c3d4e5f6a7b8c9d001',
        name: 'Arjun Sharma',
        email: 'student@uniflow.edu',
        role: 'student',
        studentId: 'CS2021001',
      };
      localStorage.setItem('uniflow_token', 'valid.student.jwt');
      localStorage.setItem('uniflow_user', JSON.stringify(studentUser));
      authApi.getCurrentUser.mockResolvedValue(studentUser);
    });

    it('allows student to access /student dashboard', async () => {
      renderWithRouter('/student');

      await waitFor(() => {
        expect(screen.getByRole('heading', { name: /welcome, arjun sharma/i })).toBeInTheDocument();
        expect(screen.getByText(/student portal/i)).toBeInTheDocument();
      });
    });

    it('blocks student from accessing /staff with 403 redirect', async () => {
      renderWithRouter('/staff');

      await waitFor(() => {
        expect(screen.getByRole('heading', { name: /403 — access denied/i })).toBeInTheDocument();
      });
    });

    it('blocks student from accessing /admin with 403 redirect', async () => {
      renderWithRouter('/admin');

      await waitFor(() => {
        expect(screen.getByRole('heading', { name: /403 — access denied/i })).toBeInTheDocument();
      });
    });
  });

  describe('Staff Role Permissions', () => {
    beforeEach(() => {
      const staffUser = {
        id: '64a1b2c3d4e5f6a7b8c9d002',
        name: 'Priya Nair',
        email: 'staff@uniflow.edu',
        role: 'staff',
      };
      localStorage.setItem('uniflow_token', 'valid.staff.jwt');
      localStorage.setItem('uniflow_user', JSON.stringify(staffUser));
      authApi.getCurrentUser.mockResolvedValue(staffUser);
    });

    it('allows staff to access /staff review queue', async () => {
      renderWithRouter('/staff');

      await waitFor(() => {
        expect(screen.getByRole('heading', { name: /review queue/i })).toBeInTheDocument();
        expect(screen.getByText(/staff review queue/i)).toBeInTheDocument();
      });
    });

    it('blocks staff from accessing /admin with 403 redirect', async () => {
      renderWithRouter('/admin');

      await waitFor(() => {
        expect(screen.getByRole('heading', { name: /403 — access denied/i })).toBeInTheDocument();
      });
    });
  });

  describe('Admin Role Permissions', () => {
    beforeEach(() => {
      const adminUser = {
        id: '64a1b2c3d4e5f6a7b8c9d003',
        name: 'Dr. Ramesh Kumar',
        email: 'admin@uniflow.edu',
        role: 'admin',
      };
      localStorage.setItem('uniflow_token', 'valid.admin.jwt');
      localStorage.setItem('uniflow_user', JSON.stringify(adminUser));
      authApi.getCurrentUser.mockResolvedValue(adminUser);
    });

    it('allows admin to access /admin dashboard', async () => {
      renderWithRouter('/admin');

      await waitFor(() => {
        expect(screen.getByRole('heading', { name: /institutional control center/i })).toBeInTheDocument();
        expect(screen.getByText(/administrative console/i)).toBeInTheDocument();
      });
    });

    it('allows admin to access /staff review queue', async () => {
      renderWithRouter('/staff');

      await waitFor(() => {
        expect(screen.getByRole('heading', { name: /review queue/i })).toBeInTheDocument();
      });
    });
  });

  describe('Logout Workflow', () => {
    it('clears localStorage and redirects to /login on logout', async () => {
      const studentUser = {
        id: '64a1b2c3d4e5f6a7b8c9d001',
        name: 'Arjun Sharma',
        email: 'student@uniflow.edu',
        role: 'student',
      };
      localStorage.setItem('uniflow_token', 'valid.student.jwt');
      localStorage.setItem('uniflow_user', JSON.stringify(studentUser));
      authApi.getCurrentUser.mockResolvedValue(studentUser);

      renderWithRouter('/student');

      await waitFor(() => {
        expect(screen.getByRole('heading', { name: /welcome, arjun sharma/i })).toBeInTheDocument();
      });

      const logoutBtn = screen.getByRole('button', { name: /log out/i });
      await userEvent.click(logoutBtn);

      expect(localStorage.getItem('uniflow_token')).toBeNull();
      expect(localStorage.getItem('uniflow_user')).toBeNull();

      await waitFor(() => {
        expect(screen.getByRole('heading', { name: /sign in to your account/i })).toBeInTheDocument();
      });
    });
  });
});
