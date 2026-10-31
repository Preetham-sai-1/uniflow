/**
 * src/controllers/service.controller.js
 */

import { asyncHandler } from '../utils/asyncHandler.js';
import * as serviceService from '../services/service.service.js';

export const listServices = asyncHandler(async (req, res) => {
  const institutionId = req.user?.institution || req.query.institutionId || null;
  const category = req.query.category || null;

  const services = await serviceService.listServices({ institutionId, category });
  res.status(200).json({
    success: true,
    data: services,
  });
});

export const getService = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const service = await serviceService.getServiceByIdOrSlug(id);
  res.status(200).json({
    success: true,
    data: service,
  });
});

export const createService = asyncHandler(async (req, res) => {
  const institutionId = req.user.institution;
  const service = await serviceService.createService(req.body, institutionId);
  res.status(201).json({
    success: true,
    data: service,
  });
});
