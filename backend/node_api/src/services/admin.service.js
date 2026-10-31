/**
 * src/services/admin.service.js
 *
 * Business logic for administrative user approvals and governance.
 */

import mongoose from 'mongoose';
import User, { APPROVAL_STATUSES } from '../models/User.js';
import { AppError } from '../utils/AppError.js';

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
    approvedAt: user.approvedAt ?? null,
    approvedBy: user.approvedBy ?? null,
    isActive: user.isActive,
    createdAt: user.createdAt,
  };
}

/**
 * Lists all pending student user registration accounts for approval.
 * @param {string|null} [institutionId]
 * @returns {Promise<Array>}
 */
export async function listPendingRegistrations(institutionId = null) {
  const query = {
    approvalStatus: APPROVAL_STATUSES.PENDING,
  };

  if (institutionId) {
    query.institution = institutionId;
  }

  const users = await User.find(query)
    .populate('department', 'name code')
    .populate('institution', 'name slug code')
    .sort({ createdAt: -1 })
    .lean();

  return users.map((u) => ({
    id: u._id,
    name: u.name,
    email: u.email,
    role: u.role,
    studentId: u.studentId ?? '',
    department: u.department ? (u.department.name || u.department.code || '') : '',
    institution: u.institution ? (u.institution.name || u.institution.code || '') : '',
    approvalStatus: u.approvalStatus,
    createdAt: u.createdAt,
  }));
}

/**
 * Approves a pending user registration.
 * @param {string} userId
 * @param {string} adminId
 * @returns {Promise<object>}
 */
export async function approveRegistration(userId, adminId) {
  if (!mongoose.isValidObjectId(userId)) {
    throw new AppError(400, 'VALIDATION_ERROR', 'Invalid user ID.');
  }

  const user = await User.findById(userId);
  if (!user) {
    throw new AppError(404, 'NOT_FOUND', 'User registration not found.');
  }

  if (user.approvalStatus === APPROVAL_STATUSES.APPROVED) {
    return {
      user: sanitizeUser(user),
      message: 'User is already approved.',
    };
  }

  user.approvalStatus = APPROVAL_STATUSES.APPROVED;
  user.approvedAt = new Date();
  user.approvedBy = adminId;
  user.rejectionReason = null;
  user.isActive = true;

  await user.save();

  return {
    user: sanitizeUser(user),
    message: 'User registration approved successfully.',
  };
}

/**
 * Rejects a pending user registration.
 * @param {string} userId
 * @param {string} adminId
 * @param {string} [reason]
 * @returns {Promise<object>}
 */
export async function rejectRegistration(userId, adminId, reason = null) {
  if (!mongoose.isValidObjectId(userId)) {
    throw new AppError(400, 'VALIDATION_ERROR', 'Invalid user ID.');
  }

  const user = await User.findById(userId);
  if (!user) {
    throw new AppError(404, 'NOT_FOUND', 'User registration not found.');
  }

  user.approvalStatus = APPROVAL_STATUSES.REJECTED;
  user.rejectionReason =
    reason && typeof reason === 'string' && reason.trim()
      ? reason.trim()
      : 'Registration rejected by administrator.';
  user.approvedAt = new Date();
  user.approvedBy = adminId;

  await user.save();

  return {
    user: sanitizeUser(user),
    message: 'User registration rejected.',
  };
}

