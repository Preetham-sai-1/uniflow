/**
 * src/routes/notification.routes.js
 */

import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware.js';
import {
  listNotifications,
  markAsRead,
  markAllAsRead,
} from '../controllers/notification.controller.js';

const router = Router();

// GET /api/notifications — list notifications for current user
router.get('/', authenticate, listNotifications);

// PATCH /api/notifications/read-all — mark all as read
router.patch('/read-all', authenticate, markAllAsRead);

// PATCH /api/notifications/:id/read — mark single notification as read
router.patch('/:id/read', authenticate, markAsRead);

export default router;
