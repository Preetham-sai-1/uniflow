/**
 * src/config/env.js
 *
 * Validates required environment variables using Zod at startup.
 * If validation fails the process exits with a clear error — the server
 * must not start with a broken configuration.
 *
 * Import this module before anything else that reads process.env.
 */

import 'dotenv/config'; // Load .env (no-op if file does not exist)
import { z } from 'zod';

const envSchema = z.object({
  PORT: z.coerce.number().int().positive().default(3001),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),

  // Database — required; must be a non-empty string
  MONGO_URI: z.string().min(1, 'MONGO_URI is required. Set it in your .env file.'),

  // JWT
  JWT_SECRET: z
    .string()
    .min(32, 'JWT_SECRET must be at least 32 characters. Generate one with: openssl rand -hex 64'),
  JWT_EXPIRES_IN: z.string().default('7d'),

  // CORS — the React dev server origin
  FRONTEND_URL: z.string().url().default('http://localhost:5173'),

  // CORS — the Flutter web dev origin
  FLUTTER_WEB_URL: z.string().url().default('http://localhost:7357'),

  // Bcrypt cost — integer; tests use 1 for speed
  BCRYPT_SALT_ROUNDS: z.coerce.number().int().min(1).max(31).default(10),
});

const result = envSchema.safeParse(process.env);

if (!result.success) {
  const fieldErrors = result.error.flatten().fieldErrors;
  console.error('\n❌  Environment configuration error — cannot start the server.\n');
  for (const [key, messages] of Object.entries(fieldErrors)) {
    console.error(`  ${key}: ${messages.join(', ')}`);
  }
  console.error('\n  Copy backend/node_api/.env.example to backend/node_api/.env and fill in the values.\n');
  process.exit(1);
}

export const env = Object.freeze(result.data);
