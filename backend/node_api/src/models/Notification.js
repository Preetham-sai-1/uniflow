/**
 * src/models/Notification.js
 *
 * In-app notification sent to a user when a workflow step transitions.
 *
 * Phase 1 note: Notifications are created by the service layer when status changes.
 * They are read-only from the client. The frontend polls GET /api/notifications
 * and marks them read via PATCH /api/notifications/:id/read.
 * Push/email notifications are future scope.
 */

import mongoose, { Schema } from 'mongoose';

export const NOTIFICATION_TYPES = Object.freeze({
  STEP_APPROVED: 'STEP_APPROVED',
  STEP_REJECTED: 'STEP_REJECTED',
  PAYMENT_REQUIRED: 'PAYMENT_REQUIRED',
  REQUEST_COMPLETED: 'REQUEST_COMPLETED',
  REQUEST_SUBMITTED: 'REQUEST_SUBMITTED',
  INFO: 'INFO',
});

const notificationSchema = new Schema(
  {
    recipient: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Notification must have a recipient.'],
    },

    // Optional — links the notification to a specific request
    request: {
      type: Schema.Types.ObjectId,
      ref: 'Request',
      default: null,
    },

    title: {
      type: String,
      required: [true, 'Notification title is required.'],
      trim: true,
      maxlength: [200, 'Title cannot exceed 200 characters.'],
    },

    message: {
      type: String,
      required: [true, 'Notification message is required.'],
      trim: true,
      maxlength: [1000, 'Message cannot exceed 1000 characters.'],
    },

    type: {
      type: String,
      required: [true, 'Notification type is required.'],
      enum: {
        values: Object.values(NOTIFICATION_TYPES),
        message: `Type must be one of: ${Object.values(NOTIFICATION_TYPES).join(', ')}.`,
      },
      default: NOTIFICATION_TYPES.INFO,
    },

    isRead: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
    collection: 'notifications',
  }
);

// Primary query pattern: find unread notifications for a user, newest first
notificationSchema.index({ recipient: 1, isRead: 1, createdAt: -1 });

export default mongoose.model('Notification', notificationSchema);
