/**
 * src/models/UserDeletionAudit.js
 *
 * Tamper-evident audit collection recording permanent user account deletions.
 * Captures user metadata, role, deletion timestamp, and deleting actor ID/role
 * without storing passwords or sensitive credentials.
 */

import mongoose, { Schema } from 'mongoose';

const userDeletionAuditSchema = new Schema(
  {
    deletedUserId: {
      type: Schema.Types.ObjectId,
      required: true,
      index: true,
    },
    deletedUserRole: {
      type: String,
      required: true,
      enum: ['student', 'staff'],
    },
    deletedUserName: {
      type: String,
      required: true,
      trim: true,
    },
    deletedUserEmail: {
      type: String,
      required: true,
      lowercase: true,
      trim: true,
    },
    deletedUserIdentifier: {
      type: String,
      trim: true,
      default: null,
    },
    deletedUserDepartment: {
      type: Schema.Types.ObjectId,
      ref: 'Department',
      default: null,
    },
    deletedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    deletedByRole: {
      type: String,
      required: true,
      enum: ['admin', 'staff'],
    },
    institution: {
      type: Schema.Types.ObjectId,
      ref: 'Institution',
      required: true,
      index: true,
    },
    deletedAt: {
      type: Date,
      default: Date.now,
      index: true,
    },
  },
  {
    timestamps: true,
    collection: 'user_deletion_audits',
  }
);

export default mongoose.model('UserDeletionAudit', userDeletionAuditSchema);

