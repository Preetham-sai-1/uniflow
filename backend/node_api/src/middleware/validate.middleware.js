/**
 * src/middleware/validate.middleware.js
 *
 * Generic Zod validation middleware factory.
 *
 * Usage:
 *   import { validate } from '../middleware/validate.middleware.js';
 *   import { registerSchema } from '../validators/auth.validators.js';
 *
 *   router.post('/register', validate(registerSchema), authController.register);
 *
 * On success:  req.body is replaced with the parsed + coerced Zod output.
 * On failure:  calls next(AppError) with VALIDATION_ERROR and a details array.
 */

import { AppError } from '../utils/AppError.js';

export const validate = (schema) => (req, res, next) => {
  const result = schema.safeParse(req.body);

  if (!result.success) {
    const details = result.error.errors.map((e) => ({
      field: e.path.join('.') || 'body',
      message: e.message,
    }));
    return next(new AppError(400, 'VALIDATION_ERROR', 'Input validation failed.', details));
  }

  // Replace req.body with the parsed and coerced data (e.g. email lowercased)
  req.body = result.data;
  next();
};
