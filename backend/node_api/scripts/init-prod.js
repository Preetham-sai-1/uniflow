/**
 * scripts/init-prod.js
 *
 * Production Database Initialization Script
 *
 * Populates the production MongoDB database with essential organizational
 * configuration, departments, service catalogue entries, and workflow definitions.
 *
 * ⚠️  PRODUCTION SAFE:
 *  - Enforces strict database isolation: ONLY runs against 'uniflow_prod'.
 *  - Idempotent: checks for existing records before inserting.
 *  - NEVER overwrites or alters existing production records.
 *  - NEVER creates demo student, demo staff, or dummy accounts.
 *  - NEVER generates mock requests, transactions, or notifications.
 *  - NEVER logs passwords, credentials, or full connection strings.
 *
 * Usage:
 *   node scripts/init-prod.js
 *   npm run init:prod
 *
 * Requirements:
 *   - MONGO_URI must point specifically to 'uniflow_prod'
 */

import 'dotenv/config';
import mongoose from 'mongoose';
import path from 'path';
import { fileURLToPath } from 'url';
import { assertProductionDatabase, REQUIRED_PROD_DB_NAME } from './lib/db-guard.js';

// ─── Models ───────────────────────────────────────────────────────────────────
import Institution from '../src/models/Institution.js';
import Department from '../src/models/Department.js';
import Service from '../src/models/Service.js';
import Workflow from '../src/models/Workflow.js';
import User from '../src/models/User.js';
import Request from '../src/models/Request.js';
import Notification from '../src/models/Notification.js';

function log(icon, message) {
  console.log(`  ${icon}  ${message}`);
}

/**
 * Executes production database initialization with database isolation.
 * @param {string} [uriOverride] - Optional MONGO_URI override.
 * @returns {Promise<object>} Summary of initialized items.
 */
export async function initProd(uriOverride = null) {
  const MONGO_URI = uriOverride || process.env.MONGO_URI;

  if (!MONGO_URI) {
    throw new Error('MONGO_URI is not set. Please provide MONGO_URI in your environment.');
  }

  console.log('\n🏛️  UniFlow — Production Database Initialization\n');
  console.log('━'.repeat(55));

  // ── 0. Connect ─────────────────────────────────────────────────────────────
  await mongoose.connect(MONGO_URI, { serverSelectionTimeoutMS: 10000 });
  const dbName = mongoose.connection.db?.databaseName;

  // ── Mandatory Database Isolation Guard ─────────────────────────────────────
  // Enforce that this script NEVER runs against the development database ('uniflow')
  // or any other non-production database.
  try {
    assertProductionDatabase(mongoose.connection, REQUIRED_PROD_DB_NAME);
  } catch (guardErr) {
    await mongoose.disconnect();
    throw guardErr;
  }

  console.log(`\n✅  Connected to MongoDB database: [ ${dbName} ] (Verified Production Database)\n`);

  // ── 1. Institution ─────────────────────────────────────────────────────────
  console.log('📍  1. Institution Configuration');
  let institution = await Institution.findOne({ isActive: true });

  if (!institution) {
    const instName = process.env.INSTITUTION_NAME || 'UniFlow Campus';
    const instSlug = process.env.INSTITUTION_SLUG || 'uniflow-campus';
    const instCode = process.env.INSTITUTION_CODE || 'UFC';

    institution = await Institution.create({
      name: instName,
      slug: instSlug,
      code: instCode,
      isActive: true,
    });
    log('✓', `Created Institution: ${institution.name} (${institution.code}) [ID: ${institution._id}]`);
  } else {
    log('ℹ', `Existing Institution preserved: ${institution.name} (${institution.code}) [ID: ${institution._id}]`);
  }

  // ── 2. Departments ─────────────────────────────────────────────────────────
  console.log('\n🏢  2. Institutional Departments');

  const departmentDefs = [
    { name: 'Administration', code: 'ADMIN' },
    { name: 'Computer Science', code: 'CS' },
    { name: 'Security', code: 'SEC' },
    { name: 'Facilities', code: 'FAC' },
  ];

  const departments = {};
  for (const def of departmentDefs) {
    let dept = await Department.findOne({ code: def.code, institution: institution._id });
    if (!dept) {
      dept = await Department.create({
        name: def.name,
        code: def.code,
        institution: institution._id,
        isActive: true,
      });
      log('✓', `Created Department: ${dept.name} (${dept.code}) [ID: ${dept._id}]`);
    } else {
      log('ℹ', `Existing Department preserved: ${dept.name} (${dept.code}) [ID: ${dept._id}]`);
    }
    departments[def.code] = dept;
  }

  // ── 3. Services ────────────────────────────────────────────────────────────
  console.log('\n🛎️   3. Campus Services Catalogue');

  // Service 1: Bonafide Certificate
  let bonafideService = await Service.findOne({ slug: 'bonafide-certificate' });
  if (!bonafideService) {
    bonafideService = await Service.create({
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
    });
    log('✓', `Created Service: Bonafide Certificate [ID: ${bonafideService._id}]`);
  } else {
    log('ℹ', `Existing Service preserved: Bonafide Certificate [ID: ${bonafideService._id}]`);
  }

  // Service 2: ID Card Replacement
  let idCardService = await Service.findOne({ slug: 'id-card-replacement' });
  if (!idCardService) {
    idCardService = await Service.create({
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
    });
    log('✓', `Created Service: ID Card Replacement [ID: ${idCardService._id}]`);
  } else {
    log('ℹ', `Existing Service preserved: ID Card Replacement [ID: ${idCardService._id}]`);
  }

  // Service 3: Equipment Booking
  let equipmentService = await Service.findOne({ slug: 'equipment-booking' });
  if (!equipmentService) {
    equipmentService = await Service.create({
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
    });
    log('✓', `Created Service: Equipment Booking [ID: ${equipmentService._id}]`);
  } else {
    log('ℹ', `Existing Service preserved: Equipment Booking [ID: ${equipmentService._id}]`);
  }

  // ── 4. Workflows ───────────────────────────────────────────────────────────
  console.log('\n🔄  4. Workflow Definitions');

  // Workflow 1: Bonafide Certificate Workflow
  let bonafideWorkflow = await Workflow.findOne({
    service: bonafideService._id,
    institution: institution._id,
  });
  if (!bonafideWorkflow) {
    bonafideWorkflow = await Workflow.create({
      name: 'Bonafide Certificate Workflow',
      service: bonafideService._id,
      institution: institution._id,
      version: 1,
      isActive: true,
      steps: [
        {
          stepIndex: 0,
          name: 'Department Verification',
          description: "Department secretary verifies the student's current enrolment and academic standing.",
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
    });
    await Service.findByIdAndUpdate(bonafideService._id, { workflow: bonafideWorkflow._id });
    log('✓', `Created Workflow & linked: Bonafide Certificate Workflow [ID: ${bonafideWorkflow._id}]`);
  } else {
    log('ℹ', `Existing Workflow preserved: Bonafide Certificate Workflow [ID: ${bonafideWorkflow._id}]`);
    if (!bonafideService.workflow) {
      await Service.findByIdAndUpdate(bonafideService._id, { workflow: bonafideWorkflow._id });
    }
  }

  // Workflow 2: ID Card Replacement Workflow
  let idCardWorkflow = await Workflow.findOne({
    service: idCardService._id,
    institution: institution._id,
  });
  if (!idCardWorkflow) {
    idCardWorkflow = await Workflow.create({
      name: 'ID Card Replacement Workflow',
      service: idCardService._id,
      institution: institution._id,
      version: 1,
      isActive: true,
      steps: [
        {
          stepIndex: 0,
          name: 'Security Review',
          description: "Security desk verifies the student's identity and confirms no account flags.",
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
    });
    await Service.findByIdAndUpdate(idCardService._id, { workflow: idCardWorkflow._id });
    log('✓', `Created Workflow & linked: ID Card Replacement Workflow [ID: ${idCardWorkflow._id}]`);
  } else {
    log('ℹ', `Existing Workflow preserved: ID Card Replacement Workflow [ID: ${idCardWorkflow._id}]`);
    if (!idCardService.workflow) {
      await Service.findByIdAndUpdate(idCardService._id, { workflow: idCardWorkflow._id });
    }
  }

  // Workflow 3: Equipment Booking Workflow
  let equipmentWorkflow = await Workflow.findOne({
    service: equipmentService._id,
    institution: institution._id,
  });
  if (!equipmentWorkflow) {
    equipmentWorkflow = await Workflow.create({
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
    });
    await Service.findByIdAndUpdate(equipmentService._id, { workflow: equipmentWorkflow._id });
    log('✓', `Created Workflow & linked: Equipment Booking Workflow [ID: ${equipmentWorkflow._id}]`);
  } else {
    log('ℹ', `Existing Workflow preserved: Equipment Booking Workflow [ID: ${equipmentWorkflow._id}]`);
    if (!equipmentService.workflow) {
      await Service.findByIdAndUpdate(equipmentService._id, { workflow: equipmentWorkflow._id });
    }
  }

  // ── 5. Index Synchronization ────────────────────────────────────────────────
  console.log('\n⚡  5. Index Synchronization');
  await Promise.all([
    Institution.syncIndexes(),
    Department.syncIndexes(),
    Service.syncIndexes(),
    Workflow.syncIndexes(),
    User.syncIndexes(),
    Request.syncIndexes(),
    Notification.syncIndexes(),
  ]);
  log('✓', 'All 7 collection indexes verified and synchronized.');

  // ── 6. Summary ─────────────────────────────────────────────────────────────
  console.log('\n' + '━'.repeat(55));
  console.log('✅  Production database initialization complete.\n');
  console.log('   Verification checklist:');
  console.log('   - Database: Verified strictly targeting [ uniflow_prod ].');
  console.log('   - 0 demo student accounts created.');
  console.log('   - 0 demo staff accounts created.');
  console.log('   - 0 demo admin accounts created.');
  console.log('   - 0 sample requests or transactions created.');
  console.log('   - Essential institution, departments, services, and workflows are active.');
  console.log('   - Next step: Run `npm run create-admin` to provision the primary administrator.\n');

  return {
    database: dbName,
    institution: institution.name,
    departments: Object.keys(departments),
    services: [bonafideService.name, idCardService.name, equipmentService.name],
  };
}

// ─── Direct CLI Execution Handler ─────────────────────────────────────────────
const isDirectExecution =
  process.argv[1] && path.resolve(process.argv[1]) === path.resolve(fileURLToPath(import.meta.url));

if (isDirectExecution) {
  initProd()
    .then(() => mongoose.disconnect())
    .catch(async (err) => {
      if (err.code === 'DATABASE_ISOLATION_VIOLATION') {
        console.error('\n🛑  DATABASE ISOLATION ERROR:');
        console.error(`    ${err.message}`);
        console.error(`    Actual connected database: [ ${err.actualDb ?? 'unknown'} ]`);
        console.error('    Aborting immediately. Zero database writes or schema modifications performed.\n');
        console.error('    To initialize the production database, explicitly provide the production URI:');
        console.error('    MONGO_URI="mongodb+srv://.../uniflow_prod?..." npm run init:prod\n');
      } else {
        console.error('\n❌  Initialization failed:', err.message);
      }
      await mongoose.disconnect().catch(() => {});
      process.exit(1);
    });
}
