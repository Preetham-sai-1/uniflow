/**
 * scripts/seed.js
 *
 * Idempotent seed script — populates the database with demo data for local
 * development and demonstration purposes.
 *
 * ⚠️  DEMO ACCOUNTS ONLY — never use these credentials in production.
 *
 * Run with:
 *   npm run seed
 *
 * Requirements:
 *  - MONGO_URI and BCRYPT_SALT_ROUNDS must be set in .env
 *  - Safe to run multiple times; uses upserts throughout.
 *  - Does NOT delete any user data — only creates or updates demo records.
 *
 * Seeds:
 *  1. Institution  — UniFlow Demo University
 *  2. Departments  — Administration, Computer Science, Security, Facilities
 *  3. Users        — one student, one staff, one admin
 *  4. Services     — Bonafide Certificate, ID Card Replacement, Equipment Booking
 *  5. Workflows    — one per service with correct step definitions
 *  6. Service↔Workflow links — updated after workflows are created
 */

import 'dotenv/config';
import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

// ─── Models ───────────────────────────────────────────────────────────────────
// Import order matters for Mongoose model registration
import Institution from '../src/models/Institution.js';
import Department from '../src/models/Department.js';
import User from '../src/models/User.js';
import Service from '../src/models/Service.js';
import Workflow from '../src/models/Workflow.js';

// ─── Config ───────────────────────────────────────────────────────────────────

const MONGO_URI = process.env.MONGO_URI;
const SALT_ROUNDS = parseInt(process.env.BCRYPT_SALT_ROUNDS ?? '10', 10);

if (!MONGO_URI) {
  console.error('❌  MONGO_URI is not set. Copy .env.example to .env and fill it in.');
  process.exit(1);
}

// ─── Demo account credentials ─────────────────────────────────────────────────

const DEMO_PASSWORD = 'Demo@1234'; // ⚠️ Development only

const DEMO_ACCOUNTS = {
  student: { name: 'Arjun Sharma', email: 'student@uniflow.edu', role: 'student', studentId: 'CS2021001' },
  staff: { name: 'Priya Nair', email: 'staff@uniflow.edu', role: 'staff' },
  admin: { name: 'Dr. Ramesh Kumar', email: 'admin@uniflow.edu', role: 'admin' },
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Upsert a document by a filter — update if found, create if not.
 * Returns the saved document.
 */
async function upsert(Model, filter, data) {
  return Model.findOneAndUpdate(filter, { $set: data }, { upsert: true, new: true, setDefaultsOnInsert: true });
}

function log(icon, message) {
  console.log(`  ${icon}  ${message}`);
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function seed() {
  console.log('\n🌱  UniFlow Seed Script\n');
  console.log('━'.repeat(50));

  // ── Connect ───────────────────────────────────────────────────────────────────
  await mongoose.connect(MONGO_URI, { serverSelectionTimeoutMS: 8000 });
  console.log(`\n✅  Connected to MongoDB\n`);

  // ── 1. Institution ─────────────────────────────────────────────────────────────
  console.log('📍  Institution');
  const institution = await upsert(
    Institution,
    { slug: 'uniflow-demo-university' },
    {
      name: 'UniFlow Demo University',
      slug: 'uniflow-demo-university',
      code: 'UDU',
      isActive: true,
    }
  );
  log('✓', `Institution: ${institution.name}  (${institution._id})`);

  // ── 2. Departments ─────────────────────────────────────────────────────────────
  console.log('\n🏢  Departments');

  const departmentDefs = [
    { name: 'Administration', code: 'ADMIN' },
    { name: 'Computer Science', code: 'CS' },
    { name: 'Security', code: 'SEC' },
    { name: 'Facilities', code: 'FAC' },
  ];

  const departments = {};
  for (const def of departmentDefs) {
    const dept = await upsert(
      Department,
      { code: def.code, institution: institution._id },
      { name: def.name, code: def.code, institution: institution._id, isActive: true }
    );
    departments[def.code] = dept;
    log('✓', `${dept.name}  (${dept._id})`);
  }

  // ── 3. Demo users ──────────────────────────────────────────────────────────────
  console.log('\n👤  Demo Users');
  console.log('    ⚠️   These accounts are for local development only.\n');

  const passwordHash = await bcrypt.hash(DEMO_PASSWORD, SALT_ROUNDS);

  // Student — no department
  const studentData = DEMO_ACCOUNTS.student;
  const student = await upsert(
    User,
    { email: studentData.email },
    {
      name: studentData.name,
      email: studentData.email,
      passwordHash,
      role: studentData.role,
      institution: institution._id,
      department: null,
      studentId: studentData.studentId,
      isActive: true,
    }
  );
  log('✓', `Student  : ${student.email}  /  Password: ${DEMO_PASSWORD}`);

  // Staff — belongs to Computer Science dept
  const staffData = DEMO_ACCOUNTS.staff;
  const staff = await upsert(
    User,
    { email: staffData.email },
    {
      name: staffData.name,
      email: staffData.email,
      passwordHash,
      role: staffData.role,
      institution: institution._id,
      department: departments['CS']._id,
      isActive: true,
    }
  );
  log('✓', `Staff    : ${staff.email}  /  Password: ${DEMO_PASSWORD}`);

  // Admin — belongs to Administration dept
  const adminData = DEMO_ACCOUNTS.admin;
  const admin = await upsert(
    User,
    { email: adminData.email },
    {
      name: adminData.name,
      email: adminData.email,
      passwordHash,
      role: adminData.role,
      institution: institution._id,
      department: departments['ADMIN']._id,
      isActive: true,
    }
  );
  log('✓', `Admin    : ${admin.email}  /  Password: ${DEMO_PASSWORD}`);

  // ── 4. Services (without workflow link — added after workflows are created) ────
  console.log('\n🛎️   Services');

  const bonafideService = await upsert(
    Service,
    { slug: 'bonafide-certificate' },
    {
      name: 'Bonafide Certificate',
      slug: 'bonafide-certificate',
      description:
        'An official letter from the institution confirming your current enrolment status. Commonly required for bank accounts, scholarship applications, and visa processing.',
      category: 'Academic',
      requiredDocuments: ['Student ID card', 'Previous bonafide certificate (if any)'],
      responsibleDepartment: departments['ADMIN']._id,
      institution: institution._id,
      formFields: [
        {
          name: 'purpose',
          label: 'Purpose of Certificate',
          type: 'select',
          options: ['Scholarship', 'Bank Account', 'Visa Application', 'Other'],
          required: true,
        },
        {
          name: 'copies',
          label: 'Number of Copies Required',
          type: 'number',
          required: true,
          placeholder: '1',
        },
        {
          name: 'additionalDetails',
          label: 'Additional Details',
          type: 'textarea',
          required: false,
          placeholder: 'e.g. Please include CGPA on the certificate.',
        },
      ],
      estimatedDays: 3,
      isActive: true,
    }
  );
  log('✓', `Bonafide Certificate  (${bonafideService._id})`);

  const idCardService = await upsert(
    Service,
    { slug: 'id-card-replacement' },
    {
      name: 'ID Card Replacement',
      slug: 'id-card-replacement',
      description:
        'Request a replacement for a lost, stolen, or damaged institutional ID card. A nominal replacement fee applies (simulated in this demo).',
      category: 'Identity',
      requiredDocuments: [
        'Police complaint reference number (if stolen)',
        'Photograph (passport size)',
      ],
      responsibleDepartment: departments['SEC']._id,
      institution: institution._id,
      formFields: [
        {
          name: 'reason',
          label: 'Reason for Replacement',
          type: 'select',
          options: ['Lost', 'Stolen', 'Damaged'],
          required: true,
        },
        {
          name: 'policeComplaintRef',
          label: 'Police Complaint Reference (if stolen)',
          type: 'text',
          required: false,
          placeholder: 'e.g. FIR/2025/001234',
        },
        {
          name: 'contactNumber',
          label: 'Contact Number for Delivery Confirmation',
          type: 'text',
          required: true,
          placeholder: '+91 98765 43210',
        },
      ],
      estimatedDays: 5,
      isActive: true,
    }
  );
  log('✓', `ID Card Replacement  (${idCardService._id})`);

  const equipmentService = await upsert(
    Service,
    { slug: 'equipment-booking' },
    {
      name: 'Equipment Booking',
      slug: 'equipment-booking',
      description:
        'Borrow institutional equipment (cameras, projectors, lab instruments, etc.) for a specified date and time slot.',
      category: 'Resources',
      requiredDocuments: [],
      responsibleDepartment: departments['FAC']._id,
      institution: institution._id,
      formFields: [
        {
          name: 'equipmentName',
          label: 'Equipment Required',
          type: 'text',
          required: true,
          placeholder: 'e.g. Canon EOS R10 Camera',
        },
        {
          name: 'purpose',
          label: 'Purpose / Intended Use',
          type: 'textarea',
          required: true,
          placeholder: 'Describe why you need this equipment.',
        },
        {
          name: 'startTime',
          label: 'Start Date & Time',
          type: 'datetime',
          required: true,
        },
        {
          name: 'endTime',
          label: 'End Date & Time',
          type: 'datetime',
          required: true,
        },
      ],
      estimatedDays: 1,
      isActive: true,
    }
  );
  log('✓', `Equipment Booking  (${equipmentService._id})`);

  // ── 5. Workflows ───────────────────────────────────────────────────────────────
  console.log('\n🔄  Workflows');

  // ── Workflow 1: Bonafide Certificate ──────────────────────────────────────────
  const bonafideWorkflow = await upsert(
    Workflow,
    { name: 'Bonafide Certificate Workflow', institution: institution._id },
    {
      name: 'Bonafide Certificate Workflow',
      service: bonafideService._id,
      institution: institution._id,
      version: 1,
      isActive: true,
      steps: [
        {
          stepIndex: 0,
          name: 'Department Verification',
          description: 'Department secretary verifies the student\'s current enrolment and academic standing.',
          assignedRole: 'staff',
          department: departments['CS']._id,
          isPaymentStep: false,
          pendingStatus: 'DEPARTMENT_VERIFICATION_PENDING',
          requiresComment: false,
        },
        {
          stepIndex: 1,
          name: 'Administrative Approval',
          description: 'Administrator grants final approval and initiates certificate preparation.',
          assignedRole: 'admin',
          department: departments['ADMIN']._id,
          isPaymentStep: false,
          pendingStatus: 'ADMIN_APPROVAL_PENDING',
          requiresComment: false,
        },
      ],
    }
  );
  log('✓', `Bonafide Certificate Workflow  (${bonafideWorkflow._id})`);

  // ── Workflow 2: ID Card Replacement ───────────────────────────────────────────
  const idCardWorkflow = await upsert(
    Workflow,
    { name: 'ID Card Replacement Workflow', institution: institution._id },
    {
      name: 'ID Card Replacement Workflow',
      service: idCardService._id,
      institution: institution._id,
      version: 1,
      isActive: true,
      steps: [
        {
          stepIndex: 0,
          name: 'Security Review',
          description: 'Security desk verifies the student\'s identity and confirms no account flags.',
          assignedRole: 'staff',
          department: departments['SEC']._id,
          isPaymentStep: false,
          pendingStatus: 'SECURITY_REVIEW_PENDING',
          requiresComment: false,
        },
        {
          stepIndex: 1,
          name: 'Payment Confirmation',
          description: 'Student completes the replacement card fee payment (simulated).',
          assignedRole: 'student',
          department: null,
          isPaymentStep: true,
          pendingStatus: 'PAYMENT_REQUIRED',
          requiresComment: false,
        },
        {
          stepIndex: 2,
          name: 'Administrative Approval',
          description: 'Administrator approves card printing after security clearance and payment.',
          assignedRole: 'admin',
          department: departments['ADMIN']._id,
          isPaymentStep: false,
          pendingStatus: 'ADMIN_APPROVAL_PENDING',
          requiresComment: false,
        },
      ],
    }
  );
  log('✓', `ID Card Replacement Workflow  (${idCardWorkflow._id})`);

  // ── Workflow 3: Equipment Booking ─────────────────────────────────────────────
  const equipmentWorkflow = await upsert(
    Workflow,
    { name: 'Equipment Booking Workflow', institution: institution._id },
    {
      name: 'Equipment Booking Workflow',
      service: equipmentService._id,
      institution: institution._id,
      version: 1,
      isActive: true,
      steps: [
        {
          stepIndex: 0,
          name: 'Staff Review',
          description: 'Equipment custodian checks availability and approves or rejects the booking.',
          assignedRole: 'staff',
          department: departments['FAC']._id,
          isPaymentStep: false,
          pendingStatus: 'STAFF_REVIEW_PENDING',
          requiresComment: false,
        },
      ],
    }
  );
  log('✓', `Equipment Booking Workflow  (${equipmentWorkflow._id})`);

  // ── 6. Link workflows back to services ────────────────────────────────────────
  console.log('\n🔗  Linking workflows to services');

  await Service.findByIdAndUpdate(bonafideService._id, { workflow: bonafideWorkflow._id });
  log('✓', 'Bonafide Certificate ↔ Bonafide Certificate Workflow');

  await Service.findByIdAndUpdate(idCardService._id, { workflow: idCardWorkflow._id });
  log('✓', 'ID Card Replacement ↔ ID Card Replacement Workflow');

  await Service.findByIdAndUpdate(equipmentService._id, { workflow: equipmentWorkflow._id });
  log('✓', 'Equipment Booking ↔ Equipment Booking Workflow');

  // ── Done ──────────────────────────────────────────────────────────────────────
  console.log('\n' + '━'.repeat(50));
  console.log('\n✅  Seed complete.\n');
  console.log('   Demo credentials (development only):');
  console.log(`     Student : ${DEMO_ACCOUNTS.student.email}  /  ${DEMO_PASSWORD}`);
  console.log(`     Staff   : ${DEMO_ACCOUNTS.staff.email}  /  ${DEMO_PASSWORD}`);
  console.log(`     Admin   : ${DEMO_ACCOUNTS.admin.email}  /  ${DEMO_PASSWORD}\n`);
}

seed()
  .then(() => mongoose.disconnect())
  .catch((err) => {
    console.error('\n❌  Seed failed:', err.message);
    mongoose.disconnect();
    process.exit(1);
  });
