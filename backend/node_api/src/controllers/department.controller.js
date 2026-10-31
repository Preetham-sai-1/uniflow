/**
 * src/controllers/department.controller.js
 */

import { asyncHandler } from '../utils/asyncHandler.js';
import * as departmentService from '../services/department.service.js';

export const listDepartments = asyncHandler(async (req, res) => {
  const institutionId = req.user?.institution || req.query.institutionId || null;
  const departments = await departmentService.getAllDepartments(institutionId);

  const formatted = departments.map((d) => ({
    id: d._id.toString(),
    name: d.name,
    code: d.code,
    institution: d.institution,
  }));

  res.status(200).json({
    success: true,
    data: formatted,
  });
});
