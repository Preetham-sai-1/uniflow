/**
 * src/controllers/staff.controller.js
 */

import { asyncHandler } from '../utils/asyncHandler.js';
import * as requestService from '../services/request.service.js';
import * as adminService from '../services/admin.service.js';

export const getStaffQueue = asyncHandler(async (req, res) => {
  const queue = await requestService.getStaffQueue(req.user, {
    page: req.query.page ? parseInt(req.query.page, 10) : 1,
    limit: req.query.limit ? parseInt(req.query.limit, 10) : 50,
  });

  res.status(200).json({
    success: true,
    data: queue,
  });
});

export const approveStep = asyncHandler(async (req, res) => {
  const { id, stepIndex } = req.params;
  const { comment } = req.body;

  const request = await requestService.actionStep({
    requestId: id,
    stepIndex: parseInt(stepIndex, 10),
    action: 'APPROVE',
    actorUser: req.user,
    comment,
  });

  res.status(200).json({
    success: true,
    data: request,
  });
});

export const rejectStep = asyncHandler(async (req, res) => {
  const { id, stepIndex } = req.params;
  const { comment } = req.body;

  const request = await requestService.actionStep({
    requestId: id,
    stepIndex: parseInt(stepIndex, 10),
    action: 'REJECT',
    actorUser: req.user,
    comment,
  });

  res.status(200).json({
    success: true,
    data: request,
  });
});

export const listStudents = asyncHandler(async (req, res) => {
  const institutionId = req.user.institution || null;
  const { search, approvalStatus, page, limit } = req.query;

  const result = await adminService.listAllUsers({
    institutionId,
    role: 'student',
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

export const getPendingStudents = asyncHandler(async (req, res) => {
  const institutionId = req.user.institution || null;
  const pendingUsers = await adminService.listPendingRegistrations(institutionId);
  const pendingStudents = pendingUsers.filter((u) => u.role === 'student');

  res.status(200).json({
    success: true,
    data: pendingStudents,
  });
});

export const createStudent = asyncHandler(async (req, res) => {
  const { name, email, password, studentId, department, departmentId } = req.body;

  const result = await adminService.createUser({
    name,
    email,
    password,
    role: 'student', // Staff can only create student accounts
    departmentId: departmentId || department,
    studentId,
    creatorId: req.user.id,
    creatorRole: req.user.role,
    institutionId: req.user.institution,
  });

  res.status(201).json({
    success: true,
    data: result.user,
    message: result.message,
  });
});

export const approveStudent = asyncHandler(async (req, res) => {
  const result = await adminService.approveRegistration(
    req.params.id,
    req.user.id,
    req.user.role
  );

  res.status(200).json({
    success: true,
    data: result,
  });
});

export const rejectStudent = asyncHandler(async (req, res) => {
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

export const deleteStudent = asyncHandler(async (req, res) => {
  const result = await adminService.deleteUser(req.params.id, req.user.id, req.user.role);

  res.status(200).json({
    success: true,
    data: result,
  });
});
