/**
 * src/routes/request.routes.js
 */

import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireRole } from '../middleware/role.middleware.js';
import { validate } from '../middleware/validate.middleware.js';
import {
  submitRequestSchema,
  approveStepSchema,
  rejectStepSchema,
} from '../validators/request.validators.js';
import {
  submitRequest,
  listRequests,
  getRequest,
  confirmPayment,
  approveStep,
  rejectStep,
} from '../controllers/request.controller.js';

const router = Router();

// POST /api/requests — student submits a new request
router.post('/', authenticate, requireRole('student'), validate(submitRequestSchema), submitRequest);

// GET /api/requests — list requests (filtered by user role)
router.get('/', authenticate, listRequests);

// GET /api/requests/:id — get request details
router.get('/:id', authenticate, getRequest);

// PATCH /api/requests/:id/payment — simulated payment step (student only)
router.patch('/:id/payment', authenticate, requireRole('student'), confirmPayment);

// PATCH /api/requests/:id/steps/:stepIndex/approve — approve step (staff or admin)
router.patch(
  '/:id/steps/:stepIndex/approve',
  authenticate,
  requireRole('staff', 'admin'),
  validate(approveStepSchema),
  approveStep
);

// PATCH /api/requests/:id/steps/:stepIndex/reject — reject step (staff or admin)
router.patch(
  '/:id/steps/:stepIndex/reject',
  authenticate,
  requireRole('staff', 'admin'),
  validate(rejectStepSchema),
  rejectStep
);

export default router;
