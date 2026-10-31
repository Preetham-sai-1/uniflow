/**
 * src/controllers/auth.controller.js
 *
 * Thin controller layer for authentication endpoints.
 * Each function: extracts from request → calls service → sends response.
 * No business logic lives here.
 */

import { asyncHandler } from '../utils/asyncHandler.js';
import * as authService from '../services/auth.service.js';

// ─── POST /api/auth/register ──────────────────────────────────────────────────

export const register = asyncHandler(async (req, res) => {
  // req.body is already validated and shaped by the validate() middleware
  const result = await authService.registerUser(req.body);

  res.status(201).json({
    success: true,
    data: result,
  });
});

// ─── POST /api/auth/login ─────────────────────────────────────────────────────

export const login = asyncHandler(async (req, res) => {
  const { token, user } = await authService.loginUser(req.body);

  res.status(200).json({
    success: true,
    data: { token, user },
  });
});

// ─── GET /api/auth/me ─────────────────────────────────────────────────────────

export const getMe = asyncHandler(async (req, res) => {
  // req.user.id is set by the authenticate() middleware from the JWT payload
  const user = await authService.getCurrentUser(req.user.id);

  res.status(200).json({
    success: true,
    data: { user },
  });
});
