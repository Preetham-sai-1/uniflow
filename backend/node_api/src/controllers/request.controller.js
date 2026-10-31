/**
 * src/controllers/request.controller.js
 */

import { asyncHandler } from '../utils/asyncHandler.js';
import * as requestService from '../services/request.service.js';

export const submitRequest = asyncHandler(async (req, res) => {
  const { serviceId, formData } = req.body;
  const studentId = req.user.id;

  const request = await requestService.createRequest({
    studentId,
    serviceId,
    formData,
  });

  res.status(201).json({
    success: true,
    data: request,
  });
});

export const listRequests = asyncHandler(async (req, res) => {
  const { status, serviceId, page, limit } = req.query;
  const result = await requestService.listRequests({
    user: req.user,
    status,
    serviceId,
    page: page ? parseInt(page, 10) : 1,
    limit: limit ? parseInt(limit, 10) : 20,
  });

  res.status(200).json({
    success: true,
    data: result.items,
    pagination: result.pagination,
  });
});

export const getRequest = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const request = await requestService.getRequestById(id, req.user);

  res.status(200).json({
    success: true,
    data: request,
  });
});

export const confirmPayment = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const request = await requestService.confirmPayment({
    requestId: id,
    studentUser: req.user,
  });

  res.status(200).json({
    success: true,
    data: request,
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
