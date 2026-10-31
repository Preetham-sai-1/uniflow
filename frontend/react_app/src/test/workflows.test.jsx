import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { AuthContext } from '../context/AuthContext.jsx';
import ServiceCatalogue from '../pages/student/ServiceCatalogue.jsx';
import RequestForm from '../pages/student/RequestForm.jsx';
import RequestDetail from '../pages/student/RequestDetail.jsx';
import StaffQueue from '../pages/staff/StaffQueue.jsx';
import AdminDashboard from '../pages/admin/AdminDashboard.jsx';
import * as servicesApi from '../api/servicesApi.js';
import * as requestsApi from '../api/requestsApi.js';
import * as staffApi from '../api/staffApi.js';
import * as adminApi from '../api/adminApi.js';

// Mock mockUser
const mockStudentUser = {
  id: 'student-123',
  name: 'Arjun Sharma',
  email: 'arjun@college.edu',
  role: 'student',
  studentId: 'CS2021001',
};

const mockStaffUser = {
  id: 'staff-456',
  name: 'Prof. Verma',
  email: 'verma@college.edu',
  role: 'staff',
  department: 'CS',
};

const mockAdminUser = {
  id: 'admin-789',
  name: 'Dean Admin',
  email: 'admin@college.edu',
  role: 'admin',
};

// Helper for rendering with AuthContext and Router
function renderWithAuth(ui, { user = mockStudentUser, initialEntries = ['/'] } = {}) {
  const authValue = {
    user,
    role: user?.role || null,
    token: 'mock-token',
    isAuthenticated: Boolean(user),
    loading: false,
    login: vi.fn(),
    register: vi.fn(),
    logout: vi.fn(),
  };

  return render(
    <AuthContext.Provider value={authValue}>
      <MemoryRouter initialEntries={initialEntries}>
        {ui}
      </MemoryRouter>
    </AuthContext.Provider>
  );
}

describe('Phase 4 — Frontend Workflow UIs', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  // ── 1. Service Catalogue ───────────────────────────────────────────────────
  describe('Service Catalogue', () => {
    const mockServices = [
      {
        id: 's-1',
        slug: 'bonafide-certificate',
        name: 'Bonafide Certificate',
        category: 'Academic',
        description: 'Official enrolment confirmation letter.',
        estimatedDays: 3,
      },
      {
        id: 's-2',
        slug: 'id-card-replacement',
        name: 'ID Card Replacement',
        category: 'Identity',
        description: 'Replacement for lost or stolen ID card.',
        estimatedDays: 5,
      },
      {
        id: 's-3',
        slug: 'equipment-booking',
        name: 'Equipment Booking',
        category: 'Resources',
        description: 'Borrow cameras and projectors.',
        estimatedDays: 1,
      },
    ];

    it('renders all campus services and filters by category', async () => {
      vi.spyOn(servicesApi, 'getServices').mockResolvedValue(mockServices);

      renderWithAuth(<ServiceCatalogue />);

      // Should show loading then services
      await waitFor(() => {
        expect(screen.getByText('Bonafide Certificate')).toBeInTheDocument();
        expect(screen.getByText('ID Card Replacement')).toBeInTheDocument();
        expect(screen.getByText('Equipment Booking')).toBeInTheDocument();
      });

      // Filter by Identity
      const identityPill = screen.getByRole('button', { name: 'Identity' });
      fireEvent.click(identityPill);

      expect(screen.getByText('ID Card Replacement')).toBeInTheDocument();
      expect(screen.queryByText('Bonafide Certificate')).not.toBeInTheDocument();
      expect(screen.queryByText('Equipment Booking')).not.toBeInTheDocument();
    });
  });

  // ── 2. Request Form & Submissions ──────────────────────────────────────────
  describe('Request Form', () => {
    const bonafideService = {
      id: 's-1',
      slug: 'bonafide-certificate',
      name: 'Bonafide Certificate',
      category: 'Academic',
      description: 'Official enrolment confirmation letter.',
      estimatedDays: 3,
      formFields: [
        { name: 'purpose', label: 'Purpose of Certificate', type: 'select', required: true },
        { name: 'copies', label: 'Number of Copies', type: 'number', required: true },
      ],
    };

    it('submits a bonafide certificate request with selected purpose and copies', async () => {
      vi.spyOn(servicesApi, 'getServiceById').mockResolvedValue(bonafideService);
      const submitSpy = vi.spyOn(requestsApi, 'submitRequest').mockResolvedValue({
        id: 'req-new-1',
        requestNumber: 'UF-20261014-TEST',
      });

      renderWithAuth(
        <Routes>
          <Route path="/student/services/:serviceId/apply" element={<RequestForm />} />
          <Route path="/student/requests/:id" element={<div>Request Detail Page</div>} />
        </Routes>,
        { initialEntries: ['/student/services/bonafide-certificate/apply'] }
      );

      await waitFor(() => {
        expect(screen.getByText('Request Details')).toBeInTheDocument();
      });

      // Fill in copies
      const copiesInput = screen.getByLabelText(/Number of Copies/i);
      fireEvent.change(copiesInput, { target: { value: '2' } });

      // Submit form
      const submitButton = screen.getByRole('button', { name: /Submit Request/i });
      fireEvent.click(submitButton);

      await waitFor(() => {
        expect(submitSpy).toHaveBeenCalledWith({
          serviceId: 's-1',
          formData: expect.objectContaining({
            purpose: 'Scholarship',
            copies: 2,
          }),
        });
      });
    });

    it('validates required fields on equipment booking', async () => {
      const equipmentService = {
        id: 's-3',
        slug: 'equipment-booking',
        name: 'Equipment Booking',
        category: 'Resources',
        description: 'Borrow gear.',
        estimatedDays: 1,
      };

      vi.spyOn(servicesApi, 'getServiceById').mockResolvedValue(equipmentService);
      const submitSpy = vi.spyOn(requestsApi, 'submitRequest');

      renderWithAuth(
        <Routes>
          <Route path="/student/services/:serviceId/apply" element={<RequestForm />} />
        </Routes>,
        { initialEntries: ['/student/services/equipment-booking/apply'] }
      );

      await waitFor(() => {
        expect(screen.getByText('Equipment Required')).toBeInTheDocument();
      });

      // Submit without filling equipment
      const submitButton = screen.getByRole('button', { name: /Submit Request/i });
      fireEvent.click(submitButton);

      await waitFor(() => {
        expect(screen.getByText('Equipment name is required.')).toBeInTheDocument();
      });
      expect(submitSpy).not.toHaveBeenCalled();
    });
  });

  // ── 3. Journey Detail & Payment Simulation ─────────────────────────────────
  describe('Journey Detail & Payment Simulation', () => {
    const mockRequestWithPayment = {
      id: 'req-id-card-1',
      requestNumber: 'UF-20261014-IDCARD',
      status: 'PAYMENT_REQUIRED',
      currentStepIndex: 1,
      createdAt: '2026-10-14T10:00:00.000Z',
      service: {
        name: 'ID Card Replacement',
        category: 'Identity',
        estimatedDays: 5,
      },
      formData: {
        reason: 'Lost',
        contactNumber: '+91 98765 43210',
      },
      runtimeSteps: [
        {
          stepIndex: 0,
          name: 'Security Review',
          assignedRole: 'staff',
          status: 'APPROVED',
          actionedAt: '2026-10-14T11:00:00.000Z',
          actor: { name: 'Officer Singh' },
          comment: 'Verified lost report.',
        },
        {
          stepIndex: 1,
          name: 'Replacement Fee Payment',
          assignedRole: 'student',
          isPaymentStep: true,
          status: 'PENDING',
        },
        {
          stepIndex: 2,
          name: 'Administrative Approval',
          assignedRole: 'admin',
          status: 'PENDING',
        },
      ],
      auditLog: [],
    };

    it('displays payment simulation UI when status is PAYMENT_REQUIRED and executes payment', async () => {
      vi.spyOn(requestsApi, 'getRequestById').mockResolvedValue(mockRequestWithPayment);
      const paySpy = vi.spyOn(requestsApi, 'confirmPayment').mockResolvedValue({
        ...mockRequestWithPayment,
        status: 'ADMIN_APPROVAL_PENDING',
        currentStepIndex: 2,
        runtimeSteps: [
          mockRequestWithPayment.runtimeSteps[0],
          {
            ...mockRequestWithPayment.runtimeSteps[1],
            status: 'PAYMENT_COMPLETED',
          },
          mockRequestWithPayment.runtimeSteps[2],
        ],
      });

      renderWithAuth(
        <Routes>
          <Route path="/student/requests/:id" element={<RequestDetail />} />
        </Routes>,
        { initialEntries: ['/student/requests/req-id-card-1'] }
      );

      // Verify request number and payment card are present
      await waitFor(() => {
        expect(screen.getByText('UF-20261014-IDCARD')).toBeInTheDocument();
        expect(screen.getByText(/Replacement Fee Payment Required/i)).toBeInTheDocument();
        expect(screen.getByText('₹100.00')).toBeInTheDocument();
      });

      // Click "Pay Now (Simulate)"
      const payButton = screen.getByRole('button', { name: /Pay Now \(Simulate\)/i });
      fireEvent.click(payButton);

      await waitFor(() => {
        expect(paySpy).toHaveBeenCalledWith('req-id-card-1');
        expect(screen.getByText(/Payment of ₹100 simulated successfully/i)).toBeInTheDocument();
      });
    });

    it('renders journey completion banner when request is COMPLETED', async () => {
      const completedRequest = {
        ...mockRequestWithPayment,
        status: 'COMPLETED',
        currentStepIndex: 2,
        runtimeSteps: mockRequestWithPayment.runtimeSteps.map((s) => ({
          ...s,
          status: 'APPROVED',
        })),
      };

      vi.spyOn(requestsApi, 'getRequestById').mockResolvedValue(completedRequest);

      renderWithAuth(
        <Routes>
          <Route path="/student/requests/:id" element={<RequestDetail />} />
        </Routes>,
        { initialEntries: ['/student/requests/req-completed'] }
      );

      await waitFor(() => {
        expect(screen.getByText('Journey Successfully Completed!')).toBeInTheDocument();
      });
    });
  });

  // ── 4. Staff Review Queue ──────────────────────────────────────────────────
  describe('Staff Review Queue', () => {
    const mockQueueItems = [
      {
        stepId: 'req-1-0',
        requestId: 'req-1',
        requestNumber: 'UF-20261014-001',
        serviceName: 'Bonafide Certificate',
        serviceCategory: 'Academic',
        studentName: 'Arjun Sharma',
        studentEmail: 'arjun@college.edu',
        studentIdNumber: 'CS2021001',
        stepIndex: 0,
        stepName: 'Department Verification',
        assignedRole: 'staff',
        status: 'DEPARTMENT_VERIFICATION_PENDING',
        submittedAt: '2026-10-14T08:00:00.000Z',
        waitingHours: 3,
      },
    ];

    it('renders queue items and approves a step via modal', async () => {
      vi.spyOn(staffApi, 'getStaffQueue').mockResolvedValue(mockQueueItems);
      const approveSpy = vi.spyOn(staffApi, 'approveStaffStep').mockResolvedValue({});

      renderWithAuth(<StaffQueue />, { user: mockStaffUser });

      await waitFor(() => {
        expect(screen.getByText('UF-20261014-001')).toBeInTheDocument();
        expect(screen.getByText('Bonafide Certificate')).toBeInTheDocument();
      });

      // Open approve modal
      const approveBtn = screen.getByRole('button', { name: /^Approve$/i });
      fireEvent.click(approveBtn);

      expect(screen.getByText('Approve Workflow Step')).toBeInTheDocument();

      // Submit approval
      const confirmBtn = screen.getByRole('button', { name: /Confirm Approval/i });
      fireEvent.click(confirmBtn);

      await waitFor(() => {
        expect(approveSpy).toHaveBeenCalledWith('req-1', 0, '');
      });
    });

    it('enforces mandatory comments when rejecting a step', async () => {
      vi.spyOn(staffApi, 'getStaffQueue').mockResolvedValue(mockQueueItems);
      const rejectSpy = vi.spyOn(staffApi, 'rejectStaffStep');

      renderWithAuth(<StaffQueue />, { user: mockStaffUser });

      await waitFor(() => {
        expect(screen.getByText('UF-20261014-001')).toBeInTheDocument();
      });

      // Click Reject
      const rejectBtn = screen.getByRole('button', { name: /^Reject$/i });
      fireEvent.click(rejectBtn);

      expect(screen.getByText('Reject Request')).toBeInTheDocument();

      // Try submitting without comment
      const confirmRejectBtn = screen.getByRole('button', { name: /Confirm Rejection/i });
      fireEvent.click(confirmRejectBtn);

      await waitFor(() => {
        expect(
          screen.getByText(/A rejection reason is strictly required/i)
        ).toBeInTheDocument();
      });
      expect(rejectSpy).not.toHaveBeenCalled();

      // Enter comment and submit
      const commentInput = screen.getByLabelText(/Rejection Reason/i);
      fireEvent.change(commentInput, { target: { value: 'Incomplete documentation.' } });

      rejectSpy.mockResolvedValue({});
      fireEvent.click(confirmRejectBtn);

      await waitFor(() => {
        expect(rejectSpy).toHaveBeenCalledWith('req-1', 0, 'Incomplete documentation.');
      });
    });
  });

  // ── 5. Admin Dashboard ─────────────────────────────────────────────────────
  describe('Admin Dashboard', () => {
    const mockStats = {
      requests: {
        total: 42,
        pending: 10,
        completed: 28,
        rejected: 4,
      },
      bookings: {
        total: 12,
        pending: 2,
        confirmed: 9,
        rejected: 1,
      },
      byService: [
        { serviceName: 'Bonafide Certificate', total: 25, pending: 5 },
        { serviceName: 'ID Card Replacement', total: 10, pending: 3 },
        { serviceName: 'Equipment Booking', total: 7, pending: 2 },
      ],
    };

    const mockAdminRequests = [
      {
        _id: 'req-admin-1',
        requestNumber: 'UF-20261014-ADMIN',
        status: 'ADMIN_APPROVAL_PENDING',
        createdAt: '2026-10-14T09:00:00.000Z',
        service: { name: 'Bonafide Certificate' },
        student: { name: 'Priya Patel', email: 'priya@college.edu', studentId: 'CS2021002' },
      },
    ];

    it('renders administrative statistics and institutional request list', async () => {
      vi.spyOn(adminApi, 'getAdminStats').mockResolvedValue(mockStats);
      vi.spyOn(adminApi, 'getAllRequests').mockResolvedValue({
        items: mockAdminRequests,
        pagination: { total: 1, page: 1, limit: 50, pages: 1 },
      });

      renderWithAuth(<AdminDashboard />, { user: mockAdminUser });

      await waitFor(() => {
        expect(screen.getByText('42')).toBeInTheDocument(); // total submissions
        expect(screen.getByText('10')).toBeInTheDocument(); // pending approval
        expect(screen.getByText('28')).toBeInTheDocument(); // completed journeys
        expect(screen.getByText('4')).toBeInTheDocument(); // rejected requests
        expect(screen.getByText('UF-20261014-ADMIN')).toBeInTheDocument();
        expect(screen.getByText('Priya Patel')).toBeInTheDocument();
      });
    });
  });
});
