/**
 * src/middleware/role.middleware.js
 *
 * requireRole(...allowedRoles) — factory that returns a middleware function
 * which enforces role-based access control AFTER authenticate() has run.
 *
 * Usage (from docs/ARCHITECTURE.md §8):
 *   router.patch(
 *     '/queue/:stepId',
 *     authenticate,
 *     requireRole('staff', 'admin'),
 *     staffController.approveStep
 *   );
 *
 * Security rules (from AGENTS.md §5):
 *  - Role is read from req.user (set by authenticate()), never from req.body.
 *  - authenticate() MUST run before requireRole().
 *  - A student must never be able to approve their own requests —
 *    that additional check is enforced in the service layer, not here.
 */

import { AppError } from '../utils/AppError.js';

/**
 * @param {...string} allowedRoles - One or more role strings ('student', 'staff', 'admin')
 * @returns {Function} Express middleware
 */
export const requireRole = (...allowedRoles) =>
  (req, _res, next) => {
    if (!req.user) {
      // authenticate() must have run first
      return next(
        new AppError(401, 'MISSING_TOKEN', 'Authentication required.')
      );
    }

    if (!allowedRoles.includes(req.user.role)) {
      return next(
        new AppError(
          403,
          'FORBIDDEN',
          `Access denied. Required role: ${allowedRoles.join(' or ')}.`
        )
      );
    }

    next();
  };
