/**
 * src/server.js
 *
 * Application entry point.
 * Responsibilities:
 *  1. Connect to MongoDB via Mongoose.
 *  2. Start the HTTP server on the configured port.
 *  3. Register SIGTERM / SIGINT handlers for graceful shutdown.
 *
 * app.js and server.js are intentionally separate so that tests can
 * import app.js without starting the server or connecting to the database.
 */

import app from './app.js';
import { env } from './config/env.js';
import { connectDB, disconnectDB } from './config/database.js';

// ── Start ─────────────────────────────────────────────────────────────────────

async function start() {
  // Connect to MongoDB before accepting traffic
  await connectDB();

  const server = app.listen(env.PORT, () => {
    console.log(`🚀  UniFlow API running on http://localhost:${env.PORT}`);
    console.log(`    Environment : ${env.NODE_ENV}`);
    console.log(`    CORS origin : ${env.FRONTEND_URL}`);
  });

  // ── Graceful shutdown ────────────────────────────────────────────────────────

  async function shutdown(signal) {
    console.log(`\n${signal} received — shutting down gracefully...`);

    // Stop accepting new connections
    server.close(async () => {
      console.log('HTTP server closed.');
      await disconnectDB();
      console.log('Shutdown complete.');
      process.exit(0);
    });

    // Force exit if shutdown takes too long
    setTimeout(() => {
      console.error('Forced exit after timeout.');
      process.exit(1);
    }, 10_000);
  }

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));

  // Catch unhandled promise rejections — log and exit so the process
  // restarts cleanly (under a process manager like PM2 or Railway).
  process.on('unhandledRejection', (reason) => {
    console.error('Unhandled promise rejection:', reason);
    shutdown('unhandledRejection');
  });
}

start();
