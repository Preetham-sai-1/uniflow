/**
 * src/controllers/health.controller.js
 *
 * GET /api/health — server liveness check.
 *
 * This endpoint is intentionally simple and does NOT check the database
 * connection. It confirms that the Node.js process is alive and the Express
 * application is responding to requests.
 *
 * A database connectivity check (readiness probe) can be added in a future
 * phase if needed for deployment health monitoring.
 */

export function getHealth(_req, res) {
  res.status(200).json({
    success: true,
    data: {
      status: 'operational',
      service: 'uniflow-api',
      version: '1.0.0',
      environment: process.env.NODE_ENV ?? 'development',
      timestamp: new Date().toISOString(),
    },
  });
}
