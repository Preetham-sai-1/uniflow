/**
 * src/routes/auth.routes.js
 *
 * Authentication endpoints (from docs/API_CONTRACT.md §6.1):
 *
 *   POST /api/auth/register  [PUBLIC]   — create a new account
 *   POST /api/auth/login     [PUBLIC]   — authenticate and receive a JWT
 *   GET  /api/auth/me        [auth]     — get the current user's profile
 */

import { Router } from 'express';
import { validate } from '../middleware/validate.middleware.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { registerSchema, loginSchema } from '../validators/auth.validators.js';
import * as authController from '../controllers/auth.controller.js';

const router = Router();

// POST /api/auth/register
router.post('/register', validate(registerSchema), authController.register);

// POST /api/auth/login
router.post('/login', validate(loginSchema), authController.login);

// GET /api/auth/me
router.get('/me', authenticate, authController.getMe);

export default router;
