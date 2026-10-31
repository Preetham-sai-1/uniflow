/**
 * src/app.js
 *
 * Creates and configures the Express application.
 * Does NOT connect to the database — that happens in server.js.
 * This separation allows tests to import the app without needing a live DB.
 *
 * Middleware order (matters for Express):
 *   1. Security headers (helmet)
 *   2. CORS
 *   3. Request logging (development only)
 *   4. Body parsers
 *   5. API routes
 *   6. 404 handler (after all routes)
 *   7. Global error handler (must be last, 4-argument signature)
 */

import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { env } from './config/env.js';
import router from './routes/index.js';
import { notFoundHandler, errorHandler } from './middleware/error.middleware.js';

const app = express();

// ── 1. Security headers ───────────────────────────────────────────────────────
app.use(helmet());

// ── 2. CORS — only allow the configured frontend origin ───────────────────────
app.use(
  cors({
    origin: env.FRONTEND_URL,
    methods: ['GET', 'POST', 'PATCH', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: false, // No cookies in MVP; JWT is in the Authorization header
  })
);

// ── 3. Request logging (development only) ─────────────────────────────────────
if (env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// ── 4. Body parsers ───────────────────────────────────────────────────────────
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: false }));

// ── 5. API routes ─────────────────────────────────────────────────────────────
app.use('/api', router);

// ── 6. 404 — catch unmatched /api/* routes before the error handler ───────────
app.use('/api/*splat', notFoundHandler);

// Catch requests to non-/api paths (e.g. root)
app.use((_req, res) => {
  res.status(404).json({
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: 'This is the UniFlow API. All endpoints are under /api/.',
    },
  });
});

// ── 7. Global error handler (must be registered last) ────────────────────────
app.use(errorHandler);

export default app;
