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

export default mongoose.model('User', userSchema);
