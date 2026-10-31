/**
 * src/validators/auth.validators.js
 *
 * Zod schemas for authentication endpoint request bodies.
 * Used by the validate() middleware factory in middleware/validate.middleware.js.
 */

import { z } from 'zod';

export const registerSchema = z.object({
  name: z
    .string({ required_error: 'Name is required.' })
    .trim()
    .min(2, 'Name must be at least 2 characters.')
    .max(100, 'Name cannot exceed 100 characters.'),

  email: z
    .string({ required_error: 'Email is required.' })
    .trim()
    .toLowerCase()
    .email('Please provide a valid email address.'),

  password: z
    .string({ required_error: 'Password is required.' })
    .min(8, 'Password must be at least 8 characters.'),

  role: z
    .enum(['student'], {
      invalid_type_error: 'Public registration is only permitted for students. Staff and admin accounts must be provisioned administratively.',
    })
    .default('student'),

  // Optional — ObjectId string for the department the user belongs to
  departmentId: z.string().optional(),

  // Optional — student roll number
  studentId: z.string().trim().optional(),
});

export const loginSchema = z.object({
  email: z
    .string({ required_error: 'Email is required.' })
    .trim()
    .toLowerCase()
    .email('Please provide a valid email address.'),

  password: z
    .string({ required_error: 'Password is required.' })
    .min(1, 'Password is required.'),
});
