/**
 * src/validators/request.validators.js
 */

import { z } from 'zod';

export const submitRequestSchema = z.object({
  serviceId: z.string().min(1, 'Service ID is required'),
  formData: z.record(z.any()).optional().default({}),
});

export const approveStepSchema = z.object({
  comment: z.string().optional().default(''),
});

export const rejectStepSchema = z.object({
  comment: z.string().min(1, 'A comment explaining the reason for rejection is required.'),
});
