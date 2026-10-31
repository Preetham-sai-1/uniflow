/**
 * scripts/create-admin.js
 *
 * Secure One-Time Administrator Provisioning Script
 *
 * Provisions the initial institutional administrator account directly into
 * MongoDB with role: 'admin' and a bcrypt-hashed password.
 *
 * ⚠️  SECURITY RULES:
 *  - Enforces strict database isolation: ONLY runs against 'uniflow_prod'.
 *  - Administrator email and password must be supplied explicitly at execution time.
 *  - Passwords are NEVER hardcoded or committed to version control.
 *  - Passwords are NEVER printed in console output or log files.
 *  - Passwords are encrypted using bcrypt (configured salt rounds).
 *  - Safe execution: verifies institution exists, checks for existing accounts,
 *    and never overwrites or resets an existing user's password without confirmation.
 *
 * Execution Methods:
 *
 * 1. Environment variables (e.g. in CI/CD or scripted container execution):
 *    ADMIN_NAME="Dr. Sarah Johnson" \
 *    ADMIN_EMAIL="admin@uniflow.edu" \
 *    ADMIN_PASSWORD="YourStrongSecurePassword123!" \
 *    node scripts/create-admin.js
 *
 * 2. Interactive CLI prompt:
 *    npm run create-admin
 *    (Prompts securely for name, email, and password if not in env)
 */

import 'dotenv/config';
import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import readline from 'readline';
import path from 'path';
import { fileURLToPath } from 'url';
import { assertProductionDatabase, REQUIRED_PROD_DB_NAME } from './lib/db-guard.js';

import User, { USER_ROLES } from '../src/models/User.js';
import Institution from '../src/models/Institution.js';
import Department from '../src/models/Department.js';

const SALT_ROUNDS = parseInt(process.env.BCRYPT_SALT_ROUNDS ?? '10', 10);

// ─── Interactive prompt helper ────────────────────────────────────────────────
function prompt(question, isPassword = false) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  return new Promise((resolve) => {
    if (isPassword) {
      process.stdout.write(question);
      let pass = '';
      process.stdin.setRawMode?.(true);
      process.stdin.resume?.();

      const onData = (char) => {
        const c = char.toString();
        if (c === '\n' || c === '\r' || c === '\u0004') {
          process.stdin.setRawMode?.(false);
          process.stdin.pause?.();
          process.stdin.removeListener('data', onData);
          process.stdout.write('\n');
          rl.close();
          resolve(pass);
        } else if (c === '\u0008' || c === '\x7f') {
          if (pass.length > 0) {
            pass = pass.slice(0, -1);
            process.stdout.write('\b \b');
          }
        } else if (c === '\u0003') {
          process.exit(1);
        } else {
          pass += c;
          process.stdout.write('*');
        }
      };

      process.stdin.on('data', onData);
    } else {
      rl.question(question, (answer) => {
        rl.close();
        resolve(answer.trim());
      });
    }
  });
}

/**
 * Provisions an administrator account in production with database isolation enforcement.
 * @param {object} [options]
 * @param {string} [options.mongoUri]
 * @param {string} [options.name]
 * @param {string} [options.email]
 * @param {string} [options.password]
 * @returns {Promise<object>}
 */
export async function createAdmin(options = {}) {
  const MONGO_URI = options.mongoUri || process.env.MONGO_URI;

  if (!MONGO_URI) {
    throw new Error('MONGO_URI is not set. Please provide MONGO_URI in your environment.');
  }

  console.log('\n👤  UniFlow — Administrator Account Provisioning\n');
  console.log('━'.repeat(55));

  // Retrieve inputs from options, environment, or CLI flags, falling back to prompt
  let name = options.name || process.env.ADMIN_NAME;
  let email = options.email || process.env.ADMIN_EMAIL;
  let password = options.password || process.env.ADMIN_PASSWORD;

  // Check command line arguments (--name=..., --email=..., --password=...)
  for (const arg of process.argv.slice(2)) {
    if (arg.startsWith('--name=')) name = arg.slice(7);
    if (arg.startsWith('--email=')) email = arg.slice(8);
    if (arg.startsWith('--password=')) password = arg.slice(11);
  }

  // Interactive prompts if values are not provided in environment
  if (!name && process.stdin.isTTY) {
    name = await prompt('  Enter Administrator Full Name: ');
  }
  if (!email && process.stdin.isTTY) {
    email = await prompt('  Enter Administrator Email: ');
  }
  if (!password && process.stdin.isTTY) {
    password = await prompt('  Enter Administrator Password (min 8 chars): ', true);
  }

  // Fallback defaults or validations
  name = (name || '').trim();
  email = (email || '').trim().toLowerCase();
  password = (password || '').trim();

  // Validate inputs
  if (!name || name.length < 2) {
    throw new Error('Invalid name: Administrator name must be at least 2 characters.');
  }

  const emailRegex = /^\S+@\S+\.\S+$/;
  if (!email || !emailRegex.test(email)) {
    throw new Error('Invalid email: Please supply a valid email address.');
  }

  if (!password || password.length < 8) {
    throw new Error('Weak password: Administrator password must be at least 8 characters long.');
  }

  // ── Connect ─────────────────────────────────────────────────────────────────
  await mongoose.connect(MONGO_URI, { serverSelectionTimeoutMS: 10000 });
  const dbName = mongoose.connection.db?.databaseName;

  // ── Mandatory Database Isolation Guard ─────────────────────────────────────
  // Enforce that administrator provisioning ONLY occurs in 'uniflow_prod'
  try {
    assertProductionDatabase(mongoose.connection, REQUIRED_PROD_DB_NAME);
  } catch (guardErr) {
    await mongoose.disconnect();
    throw guardErr;
  }

  console.log(`\n✅  Connected to MongoDB database: [ ${dbName} ] (Verified Production Database)\n`);

  // ── Resolve Institution ─────────────────────────────────────────────────────
  const institution = await Institution.findOne({ isActive: true });
  if (!institution) {
    await mongoose.disconnect();
    throw new Error(
      'No active institution found in the target database. Run `npm run init:prod` first.'
    );
  }

  // ── Resolve Department (Optional but assigned to Administration if present) ─
  const adminDept = await Department.findOne({ code: 'ADMIN', institution: institution._id });

  // ── Check if user with email already exists ─────────────────────────────────
  const existingUser = await User.findOne({ email });
  if (existingUser) {
    await mongoose.disconnect();
    throw new Error(
      `A user account with email "${email}" already exists. Aborting to prevent overwrite.`
    );
  }

  // ── Hash password with bcrypt ───────────────────────────────────────────────
  const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

  // ── Create Administrator ────────────────────────────────────────────────────
  const admin = await User.create({
    name,
    email,
    passwordHash,
    role: USER_ROLES.ADMIN,
    institution: institution._id,
    department: adminDept?._id ?? null,
    isActive: true,
  });

  console.log('━'.repeat(55));
  console.log('✅  Administrator account successfully created!\n');
  console.log(`  User ID     : ${admin._id}`);
  console.log(`  Name        : ${admin.name}`);
  console.log(`  Email       : ${admin.email}`);
  console.log(`  Role        : ${admin.role}`);
  console.log(`  Institution : ${institution.name} (${institution.code})`);
  console.log(`  Department  : ${adminDept ? adminDept.name : 'None'}`);
  console.log(`  Status      : Active`);
  console.log('\n  ⚠️  Password has been securely hashed with bcrypt. Never share administrator credentials.\n');

  return {
    adminId: admin._id,
    email: admin.email,
    institution: institution.name,
  };
}

// ─── Direct CLI Execution Handler ─────────────────────────────────────────────
const isDirectExecution =
  process.argv[1] && path.resolve(process.argv[1]) === path.resolve(fileURLToPath(import.meta.url));

if (isDirectExecution) {
  createAdmin()
    .then(() => mongoose.disconnect())
    .catch(async (err) => {
      if (err.code === 'DATABASE_ISOLATION_VIOLATION') {
        console.error('\n🛑  DATABASE ISOLATION ERROR:');
        console.error(`    ${err.message}`);
        console.error(`    Actual connected database: [ ${err.actualDb ?? 'unknown'} ]`);
        console.error('    Aborting immediately. Zero user accounts created or modified.\n');
        console.error('    To provision the administrator in production, explicitly provide the production URI:');
        console.error('    MONGO_URI="mongodb+srv://.../uniflow_prod?..." npm run create-admin\n');
      } else {
        console.error('\n❌  Administrator provisioning failed:', err.message);
      }
      await mongoose.disconnect().catch(() => {});
      process.exit(1);
    });
}
