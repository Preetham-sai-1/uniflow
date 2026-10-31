/**
 * src/services/auth.service.js
 *
 * Business logic for authentication operations.
 * This module owns: password hashing, JWT signing, user lookup, and
 * the sanitised user object returned to clients.
 *
 * Security rules (AGENTS.md §3, §5):
 *  - Never store or return plaintext passwords.
 *  - Never return passwordHash in any response.
 *  - Roles come from the database, never from the request body.
 *  - JWT_SECRET comes from env config, never hardcoded.
 */

import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import mongoose from 'mongoose';
import { env } from '../config/env.js';
import User from '../models/User.js';
import Institution from '../models/Institution.js';
import Department from '../models/Department.js';
import { AppError } from '../utils/AppError.js';

// ─── Token signing ─────────────────────────────────────────────────────────────

function signToken(user) {
  return jwt.sign(
    { userId: user._id, role: user.role, email: user.email },
    env.JWT_SECRET,
    { expiresIn: env.JWT_EXPIRES_IN }
  );
}

// ─── Response shaping ─────────────────────────────────────────────────────────

function sanitizeUser(user) {
  return {
    id: user._id,
    name: user.name,
    email: user.email,
    role: user.role,
    institution: user.institution,
    department: user.department ?? null,
    studentId: user.studentId ?? null,
    approvalStatus: user.approvalStatus ?? 'APPROVED',
    rejectionReason: user.rejectionReason ?? null,
    isActive: user.isActive,
    createdAt: user.createdAt,
  };
}

// ─── Register ─────────────────────────────────────────────────────────────────

/**
 * Creates a new user account.
 *
 * Institution resolution strategy (MVP):
 *   The system auto-assigns the user to the first active institution it finds.
 *   This works for the single-institution MVP. Multi-institution support
 *   requires passing institutionId explicitly (future scope).
 *
 * Security:
 *   - role: 'student' is strictly enforced on the server.
 *   - approvalStatus is initialized to 'PENDING'.
 *   - Duplicate emails and duplicate student IDs are rejected.
 *   - No active login session / token is issued until approved.
 *
 * @param {object} params
 * @param {string} params.name
 * @param {string} params.email      - Already normalized to lowercase by Zod
 * @param {string} params.password
 * @param {string} [params.role]     - Ignored; forced to 'student'
 * @param {string} [params.departmentId]
 * @param {string} [params.studentId]
 * @returns {{ user: object, message: string }}
 */
export async function registerUser({ name, email, password, departmentId, studentId }) {
  // 1. Resolve institution — find the single active institution for MVP
  const institution = await Institution.findOne({ isActive: true }).lean();
  if (!institution) {
    throw new AppError(
      503,
      'INTERNAL_ERROR',
      'No active institution found. Run the seed script first.'
    );
  }

  const normalizedEmail = email.trim().toLowerCase();

  // 2. Reject duplicate email address
  const existingEmail = await User.findOne({ email: normalizedEmail }).lean();
  if (existingEmail) {
    throw new AppError(409, 'CONFLICT', 'An account with this email address already exists.');
  }

  // 3. Reject duplicate student ID (if provided)
  const trimmedStudentId =
    studentId && typeof studentId === 'string' && studentId.trim().length > 0
      ? studentId.trim()
      : null;

  if (trimmedStudentId) {
    const existingStudentId = await User.findOne({ studentId: trimmedStudentId }).lean();
    if (existingStudentId) {
      throw new AppError(
        409,
        'CONFLICT',
        'A student account with this Student ID already exists.'
      );
    }
  }

  // 4. Resolve department if provided
  let department = null;
  if (departmentId) {
    if (!mongoose.isValidObjectId(departmentId)) {
      throw new AppError(400, 'VALIDATION_ERROR', 'Invalid department ID.');
    }
    department = await Department.findOne({
      _id: departmentId,
      institution: institution._id,
      isActive: true,
    }).lean();
    if (!department) {
      throw new AppError(404, 'NOT_FOUND', 'Department not found in this institution.');
    }
  }

  // 5. Hash password
  const passwordHash = await bcrypt.hash(password, env.BCRYPT_SALT_ROUNDS);

  // 6. Create user — Always assign role: 'student', and approvalStatus: 'PENDING'
  const user = await User.create({
    name: name.trim(),
    email: normalizedEmail,
    passwordHash,
    role: 'student',
    institution: institution._id,
    department: department?._id ?? null,
    studentId: trimmedStudentId,
    approvalStatus: 'PENDING',
    isActive: true,
  });

  return {
    user: sanitizeUser(user),
    message: 'Registration submitted successfully. Your account is pending administrator approval.',
  };
}

// ─── Login ────────────────────────────────────────────────────────────────────

/**
 * Authenticates an existing user.
 * Returns a generic 401 for both "user not found" and "wrong password"
 * to avoid leaking whether an email is registered.
 *
 * @param {object} params
 * @param {string} params.email    - Already normalized by Zod
 * @param {string} params.password
 * @returns {{ token: string, user: object }}
 */
export async function loginUser({ email, password }) {
  const normalizedEmail = email.trim().toLowerCase();
  // passwordHash is excluded from results by default; select it explicitly
  const user = await User.findOne({ email: normalizedEmail }).select('+passwordHash');

  const passwordMatch = user ? await bcrypt.compare(password, user.passwordHash) : false;

  if (!user || !passwordMatch) {
    // Identical error for both cases — avoids user enumeration
    throw new AppError(401, 'INVALID_TOKEN', 'Invalid email or password.');
  }

  // Check approval status — only APPROVED accounts can sign in
  if (user.approvalStatus === 'PENDING') {
    throw new AppError(
      403,
      'ACCOUNT_PENDING_APPROVAL',
      'Your account registration is pending administrator approval. Please contact campus administration.'
    );
  }

  if (user.approvalStatus === 'REJECTED') {
    const reasonMsg = user.rejectionReason ? ` Reason: ${user.rejectionReason}` : '';
    throw new AppError(
      403,
      'ACCOUNT_REJECTED',
      `Your account registration was rejected by the administrator.${reasonMsg}`
    );
  }

  if (!user.isActive) {
    throw new AppError(403, 'FORBIDDEN', 'This account has been deactivated. Contact your administrator.');
  }

  const token = signToken(user);
  return { token, user: sanitizeUser(user) };
}

// ─── Get current user ─────────────────────────────────────────────────────────

/**
 * Returns the authenticated user's full profile.
 *
 * @param {string} userId - From req.user.id (JWT payload)
 * @returns {object} Sanitized user
 */
export async function getCurrentUser(userId) {
  const user = await User.findById(userId)
    .populate('institution', 'name slug code')
    .populate('department', 'name code')
    .lean();

  if (!user) {
    throw new AppError(404, 'NOT_FOUND', 'User account not found.');
  }

  return sanitizeUser(user);
}
