/**
 * scripts/create-admin.js
 *
 * Secure One-Time Administrator Provisioning Script
 *
 * Provisions the initial institutional administrator account directly into
 * MongoDB with role: 'admin' and a bcrypt-hashed password.
 *
 * ⚠️  SECURITY RULES:
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

import User, { USER_ROLES } from '../src/models/User.js';
import Institution from '../src/models/Institution.js';
import Department from '../src/models/Department.js';

const MONGO_URI = process.env.MONGO_URI;
const SALT_ROUNDS = parseInt(process.env.BCRYPT_SALT_ROUNDS ?? '10', 10);

if (!MONGO_URI) {
  console.error('❌  MONGO_URI is not set. Please provide MONGO_URI in your environment.');
  process.exit(1);
}

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

// ─── Main Provisioning Logic ──────────────────────────────────────────────────
async function createAdmin() {
  console.log('\n👤  UniFlow — Administrator Account Provisioning\n');
  console.log('━'.repeat(55));

  // Retrieve inputs from environment or CLI flags, falling back to prompt
  let name = process.env.ADMIN_NAME;
  let email = process.env.ADMIN_EMAIL;
  let password = process.env.ADMIN_PASSWORD;

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
    console.error('❌  Invalid name: Administrator name must be at least 2 characters.');
    process.exit(1);
  }

  const emailRegex = /^\S+@\S+\.\S+$/;
  if (!email || !emailRegex.test(email)) {
    console.error('❌  Invalid email: Please supply a valid email address.');
    process.exit(1);
  }

  if (!password || password.length < 8) {
    console.error('❌  Weak password: Administrator password must be at least 8 characters long.');
    process.exit(1);
  }

  // ── Connect ─────────────────────────────────────────────────────────────────
  await mongoose.connect(MONGO_URI, { serverSelectionTimeoutMS: 10000 });
  const dbName = mongoose.connection.db.databaseName;
  console.log(`\n✅  Connected to MongoDB database: [ ${dbName} ]\n`);

  // ── Resolve Institution ─────────────────────────────────────────────────────
  const institution = await Institution.findOne({ isActive: true });
  if (!institution) {
    console.error('❌  No active institution found in the target database.');
    console.error('    Please run the production database initialization first:');
    console.error('    npm run init:prod\n');
    await mongoose.disconnect();
    process.exit(1);
  }

  // ── Resolve Department (Optional but assigned to Administration if present) ─
  const adminDept = await Department.findOne({ code: 'ADMIN', institution: institution._id });

  // ── Check if user with email already exists ─────────────────────────────────
  const existingUser = await User.findOne({ email });
  if (existingUser) {
    console.error(`❌  A user account with email "${email}" already exists.`);
    console.error(`    Account Role: ${existingUser.role}`);
    console.error(`    User ID     : ${existingUser._id}`);
    console.error('    Aborting provisioning to prevent unintended overwrite.');
    await mongoose.disconnect();
    process.exit(1);
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

  await mongoose.disconnect();
}

createAdmin().catch(async (err) => {
  console.error('\n❌  Administrator provisioning failed:', err.message);
  await mongoose.disconnect();
  process.exit(1);
});
