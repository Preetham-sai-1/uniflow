/**
 * src/routes/admin.routes.js
 */

import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireRole } from '../middleware/role.middleware.js';
import { validate } from '../middleware/validate.middleware.js';
import {
  adminCreateUserSchema,
  adminChangeRoleSchema,
} from '../validators/user.validators.js';
import {
  getAdminStats,
  listAllRequests,
  listUsers,
  createUser,
  changeUserRole,
  deleteUser,
  listPendingUsers,
  approveUser,
  rejectUser,
} from '../controllers/admin.controller.js';

const router = Router();

// GET /api/admin/stats — summary statistics
router.get('/stats', authenticate, requireRole('admin'), getAdminStats);

// GET /api/admin/requests — list all requests with filters
router.get('/requests', authenticate, requireRole('admin'), listAllRequests);

// ── User Management ────────────────────────────────────────────────────────────

// GET /api/admin/users — list all users with role, status, and search filters
router.get('/users', authenticate, requireRole('admin'), listUsers);

// POST /api/admin/users — create student or staff account
router.post(
  '/users',
  authenticate,
  requireRole('admin'),
  validate(adminCreateUserSchema),
  createUser
);

// PATCH /api/admin/users/:id/role — change user role between student and staff
router.patch(
  '/users/:id/role',
  authenticate,
  requireRole('admin'),
  validate(adminChangeRoleSchema),
  changeUserRole
);

// DELETE /api/admin/users/:id — permanently delete student or staff account
router.delete('/users/:id', authenticate, requireRole('admin'), deleteUser);

// GET /api/admin/pending-users — list pending registrations
router.get('/pending-users', authenticate, requireRole('admin'), listPendingUsers);

// Approve registration (supports PATCH and POST)
router.patch('/users/:id/approve', authenticate, requireRole('admin'), approveUser);
router.post('/users/:id/approve', authenticate, requireRole('admin'), approveUser);

// Reject registration (supports PATCH and POST)
router.patch('/users/:id/reject', authenticate, requireRole('admin'), rejectUser);
router.post('/users/:id/reject', authenticate, requireRole('admin'), rejectUser);

export default router;
