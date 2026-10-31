/**
 * src/services/department.service.js
 *
 * Business logic for institutional departments.
 */

import Department from '../models/Department.js';

export async function getAllDepartments(institutionId = null) {
  const query = { isActive: true };
  if (institutionId) {
    query.institution = institutionId;
  }
  return Department.find(query).sort({ name: 1 }).select('_id name code institution isActive');
}

export async function getDepartmentById(id) {
  return Department.findById(id);
}
