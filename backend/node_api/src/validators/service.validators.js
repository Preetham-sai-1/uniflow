/**
 * src/validators/service.validators.js
 */

import { z } from 'zod';

const formFieldSchema = z.object({
  name: z.string().min(1, 'Field name is required'),
  label: z.string().min(1, 'Field label is required'),
  type: z.enum(['text', 'textarea', 'number', 'select', 'date', 'datetime', 'checkbox']),
  options: z.array(z.string()).optional().default([]),
  required: z.boolean().optional().default(true),
  placeholder: z.string().optional().default(''),
});

const workflowStepSchema = z.object({
  stepIndex: z.number().int().min(0),
  name: z.string().min(1, 'Step name is required'),
  description: z.string().optional().default(''),
  assignedRole: z.enum(['student', 'staff', 'admin']),
  department: z.string().optional().nullable(),
  isPaymentStep: z.boolean().optional().default(false),
  pendingStatus: z.string().min(1, 'pendingStatus is required'),
  requiresComment: z.boolean().optional().default(false),
});

export const createServiceSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters').max(150),
  slug: z.string().min(2).max(100).regex(/^[a-z0-9-]+$/, 'Slug may only contain lowercase letters, numbers, and hyphens').optional(),
  description: z.string().min(5, 'Description must be at least 5 characters').max(1000),
  category: z.enum(['Academic', 'Identity', 'Resources', 'Finance', 'Other']),
  estimatedDays: z.number().int().min(1).optional().default(3),
  requiredDocuments: z.array(z.string()).optional().default([]),
  responsibleDepartmentId: z.string().min(1, 'Responsible department ID is required'),
  formFields: z.array(formFieldSchema).optional().default([]),
  workflowSteps: z.array(workflowStepSchema).min(1, 'At least one workflow step is required').optional(),
});
