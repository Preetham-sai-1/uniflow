/**
 * src/middleware/auth.middleware.js
 *
 * authenticate() — verifies the JWT from the Authorization header and
 * attaches req.user = { id, role, email } to every downstream handler.
 *
 * Security rules (from AGENTS.md §5):
 *  - Role is read from the verified JWT payload, never from the request body.
 *  - A missing or malformed token returns 401, not 403.
 *  - JWT errors are caught and forwarded to the global error handler,
 *    which maps them to the correct 401 response.
 */

import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { AppError } from '../utils/AppError.js';
import { asyncHandler } from '../utils/asyncHandler.js';

/**
 * Middleware that verifies the JWT in `Authorization: Bearer <token>`.
 * Attaches req.user = { id, role, email } on success.
 * Calls next(AppError 401) if the header is absent or the token is invalid.
 */
export const authenticate = asyncHandler(async (req, _res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new AppError(
      401,
      'MISSING_TOKEN',
      'Authentication required. Provide a Bearer token in the Authorization header.'
    );
  }

  const token = authHeader.slice(7); // Remove "Bearer " prefix

  // jwt.verify throws JsonWebTokenError / TokenExpiredError on failure.
  // The global error handler translates those to 401 responses.
  const payload = jwt.verify(token, env.JWT_SECRET);

  // Attach only what downstream middleware / controllers need.
  // Never expose the full payload — only the fields we explicitly trust.
  req.user = {
    id: payload.userId,
    role: payload.role,
    email: payload.email,
  };

  next();
});
