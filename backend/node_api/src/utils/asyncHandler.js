/**
 * src/utils/asyncHandler.js
 *
 * Wraps an async Express route handler so that any rejected promise is
 * forwarded to next(err) rather than causing an unhandled rejection.
 *
 * Usage:
 *   router.get('/path', asyncHandler(async (req, res) => { ... }));
 */

/**
 * @param {Function} fn - An async Express handler: (req, res, next) => Promise
 * @returns {Function}  - Express middleware that catches errors and calls next(err)
 */
export const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};
