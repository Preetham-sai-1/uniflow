/**
 * src/config/database.js
 *
 * Manages the Mongoose connection lifecycle.
 *
 * - connectDB()    : connect; exits process on failure.
 * - disconnectDB() : gracefully close the connection (used on shutdown / in tests).
 */

import mongoose from 'mongoose';
import { env } from './env.js';

/**
 * Connect to MongoDB using the URI from environment configuration.
 * Logs a clear message on success or failure.
 * Exits the process if the connection cannot be established — the API
 * must not run without a database.
 */
export async function connectDB() {
  try {
    const connection = await mongoose.connect(env.MONGO_URI, {
      // Mongoose 8 removed the need for most option flags; these are still useful:
      serverSelectionTimeoutMS: 5000, // fail fast if Atlas / mongod is unreachable
    });

    const host = connection.connection.host;
    console.log(`✅  MongoDB connected: ${host}`);
  } catch (error) {
    console.error('❌  MongoDB connection failed:', error.message);
    console.error('    Check that MONGO_URI is correct and the cluster is reachable.');
    process.exit(1);
  }
}

/**
 * Gracefully close the Mongoose connection.
 * Called during server shutdown so that in-flight operations can complete.
 */
export async function disconnectDB() {
  await mongoose.connection.close();
  console.log('MongoDB connection closed.');
}
