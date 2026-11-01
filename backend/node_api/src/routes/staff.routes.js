/**
 * src/routes/staff.routes.js
 */

import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireRole } from '../middleware/role.middleware.js';
import { validate } from '../middleware/validate.middleware.js';
import { approveStepSchema, rejectStepSchema } from '../validators/request.validators.js';
import {
  staffCreateStudentSchema,
  rejectRegistrationSchema,
} from '../validators/user.validators.js';
import {
  getStaffQueue,
  approveStep,
  rejectStep,
  listStudents,
  getPendingStudents,
  createStudent,
  approveStudent,
  rejectStudent,
  deleteStudent,
} from '../controllers/staff.controller.js';

const router = Router();

// GET /api/staff/queue — review queue
router.get('/queue', authenticate, requireRole('staff', 'admin'), getStaffQueue);

// GET /api/staff/pending-students (and alias /students/pending) — list pending student registrations
router.get('/pending-students', authenticate, requireRole('staff', 'admin'), getPendingStudents);
router.get('/students/pending', authenticate, requireRole('staff', 'admin'), getPendingStudents);

// POST /api/staff/students — create student account
router.post(
  '/students',
  authenticate,
  requireRole('staff', 'admin'),
  validate(staffCreateStudentSchema),
  createStudent
);

// PATCH & POST /api/staff/students/:id/approve — approve pending student registration
router.patch('/students/:id/approve', authenticate, requireRole('staff', 'admin'), approveStudent);
router.post('/students/:id/approve', authenticate, requireRole('staff', 'admin'), approveStudent);

// PATCH & POST /api/staff/students/:id/reject — reject pending student registration
router.patch(
  '/students/:id/reject',
  authenticate,
  requireRole('staff', 'admin'),
  validate(rejectRegistrationSchema),
  rejectStudent
);
router.post(
  '/students/:id/reject',
  authenticate,
  requireRole('staff', 'admin'),
  validate(rejectRegistrationSchema),
  rejectStudent
);

// GET /api/staff/students — list student accounts
router.get('/students', authenticate, requireRole('staff', 'admin'), listStudents);

// DELETE /api/staff/students/:id — permanently delete student account
router.delete('/students/:id', authenticate, requireRole('staff', 'admin'), deleteStudent);

// PATCH /api/staff/requests/:id/steps/:stepIndex/approve
router.patch(
  '/requests/:id/steps/:stepIndex/approve',
  authenticate,
  requireRole('staff', 'admin'),
  validate(approveStepSchema),
  approveStep
);

// PATCH /api/staff/requests/:id/steps/:stepIndex/reject
router.patch(
  '/requests/:id/steps/:stepIndex/reject',
  authenticate,
  requireRole('staff', 'admin'),
  validate(rejectStepSchema),
  rejectStep
);

export default router;
