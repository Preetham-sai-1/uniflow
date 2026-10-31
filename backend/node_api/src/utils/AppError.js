/**
 * src/utils/AppError.js
 *
 * A structured application error class.
 * Throwing an AppError in any async handler causes the global error middleware
 * to return a consistent JSON error response with the correct HTTP status.
 *
 * Usage:
 *   throw new AppError(404, 'NOT_FOUND', 'Request not found.');
 *   throw AppError.notFound('Request not found.');
 *   throw AppError.forbidden('Forbidden.');
 */

export class AppError extends Error {
  /**
   * @param {number} statusCode  - HTTP status code (e.g. 400, 401, 403, 404, 409, 500)
   * @param {string} errorCode   - Machine-readable code matching API_CONTRACT.md error codes
   * @param {string} message     - Human-readable description sent to the client
   * @param {Array|null} details - Optional array of { field, message } objects (validation only)
   */
  constructor(statusCode, errorCode, message, details = null) {
    super(message);
    this.name = 'AppError';
    this.statusCode = statusCode;
    this.errorCode = errorCode;
    this.details = details;
  }

  static badRequest(message, errorCode = 'BAD_REQUEST', details = null) {
    return new AppError(400, errorCode, message, details);
  }

  static validation(details, message = 'One or more fields failed validation.') {
    return new AppError(400, 'VALIDATION_ERROR', message, details);
  }

  static unauthorized(message = 'Authentication required.', errorCode = 'MISSING_TOKEN') {
    return new AppError(401, errorCode, message);
  }

  static forbidden(message = 'You do not have permission to perform this action.') {
    return new AppError(403, 'FORBIDDEN', message);
  }

  static notFound(message = 'Resource not found.') {
    return new AppError(404, 'NOT_FOUND', message);
  }

  static conflict(message = 'Resource already exists.') {
    return new AppError(409, 'CONFLICT', message);
  }
}
