/**
 * src/validators/user.validators.js
 *
 * Zod schemas for user management endpoints.
 */

import { z } from 'zod';

export const adminCreateUserSchema = z.object({
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

  role: z.enum(['student', 'staff'], {
    errorMap: () => ({
      message: 'Role must be student or staff. Admin accounts cannot be created here.',
    }),
  }),

  departmentId: z.string().trim().optional(),
  studentId: z.string().trim().optional(),
  staffId: z.string().trim().optional(),
});

export const adminChangeRoleSchema = z.object({
  role: z.enum(['student', 'staff'], {
    errorMap: () => ({
      message: 'Role must be either student or staff.',
    }),
  }),
});

export const staffCreateStudentSchema = z.object({
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

  studentId: z
    .string({ required_error: 'Student ID is required.' })
    .trim()
    .min(1, 'Student ID is required.'),

  department: z.string().trim().optional(),
  departmentId: z.string().trim().optional(),

  role: z.literal('student').optional(),
});

export const rejectRegistrationSchema = z.object({
  reason: z.string().trim().optional(),
});

