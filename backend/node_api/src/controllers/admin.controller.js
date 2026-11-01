/**
 * src/controllers/admin.controller.js
 */

import { asyncHandler } from '../utils/asyncHandler.js';
import * as requestService from '../services/request.service.js';
import * as adminService from '../services/admin.service.js';

export const getAdminStats = asyncHandler(async (req, res) => {
  const institutionId = req.user.institution || null;
  const stats = await requestService.getAdminStats(institutionId);

  res.status(200).json({
    success: true,
    data: stats,
  });
});

export const listAllRequests = asyncHandler(async (req, res) => {
  const { status, serviceId, page, limit } = req.query;

  const result = await requestService.listRequests({
    user: req.user,
    status,
    serviceId,
    page: page ? parseInt(page, 10) : 1,
    limit: limit ? parseInt(limit, 10) : 50,
  });

  res.status(200).json({
    success: true,
    data: result.items,
    pagination: result.pagination,
  });
});

export const listUsers = asyncHandler(async (req, res) => {
  const institutionId = req.user.institution || null;
  const { role, approvalStatus, search, page, limit } = req.query;

  const result = await adminService.listAllUsers({
    institutionId,
    role,
    approvalStatus,
    search,
    page: page ? parseInt(page, 10) : 1,
    limit: limit ? parseInt(limit, 10) : 50,
  });

  res.status(200).json({
    success: true,
    data: result.items,
    pagination: result.pagination,
  });
});

export const createUser = asyncHandler(async (req, res) => {
  const institutionId = req.user.institution || null;
  const result = await adminService.createUser({
    ...req.body,
    creatorId: req.user.id,
    institutionId,
  });

  res.status(201).json({
    success: true,
    data: result,
  });
});

export const changeUserRole = asyncHandler(async (req, res) => {
  const { role } = req.body;
  const result = await adminService.changeUserRole(req.params.id, role, req.user.id);

  res.status(200).json({
    success: true,
    data: result,
  });
});

export const deleteUser = asyncHandler(async (req, res) => {
  const result = await adminService.deleteUser(req.params.id, req.user.id, req.user.role);

  res.status(200).json({
    success: true,
    data: result,
  });
});

export const listPendingUsers = asyncHandler(async (req, res) => {
  const institutionId = req.user.institution || null;
  const pendingUsers = await adminService.listPendingRegistrations(institutionId);

  res.status(200).json({
    success: true,
    data: pendingUsers,
  });
});

export const approveUser = asyncHandler(async (req, res) => {
  const result = await adminService.approveRegistration(req.params.id, req.user.id, req.user.role);

  res.status(200).json({
    success: true,
    data: result,
  });
});

export const rejectUser = asyncHandler(async (req, res) => {
  const { reason } = req.body;
  const result = await adminService.rejectRegistration(
    req.params.id,
    req.user.id,
    req.user.role,
    reason
  );

  res.status(200).json({
    success: true,
    data: result,
  });
});
