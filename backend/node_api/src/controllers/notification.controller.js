/**
 * src/controllers/notification.controller.js
 */

import { asyncHandler } from '../utils/asyncHandler.js';
import * as notificationService from '../services/notification.service.js';
import { AppError } from '../utils/AppError.js';

export const listNotifications = asyncHandler(async (req, res) => {
  const unreadOnly = req.query.unread === 'true';
  const limit = req.query.limit ? parseInt(req.query.limit, 10) : 50;

  const notifications = await notificationService.getUserNotifications(req.user.id, {
    unreadOnly,
    limit,
  });

  const formatted = notifications.map((n) => ({
    id: n._id.toString(),
    type: n.type,
    title: n.title,
    message: n.message,
    requestId: n.request?._id?.toString() || null,
    requestNumber: n.request?.requestNumber || null,
    serviceName: n.request?.service?.name || null,
    isRead: n.isRead,
    createdAt: n.createdAt,
  }));

  res.status(200).json({
    success: true,
    data: formatted,
  });
});

export const markAsRead = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const updated = await notificationService.markNotificationAsRead(id, req.user.id);

  if (!updated) {
    throw AppError.notFound(`Notification not found: ${id}`);
  }

  res.status(200).json({
    success: true,
    data: {
      id: updated._id.toString(),
      isRead: updated.isRead,
    },
  });
});

export const markAllAsRead = asyncHandler(async (req, res) => {
  await notificationService.markAllNotificationsAsRead(req.user.id);

  res.status(200).json({
    success: true,
    message: 'All notifications marked as read.',
  });
});
