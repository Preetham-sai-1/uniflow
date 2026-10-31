/**
 * src/routes/department.routes.js
 */

import { Router } from 'express';
import { listDepartments } from '../controllers/department.controller.js';

const router = Router();

// GET /api/departments — list active departments
router.get('/', listDepartments);

export default router;
