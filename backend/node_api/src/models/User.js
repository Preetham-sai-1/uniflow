/**
 * src/models/User.js
 *
 * All user accounts — students, staff, and administrators — live in this
 * single collection. The `role` field distinguishes them.
 *
 * Security notes:
 *  - passwordHash is excluded from query results by default (select: false).
 *  - Roles are never accepted from request bodies; they come from the JWT payload.
 *  - Plaintext passwords are never stored; bcrypt hashing happens in auth.service.js.
 */

import mongoose, { Schema } from 'mongoose';

export const USER_ROLES = Object.freeze({
  STUDENT: 'student',
  STAFF: 'staff',
  ADMIN: 'admin',
});

export const APPROVAL_STATUSES = Object.freeze({
  PENDING: 'PENDING',
  APPROVED: 'APPROVED',
  REJECTED: 'REJECTED',
});

const userSchema = new Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required.'],
      trim: true,
      minlength: [2, 'Name must be at least 2 characters.'],
      maxlength: [100, 'Name cannot exceed 100 characters.'],
    },

    // Stored lowercase and trimmed — unique across the entire collection
    email: {
      type: String,
      required: [true, 'Email address is required.'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, 'Please provide a valid email address.'],
    },

    // Excluded from all find() results by default — must be explicitly selected
    passwordHash: {
      type: String,
      required: [true, 'Password hash is required.'],
      select: false,
    },

    role: {
      type: String,
      required: [true, 'Role is required.'],
      enum: {
        values: Object.values(USER_ROLES),
        message: 'Role must be one of: student, staff, admin.',
      },
    },

    institution: {
      type: Schema.Types.ObjectId,
      ref: 'Institution',
      required: [true, 'User must belong to an institution.'],
    },

    // Optional — required for staff members, used for queue routing
    department: {
      type: Schema.Types.ObjectId,
      ref: 'Department',
      default: null,
    },

    // Optional — student roll number or university ID
    studentId: {
      type: String,
      trim: true,
      default: null,
    },

    // Optional — staff employee ID or designation code
    staffId: {
      type: String,
      trim: true,
      default: null,
    },

    mustChangePassword: {
      type: Boolean,
      default: false,
    },

    approvalStatus: {
      type: String,
      enum: {
        values: Object.values(APPROVAL_STATUSES),
        message: 'Approval status must be one of: PENDING, APPROVED, REJECTED.',
      },
      default: APPROVAL_STATUSES.APPROVED,
    },

    rejectionReason: {
      type: String,
      trim: true,
      default: null,
    },

    approvedAt: {
      type: Date,
      default: null,
    },

    approvedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    approvedByRole: {
      type: String,
      enum: Object.values(USER_ROLES),
      default: null,
    },

    rejectedAt: {
      type: Date,
      default: null,
    },

    rejectedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    rejectedByRole: {
      type: String,
      enum: Object.values(USER_ROLES),
      default: null,
    },

    createdBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    createdByRole: {
      type: String,
      enum: Object.values(USER_ROLES),
      default: null,
    },

    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
    collection: 'users',
  }
);

// Normalized email index is already unique from the field definition.
// Add a compound index for role-based queries (e.g. find all staff in institution).
userSchema.index({ institution: 1, role: 1 });
userSchema.index({ institution: 1, approvalStatus: 1 });
userSchema.index({ studentId: 1 }, { unique: true, sparse: true });
userSchema.index({ staffId: 1 }, { unique: true, sparse: true });

export default mongoose.model('User', userSchema);
