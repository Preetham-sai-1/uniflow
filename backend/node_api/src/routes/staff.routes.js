/**
 * src/routes/staff.routes.js
 */

import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireRole } from '../middleware/role.middleware.js';
import { validate } from '../middleware/validate.middleware.js';
import { approveStepSchema, rejectStepSchema } from '../validators/request.validators.js';
import { getStaffQueue, approveStep, rejectStep } from '../controllers/staff.controller.js';

const router = Router();

// GET /api/staff/queue — review queue
router.get('/queue', authenticate, requireRole('staff', 'admin'), getStaffQueue);

// PATCH /api/staff/requests/:id/steps/:stepIndex/approve
router.patch(
  '/requests/:id/steps/:stepIndex/approve',
  authenticate,
  requireRole('staff', 'admin'),
  validate(approveStepSchema),
  approveStep
);

// PATCH /api/staff/requests/:id/steps/:stepIndex/reject
router.patch(
  '/requests/:id/steps/:stepIndex/reject',
  authenticate,
  requireRole('staff', 'admin'),
  validate(rejectStepSchema),
  rejectStep
);

export default router;
