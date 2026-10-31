/**
 * src/routes/admin.routes.js
 */

import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireRole } from '../middleware/role.middleware.js';
import { getAdminStats, listAllRequests } from '../controllers/admin.controller.js';

const router = Router();

// GET /api/admin/stats — summary statistics
router.get('/stats', authenticate, requireRole('admin'), getAdminStats);

// GET /api/admin/requests — list all requests with filters
router.get('/requests', authenticate, requireRole('admin'), listAllRequests);

export default router;
