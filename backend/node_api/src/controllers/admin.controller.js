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

export const listPendingUsers = asyncHandler(async (req, res) => {
  const institutionId = req.user.institution || null;
  const pendingUsers = await adminService.listPendingRegistrations(institutionId);

  res.status(200).json({
    success: true,
    data: pendingUsers,
  });
});

export const approveUser = asyncHandler(async (req, res) => {
  const result = await adminService.approveRegistration(req.params.id, req.user.id);

  res.status(200).json({
    success: true,
    data: result,
  });
});

export const rejectUser = asyncHandler(async (req, res) => {
  const { reason } = req.body;
  const result = await adminService.rejectRegistration(req.params.id, req.user.id, reason);

  res.status(200).json({
    success: true,
    data: result,
  });
});
