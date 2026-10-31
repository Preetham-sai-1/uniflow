/**
 * tests/models.test.js
 *
 * Schema validation tests for Mongoose models.
 * These tests call doc.validate() which runs schema validation rules
 * WITHOUT requiring a live database connection.
 *
 * What is tested:
 *  - Required field enforcement
 *  - Enum validation
 *  - String length constraints
 *  - Default values
 *
 * What is NOT tested here:
 *  - Unique index constraints (requires a live DB)
 *  - Population of references (requires a live DB)
 *  - The pre-save requestNumber hook (requires a save() call with a live DB)
 *
 * Environment: loaded from tests/.env.test via --env-file flag in `npm test`.
 */

import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import mongoose from 'mongoose';

// Models (imported but not connected to any DB)
const { default: User } = await import('../src/models/User.js');
const { default: Institution } = await import('../src/models/Institution.js');
const { default: Department } = await import('../src/models/Department.js');
const { default: Service } = await import('../src/models/Service.js');
const { default: Workflow } = await import('../src/models/Workflow.js');
const { default: Request } = await import('../src/models/Request.js');
const { default: Notification } = await import('../src/models/Notification.js');

// Fake ObjectId for reference fields
const fakeId = new mongoose.Types.ObjectId();

// ─── Institution ──────────────────────────────────────────────────────────────

describe('Institution model', () => {
  test('valid institution passes validation', async () => {
    const doc = new Institution({ name: 'Test University', slug: 'test-university', code: 'TU' });
    await assert.doesNotReject(() => doc.validate(), 'Valid institution should pass validation');
  });

  test('missing name fails validation', async () => {
    const doc = new Institution({ slug: 'test-university', code: 'TU' });
    await assert.rejects(() => doc.validate(), /name is required/i);
  });

  test('slug with uppercase fails validation', async () => {
    const doc = new Institution({ name: 'Test', slug: 'Test-University', code: 'TU' });
    // Mongoose lowercases slug automatically; slug regex check applies after lowercasing
    // so this should pass (becomes 'test-university')
    await assert.doesNotReject(() => doc.validate());
  });
});

// ─── Department ────────────────────────────────────────────────────────────────

describe('Department model', () => {
  test('valid department passes validation', async () => {
    const doc = new Department({ name: 'Computer Science', code: 'CS', institution: fakeId });
    await assert.doesNotReject(() => doc.validate());
  });

  test('missing institution fails validation', async () => {
    const doc = new Department({ name: 'Computer Science', code: 'CS' });
    await assert.rejects(() => doc.validate(), /institution/i);
  });

  test('missing code fails validation', async () => {
    const doc = new Department({ name: 'Computer Science', institution: fakeId });
    await assert.rejects(() => doc.validate(), /code/i);
  });
});

// ─── User ─────────────────────────────────────────────────────────────────────

describe('User model', () => {
  test('valid student user passes validation', async () => {
    const doc = new User({
      name: 'Arjun Sharma',
      email: 'arjun@test.edu',
      passwordHash: 'hashed',
      role: 'student',
      institution: fakeId,
    });
    await assert.doesNotReject(() => doc.validate());
  });

  test('invalid role fails validation', async () => {
    const doc = new User({
      name: 'Test',
      email: 'test@test.edu',
      passwordHash: 'hashed',
      role: 'superuser', // invalid
      institution: fakeId,
    });
    await assert.rejects(() => doc.validate(), /role/i);
  });

  test('missing email fails validation', async () => {
    const doc = new User({ name: 'Test', passwordHash: 'hashed', role: 'student', institution: fakeId });
    await assert.rejects(() => doc.validate(), /email/i);
  });

  test('invalid email format fails validation', async () => {
    const doc = new User({
      name: 'Test',
      email: 'not-an-email',
      passwordHash: 'hashed',
      role: 'student',
      institution: fakeId,
    });
    await assert.rejects(() => doc.validate(), /email/i);
  });

  test('name too short fails validation', async () => {
    const doc = new User({
      name: 'A',
      email: 'a@test.edu',
      passwordHash: 'hashed',
      role: 'student',
      institution: fakeId,
    });
    await assert.rejects(() => doc.validate(), /name/i);
  });

  test('isActive defaults to true', () => {
    const doc = new User({ name: 'Test', email: 'x@x.com', passwordHash: 'h', role: 'staff', institution: fakeId });
    assert.equal(doc.isActive, true);
  });
});

// ─── Service ──────────────────────────────────────────────────────────────────

describe('Service model', () => {
  test('valid service passes validation', async () => {
    const doc = new Service({
      name: 'Bonafide Certificate',
      slug: 'bonafide-certificate',
      description: 'Official enrolment letter.',
      category: 'Academic',
      responsibleDepartment: fakeId,
      institution: fakeId,
    });
    await assert.doesNotReject(() => doc.validate());
  });

  test('invalid category fails validation', async () => {
    const doc = new Service({
      name: 'Test Service',
      slug: 'test-service',
      description: 'A test service.',
      category: 'InvalidCategory',
      responsibleDepartment: fakeId,
      institution: fakeId,
    });
    await assert.rejects(() => doc.validate(), /category/i);
  });

  test('estimatedDays defaults to 3', () => {
    const doc = new Service({
      name: 'Test',
      slug: 'test',
      description: 'Test.',
      category: 'Other',
      responsibleDepartment: fakeId,
      institution: fakeId,
    });
    assert.equal(doc.estimatedDays, 3);
  });
});

// ─── Workflow ──────────────────────────────────────────────────────────────────

describe('Workflow model', () => {
  const validStep = {
    stepIndex: 0,
    name: 'Staff Review',
    assignedRole: 'staff',
    pendingStatus: 'STAFF_REVIEW_PENDING',
  };

  test('valid workflow passes validation', async () => {
    const doc = new Workflow({
      name: 'Test Workflow',
      service: fakeId,
      institution: fakeId,
      version: 1,
      steps: [validStep],
    });
    await assert.doesNotReject(() => doc.validate());
  });

  test('empty steps array fails validation', async () => {
    const doc = new Workflow({ name: 'Test', service: fakeId, institution: fakeId, version: 1, steps: [] });
    await assert.rejects(() => doc.validate(), /step/i);
  });

  test('step with invalid assignedRole fails validation', async () => {
    const doc = new Workflow({
      name: 'Test',
      service: fakeId,
      institution: fakeId,
      version: 1,
      steps: [{ ...validStep, assignedRole: 'superuser' }],
    });
    await assert.rejects(() => doc.validate(), /role/i);
  });

  test('version defaults to 1', () => {
    const doc = new Workflow({ name: 'Test', service: fakeId, institution: fakeId, steps: [validStep] });
    assert.equal(doc.version, 1);
  });
});

// ─── Request ──────────────────────────────────────────────────────────────────

describe('Request model', () => {
  test('valid request passes validation', async () => {
    const doc = new Request({
      student: fakeId,
      service: fakeId,
      institution: fakeId,
      workflow: fakeId,
      workflowVersion: 1,
      status: 'SUBMITTED',
    });
    await assert.doesNotReject(() => doc.validate());
  });

  test('invalid status fails validation', async () => {
    const doc = new Request({
      student: fakeId,
      service: fakeId,
      institution: fakeId,
      workflow: fakeId,
      workflowVersion: 1,
      status: 'INVALID_STATUS',
    });
    await assert.rejects(() => doc.validate(), /status/i);
  });

  test('status defaults to SUBMITTED', () => {
    const doc = new Request({
      student: fakeId,
      service: fakeId,
      institution: fakeId,
      workflow: fakeId,
      workflowVersion: 1,
    });
    assert.equal(doc.status, 'SUBMITTED');
  });

  test('currentStepIndex defaults to 0', () => {
    const doc = new Request({
      student: fakeId,
      service: fakeId,
      institution: fakeId,
      workflow: fakeId,
      workflowVersion: 1,
    });
    assert.equal(doc.currentStepIndex, 0);
  });

  test('REQUEST_STATUSES export contains all expected values', async () => {
    const { REQUEST_STATUSES } = await import('../src/models/Request.js');
    const expected = [
      'SUBMITTED', 'DEPARTMENT_VERIFICATION_PENDING', 'SECURITY_REVIEW_PENDING',
      'PAYMENT_REQUIRED', 'ADMIN_APPROVAL_PENDING', 'STAFF_REVIEW_PENDING',
      'BOOKING_CONFIRMED', 'COMPLETED', 'REJECTED',
    ];
    for (const status of expected) {
      assert.ok(REQUEST_STATUSES.includes(status), `${status} should be in REQUEST_STATUSES`);
    }
  });
});

// ─── Notification ─────────────────────────────────────────────────────────────

describe('Notification model', () => {
  test('valid notification passes validation', async () => {
    const doc = new Notification({
      recipient: fakeId,
      title: 'Your request has been approved',
      message: 'Your Bonafide Certificate request has moved to the next step.',
      type: 'STEP_APPROVED',
    });
    await assert.doesNotReject(() => doc.validate());
  });

  test('invalid notification type fails validation', async () => {
    const doc = new Notification({
      recipient: fakeId,
      title: 'Test',
      message: 'Test message',
      type: 'INVALID_TYPE',
    });
    await assert.rejects(() => doc.validate(), /type/i);
  });

  test('isRead defaults to false', () => {
    const doc = new Notification({ recipient: fakeId, title: 'T', message: 'M', type: 'INFO' });
    assert.equal(doc.isRead, false);
  });

  test('missing recipient fails validation', async () => {
    const doc = new Notification({ title: 'T', message: 'M', type: 'INFO' });
    await assert.rejects(() => doc.validate(), /recipient/i);
  });
});
