/**
 * src/services/notification.service.js
 *
 * In-app notification creation and query service.
 */

import Notification from '../models/Notification.js';

export async function createNotification({ recipientId, requestId, title, message, type = 'INFO' }) {
  if (!recipientId) return null;
  const notif = new Notification({
    recipient: recipientId,
    request: requestId,
    title,
    message,
    type,
    isRead: false,
  });
  return notif.save();
}

export async function getUserNotifications(userId, { unreadOnly = false, limit = 50 } = {}) {
  const query = { recipient: userId };
  if (unreadOnly) {
    query.isRead = false;
  }
  return Notification.find(query)
    .populate({
      path: 'request',
      select: 'requestNumber status service',
      populate: { path: 'service', select: 'name' },
    })
    .sort({ createdAt: -1 })
    .limit(limit)
    .lean();
}

export async function markNotificationAsRead(notificationId, userId) {
  const notif = await Notification.findOne({ _id: notificationId, recipient: userId });
  if (!notif) return null;
  notif.isRead = true;
  await notif.save();
  return notif;
}

export async function markAllNotificationsAsRead(userId) {
  return Notification.updateMany({ recipient: userId, isRead: false }, { $set: { isRead: true } });
}
