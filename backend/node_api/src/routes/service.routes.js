/**
 * src/routes/service.routes.js
 */

import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireRole } from '../middleware/role.middleware.js';
import { validate } from '../middleware/validate.middleware.js';
import { createServiceSchema } from '../validators/service.validators.js';
import { listServices, getService, createService } from '../controllers/service.controller.js';

const router = Router();

// GET /api/services — catalogue listing
router.get('/', authenticate, listServices);

// GET /api/services/:id — service details (by ObjectId or slug)
router.get('/:id', authenticate, getService);

// POST /api/services — admin create service
router.post('/', authenticate, requireRole('admin'), validate(createServiceSchema), createService);

export default router;
