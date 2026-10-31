/**
 * src/routes/admin.routes.js
 */

import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireRole } from '../middleware/role.middleware.js';
import {
  getAdminStats,
  listAllRequests,
  listPendingUsers,
  approveUser,
  rejectUser,
} from '../controllers/admin.controller.js';

const router = Router();

// GET /api/admin/stats — summary statistics
router.get('/stats', authenticate, requireRole('admin'), getAdminStats);

// GET /api/admin/requests — list all requests with filters
router.get('/requests', authenticate, requireRole('admin'), listAllRequests);

// GET /api/admin/pending-users — list pending registrations
router.get('/pending-users', authenticate, requireRole('admin'), listPendingUsers);

// PATCH /api/admin/users/:id/approve — approve registration
router.patch('/users/:id/approve', authenticate, requireRole('admin'), approveUser);

// PATCH /api/admin/users/:id/reject — reject registration
router.patch('/users/:id/reject', authenticate, requireRole('admin'), rejectUser);

export default router;
