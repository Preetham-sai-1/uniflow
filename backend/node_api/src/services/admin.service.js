/**
 * src/services/admin.service.js
 *
 * Business logic for administrative user approvals, role assignments,
 * user provisioning, and secure account deletion.
 */

import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import { env } from '../config/env.js';
import User, { APPROVAL_STATUSES, USER_ROLES } from '../models/User.js';
import Department from '../models/Department.js';
import Institution from '../models/Institution.js';
import UserDeletionAudit from '../models/UserDeletionAudit.js';
import { AppError } from '../utils/AppError.js';

export function sanitizeUser(user) {
  const dept = user.department;
  let formattedDept = null;
  if (dept) {
    if (typeof dept === 'object' && dept._id) {
      formattedDept = {
        id: dept._id.toString(),
        name: dept.name || '',
        code: dept.code || '',
      };
    } else if (typeof dept === 'object' && dept.name) {
      formattedDept = {
        id: (dept.id || '').toString(),
        name: dept.name || '',
        code: dept.code || '',
      };
    } else {
      formattedDept = dept.toString();
    }
  }

  const inst = user.institution;
  let formattedInst = null;
  if (inst) {
    if (typeof inst === 'object' && inst._id) {
      formattedInst = {
        id: inst._id.toString(),
        name: inst.name || '',
        code: inst.code || '',
      };
    } else {
      formattedInst = inst.toString();
    }
  }

  return {
    id: user._id ? user._id.toString() : user.id,
    name: user.name,
    email: user.email,
    role: user.role,
    institution: formattedInst,
    department: formattedDept,
    studentId: user.studentId ?? null,
    staffId: user.staffId ?? null,
    mustChangePassword: Boolean(user.mustChangePassword),
    approvalStatus: user.approvalStatus ?? 'APPROVED',
    rejectionReason: user.rejectionReason ?? null,
    approvedAt: user.approvedAt ?? null,
    approvedBy: user.approvedBy ? user.approvedBy.toString() : null,
    isActive: Boolean(user.isActive),
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
    id: u._id.toString(),
    name: u.name,
    email: u.email,
    role: u.role,
    studentId: u.studentId ?? '',
    staffId: u.staffId ?? '',
    department: u.department ? (u.department.name || u.department.code || '') : '',
    institution: u.institution ? (u.institution.name || u.institution.code || '') : '',
    approvalStatus: u.approvalStatus,
    createdAt: u.createdAt,
  }));
}

/**
 * Lists all users with role, approvalStatus, and text search filters.
 * @param {object} params
 * @param {string|null} [params.institutionId]
 * @param {string|null} [params.role]
 * @param {string|null} [params.approvalStatus]
 * @param {string|null} [params.search]
 * @param {number} [params.page=1]
 * @param {number} [params.limit=50]
 * @returns {Promise<{ items: Array, pagination: object }>}
 */
export async function listAllUsers({
  institutionId = null,
  role = null,
  approvalStatus = null,
  search = null,
  page = 1,
  limit = 50,
}) {
  const query = {};

  if (institutionId) {
    query.institution = institutionId;
  }

  if (role && role !== 'all') {
    query.role = role;
  }

  if (approvalStatus && approvalStatus !== 'all') {
    query.approvalStatus = approvalStatus;
  }

  if (search && search.trim()) {
    const s = search.trim();
    const escaped = s.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
    const regex = new RegExp(escaped, 'i');
    query.$or = [
      { name: regex },
      { email: regex },
      { studentId: regex },
      { staffId: regex },
    ];
  }

  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.max(1, Math.min(100, parseInt(limit, 10) || 50));
  const skip = (pageNum - 1) * limitNum;

  const total = await User.countDocuments(query);
  const users = await User.find(query)
    .populate('department', 'name code')
    .populate('institution', 'name slug code')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limitNum)
    .lean();

  return {
    items: users.map(sanitizeUser),
    pagination: {
      total,
      page: pageNum,
      limit: limitNum,
      pages: Math.ceil(total / limitNum) || 1,
    },
  };
}

/**
 * Creates a student or staff account administratively.
 * Enforces role: student | staff (never admin).
 * @param {object} params
 * @returns {Promise<object>}
 */
export async function createUser({
  name,
  email,
  password,
  role,
  departmentId,
  studentId,
  staffId,
  creatorId,
  creatorRole,
  institutionId,
}) {
  if (creatorRole === USER_ROLES.STAFF && role !== USER_ROLES.STUDENT) {
    throw new AppError(
      403,
      'FORBIDDEN',
      'Staff members are only permitted to create student accounts.'
    );
  }

  if (!['student', 'staff'].includes(role)) {
    throw new AppError(
      400,
      'VALIDATION_ERROR',
      'Role must be either student or staff. Admin accounts cannot be created here.'
    );
  }

  let targetInstitutionId = institutionId;
  if (!targetInstitutionId) {
    const inst = await Institution.findOne({ isActive: true }).lean();
    if (!inst) {
      throw new AppError(
        503,
        'INTERNAL_ERROR',
        'No active institution found.'
      );
    }
    targetInstitutionId = inst._id;
  }

  const normalizedEmail = email.trim().toLowerCase();

  const existingEmail = await User.findOne({ email: normalizedEmail }).lean();
  if (existingEmail) {
    throw new AppError(409, 'CONFLICT', 'An account with this email address already exists.');
  }

  const trimmedStudentId =
    role === 'student' && studentId && studentId.trim().length > 0
      ? studentId.trim()
      : null;

  if (trimmedStudentId) {
    const existingStudentId = await User.findOne({ studentId: trimmedStudentId }).lean();
    if (existingStudentId) {
      throw new AppError(409, 'CONFLICT', 'A student account with this Student ID already exists.');
    }
  }

  const trimmedStaffId =
    role === 'staff' && staffId && staffId.trim().length > 0
      ? staffId.trim()
      : null;

  if (trimmedStaffId) {
    const existingStaffId = await User.findOne({ staffId: trimmedStaffId }).lean();
    if (existingStaffId) {
      throw new AppError(409, 'CONFLICT', 'A staff account with this Staff ID already exists.');
    }
  }

  let department = null;
  if (departmentId) {
    if (!mongoose.isValidObjectId(departmentId)) {
      throw new AppError(400, 'VALIDATION_ERROR', 'Invalid department ID.');
    }
    department = await Department.findOne({
      _id: departmentId,
      institution: targetInstitutionId,
      isActive: true,
    }).lean();
    if (!department) {
      throw new AppError(404, 'NOT_FOUND', 'Department not found in this institution.');
    }
  }

  const passwordHash = await bcrypt.hash(password, env.BCRYPT_SALT_ROUNDS || 10);

  const user = await User.create({
    name: name.trim(),
    email: normalizedEmail,
    passwordHash,
    role,
    institution: targetInstitutionId,
    department: department ? department._id : null,
    studentId: trimmedStudentId,
    staffId: trimmedStaffId,
    approvalStatus: APPROVAL_STATUSES.APPROVED,
    mustChangePassword: true,
    approvedAt: new Date(),
    approvedBy: creatorId,
    approvedByRole: creatorRole || (role === 'staff' ? 'admin' : null),
    createdBy: creatorId,
    createdByRole: creatorRole || null,
    isActive: true,
  });

  return {
    user: sanitizeUser(user),
    message: `${role === 'staff' ? 'Staff' : 'Student'} account created successfully.`,
  };
}

/**
 * Changes a user's role strictly between 'student' and 'staff'.
 * Rejects if target is admin or if attempting to assign admin role.
 * @param {string} userId
 * @param {string} newRole
 * @param {string} adminId
 * @returns {Promise<object>}
 */
export async function changeUserRole(userId, newRole, adminId) {
  if (!['student', 'staff'].includes(newRole)) {
    throw new AppError(
      400,
      'VALIDATION_ERROR',
      'Role can only be changed to student or staff. Admin role cannot be assigned.'
    );
  }

  if (!mongoose.isValidObjectId(userId)) {
    throw new AppError(400, 'VALIDATION_ERROR', 'Invalid user ID.');
  }

  const user = await User.findById(userId);
  if (!user) {
    throw new AppError(404, 'NOT_FOUND', 'User not found.');
  }

  if (user.role === USER_ROLES.ADMIN) {
    throw new AppError(
      403,
      'FORBIDDEN',
      'Administrator accounts cannot be demoted through user management.'
    );
  }

  if (user.role === newRole) {
    return {
      user: sanitizeUser(user),
      message: `User is already assigned to the ${newRole} role.`,
    };
  }

  user.role = newRole;
  if (newRole === 'student') {
    user.staffId = null;
  }
  await user.save();

  return {
    user: sanitizeUser(user),
    message: `User role successfully changed to ${newRole}.`,
  };
}

/**
 * Permanently deletes a user account with strict safeguards and audit tracking.
 * Staff can delete students only.
 * Admin can delete students and staff.
 * Never allows deleting admins or self.
 * @param {string} targetUserId
 * @param {string} actorId
 * @param {string} actorRole
 * @returns {Promise<object>}
 */
export async function deleteUser(targetUserId, actorId, actorRole) {
  if (!actorId) {
    throw new AppError(401, 'UNAUTHORIZED', 'Actor identification required.');
  }

  if (!mongoose.isValidObjectId(targetUserId)) {
    throw new AppError(400, 'VALIDATION_ERROR', 'Invalid user ID.');
  }

  if (targetUserId.toString() === actorId.toString()) {
    throw new AppError(400, 'CANNOT_DELETE_SELF', 'You cannot delete your own account.');
  }

  const targetUser = await User.findById(targetUserId);
  if (!targetUser) {
    throw new AppError(404, 'NOT_FOUND', 'User not found.');
  }

  if (targetUser.role === USER_ROLES.ADMIN) {
    throw new AppError(
      403,
      'FORBIDDEN',
      'Administrator accounts cannot be deleted.'
    );
  }

  if (actorRole === USER_ROLES.STAFF && targetUser.role !== USER_ROLES.STUDENT) {
    throw new AppError(
      403,
      'FORBIDDEN',
      'Staff members are only permitted to delete student accounts.'
    );
  }

  // Audit record for permanent account deletion
  await UserDeletionAudit.create({
    deletedUserId: targetUser._id,
    deletedUserRole: targetUser.role,
    deletedUserName: targetUser.name,
    deletedUserEmail: targetUser.email,
    deletedUserIdentifier: targetUser.studentId || targetUser.staffId || null,
    deletedUserDepartment: targetUser.department || null,
    deletedBy: actorId,
    deletedByRole: actorRole,
    institution: targetUser.institution,
    deletedAt: new Date(),
  });

  // Permanently delete user document. Historical service requests remain intact.
  await User.findByIdAndDelete(targetUser._id);

  return {
    success: true,
    message: `Account for ${targetUser.name} (${targetUser.email}) has been permanently deleted.`,
    deletedUserId: targetUser._id.toString(),
  };
}

/**
 * Approves a pending user registration.
 * @param {string} userId
 * @param {string} actorId
 * @param {string} [actorRole]
 * @returns {Promise<object>}
 */
export async function approveRegistration(userId, actorId, actorRole = null) {
  if (!mongoose.isValidObjectId(userId)) {
    throw new AppError(400, 'VALIDATION_ERROR', 'Invalid user ID.');
  }

  const user = await User.findById(userId);
  if (!user) {
    throw new AppError(404, 'NOT_FOUND', 'User registration not found.');
  }

  if (actorRole === USER_ROLES.STAFF && user.role !== USER_ROLES.STUDENT) {
    throw new AppError(
      403,
      'FORBIDDEN',
      'Staff members are only permitted to approve student registrations.'
    );
  }

  if (user.approvalStatus === APPROVAL_STATUSES.APPROVED) {
    return {
      user: sanitizeUser(user),
      message: 'User is already approved.',
    };
  }

  user.approvalStatus = APPROVAL_STATUSES.APPROVED;
  user.approvedAt = new Date();
  user.approvedBy = actorId;
  user.approvedByRole = actorRole || null;
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
 * @param {string} actorId
 * @param {string} [actorRole]
 * @param {string} [reason]
 * @returns {Promise<object>}
 */
export async function rejectRegistration(userId, actorId, actorRole = null, reason = null) {
  if (!mongoose.isValidObjectId(userId)) {
    throw new AppError(400, 'VALIDATION_ERROR', 'Invalid user ID.');
  }

  const user = await User.findById(userId);
  if (!user) {
    throw new AppError(404, 'NOT_FOUND', 'User registration not found.');
  }

  if (actorRole === USER_ROLES.STAFF && user.role !== USER_ROLES.STUDENT) {
    throw new AppError(
      403,
      'FORBIDDEN',
      'Staff members are only permitted to reject student registrations.'
    );
  }

  user.approvalStatus = APPROVAL_STATUSES.REJECTED;
  user.rejectionReason =
    reason && typeof reason === 'string' && reason.trim()
      ? reason.trim()
      : `Registration rejected by ${actorRole === 'staff' ? 'staff member' : 'administrator'}.`;
  user.rejectedAt = new Date();
  user.rejectedBy = actorId;
  user.rejectedByRole = actorRole || null;

  await user.save();

  return {
    user: sanitizeUser(user),
    message: 'User registration rejected.',
  };
}
