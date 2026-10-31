/**
 * src/routes/index.js
 *
 * Central router — mounts all route groups under their /api/* prefixes.
 */

import { Router } from 'express';
import healthRoutes from './health.routes.js';
import authRoutes from './auth.routes.js';
import departmentRoutes from './department.routes.js';
import serviceRoutes from './service.routes.js';
import requestRoutes from './request.routes.js';
import staffRoutes from './staff.routes.js';
import adminRoutes from './admin.routes.js';
import notificationRoutes from './notification.routes.js';

const router = Router();

// ── Route Mounts ─────────────────────────────────────────────────────────────
router.use('/health', healthRoutes);                 // GET /api/health
router.use('/auth', authRoutes);                     // POST /api/auth/register|login, GET /api/auth/me
router.use('/departments', departmentRoutes);       // GET /api/departments
router.use('/services', serviceRoutes);             // GET /api/services, GET /api/services/:id, POST /api/services
router.use('/requests', requestRoutes);             // POST /api/requests, GET /api/requests, GET /api/requests/:id, PATCH payment/approve/reject
router.use('/staff', staffRoutes);                   // GET /api/staff/queue, PATCH /api/staff/requests/:id/steps/:stepIndex/approve|reject
router.use('/admin', adminRoutes);                   // GET /api/admin/stats, GET /api/admin/requests
router.use('/notifications', notificationRoutes);   // GET /api/notifications, PATCH /api/notifications/:id/read

export default router;
