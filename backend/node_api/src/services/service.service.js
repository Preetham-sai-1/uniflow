/**
 * src/services/service.service.js
 *
 * Business logic for service catalogue.
 */

import mongoose from 'mongoose';
import Service from '../models/Service.js';
import Workflow from '../models/Workflow.js';
import { AppError } from '../utils/AppError.js';

export async function listServices({ institutionId = null, category = null } = {}) {
  const filter = { isActive: true };
  if (institutionId) {
    filter.institution = institutionId;
  }
  if (category) {
    filter.category = category;
  }

  const services = await Service.find(filter)
    .populate('workflow', 'steps version')
    .populate('responsibleDepartment', 'name code')
    .sort({ name: 1 })
    .lean();

  return services.map((s) => ({
    id: s._id.toString(),
    name: s.name,
    slug: s.slug,
    description: s.description,
    category: s.category,
    estimatedDays: s.estimatedDays,
    requiredDocuments: s.requiredDocuments || [],
    responsibleDepartment: s.responsibleDepartment
      ? {
          id: s.responsibleDepartment._id.toString(),
          name: s.responsibleDepartment.name,
          code: s.responsibleDepartment.code,
        }
      : null,
    workflowStepCount: s.workflow?.steps?.length || 0,
    isActive: s.isActive,
  }));
}

export async function getServiceByIdOrSlug(idOrSlug) {
  const isObjectId = mongoose.Types.ObjectId.isValid(idOrSlug) && String(new mongoose.Types.ObjectId(idOrSlug)) === idOrSlug;
  const filter = isObjectId ? { _id: idOrSlug } : { slug: idOrSlug.toLowerCase() };

  const service = await Service.findOne(filter)
    .populate('workflow')
    .populate('responsibleDepartment', 'name code')
    .lean();

  if (!service) {
    throw AppError.notFound(`Service not found with identifier: ${idOrSlug}`);
  }

  return {
    id: service._id.toString(),
    name: service.name,
    slug: service.slug,
    description: service.description,
    category: service.category,
    estimatedDays: service.estimatedDays,
    requiredDocuments: service.requiredDocuments || [],
    formFields: service.formFields || [],
    responsibleDepartment: service.responsibleDepartment
      ? {
          id: service.responsibleDepartment._id.toString(),
          name: service.responsibleDepartment.name,
          code: service.responsibleDepartment.code,
        }
      : null,
    workflow: service.workflow
      ? {
          id: service.workflow._id.toString(),
          name: service.workflow.name,
          version: service.workflow.version,
          steps: service.workflow.steps || [],
        }
      : null,
    workflowSteps: service.workflow?.steps || [],
    isActive: service.isActive,
  };
}

export async function createService(data, institutionId) {
  const slug = data.slug || data.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');

  const existing = await Service.findOne({ slug });
  if (existing) {
    throw AppError.conflict(`A service with slug "${slug}" already exists.`);
  }

  const service = new Service({
    name: data.name,
    slug,
    description: data.description,
    category: data.category,
    estimatedDays: data.estimatedDays ?? 3,
    requiredDocuments: data.requiredDocuments ?? [],
    responsibleDepartment: data.responsibleDepartmentId,
    institution: institutionId,
    formFields: data.formFields ?? [],
    isActive: true,
  });

  await service.save();

  if (data.workflowSteps && data.workflowSteps.length > 0) {
    const workflow = new Workflow({
      name: `${data.name} Workflow`,
      service: service._id,
      institution: institutionId,
      version: 1,
      steps: data.workflowSteps,
      isActive: true,
    });
    await workflow.save();

    service.workflow = workflow._id;
    await service.save();
  }

  return getServiceByIdOrSlug(service._id.toString());
}
