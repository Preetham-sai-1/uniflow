/**
 * src/controllers/staff.controller.js
 */

import { asyncHandler } from '../utils/asyncHandler.js';
import * as requestService from '../services/request.service.js';

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
