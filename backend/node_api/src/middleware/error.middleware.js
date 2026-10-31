/**
 * src/middleware/error.middleware.js
 *
 * Two middleware functions:
 *
 *  notFoundHandler  — Returns a JSON 404 for any unmatched /api/* route.
 *                     Must be mounted AFTER all route handlers.
 *
 *  errorHandler     — Global Express error handler (4-argument signature).
 *                     Translates known error types into the standard API envelope.
 *                     Must be the LAST middleware registered in app.js.
 *
 * Standard error envelope (from docs/API_CONTRACT.md):
 *   { success: false, error: { code, message, details? } }
 */

import { env } from '../config/env.js';
import { AppError } from '../utils/AppError.js';

// ─── 404 handler ─────────────────────────────────────────────────────────────

export function notFoundHandler(req, res) {
  res.status(404).json({
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: `Route ${req.method} ${req.originalUrl} does not exist.`,
    },
  });
}

// ─── Global error handler ─────────────────────────────────────────────────────

// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, next) {
  const isDev = env.NODE_ENV === 'development';

  // ── Mongoose validation error ──────────────────────────────────────────────
  if (err.name === 'ValidationError') {
    const details = Object.values(err.errors).map((e) => ({
      field: e.path,
      message: e.message,
    }));
    return res.status(400).json({
      success: false,
      error: { code: 'VALIDATION_ERROR', message: 'Data validation failed.', details },
    });
  }

  // ── Mongoose duplicate key (e.g. email unique index) ──────────────────────
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue ?? {})[0] ?? 'field';
    return res.status(409).json({
      success: false,
      error: {
        code: 'CONFLICT',
        message: `A record with this ${field} already exists.`,
      },
    });
  }

  // ── Mongoose CastError (invalid ObjectId in URL param) ────────────────────
  if (err.name === 'CastError') {
    return res.status(400).json({
      success: false,
      error: { code: 'VALIDATION_ERROR', message: `Invalid value for field '${err.path}'.` },
    });
  }

  // ── JWT errors ────────────────────────────────────────────────────────────
  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError' || err.name === 'NotBeforeError') {
    return res.status(401).json({
      success: false,
      error: { code: 'INVALID_TOKEN', message: 'Authentication token is invalid or has expired.' },
    });
  }

  // ── Application errors (thrown with AppError) ─────────────────────────────
  if (err instanceof AppError) {
    const body = {
      success: false,
      error: { code: err.errorCode, message: err.message },
    };
    if (err.details) body.error.details = err.details;
    return res.status(err.statusCode).json(body);
  }

  // ── Unknown / unhandled errors ────────────────────────────────────────────
  console.error('Unhandled error:', err);
  res.status(500).json({
    success: false,
    error: {
      code: 'INTERNAL_ERROR',
      message: isDev ? err.message : 'An unexpected error occurred. Please try again.',
      ...(isDev && { stack: err.stack }),
    },
  });
}
