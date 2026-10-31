/**
 * src/routes/health.routes.js
 *
 * Public health check endpoint.
 * No authentication required — allows load balancers and monitoring tools
 * to verify the process is alive.
 */

import { Router } from 'express';
import { getHealth } from '../controllers/health.controller.js';

const router = Router();

// GET /api/health
router.get('/', getHealth);

export default router;
