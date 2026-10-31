/**
 * tests/workflow.test.js
 *
 * Automated tests for Phase 2 endpoints and workflow state machine:
 *  - Department routes (GET /api/departments)
 *  - Service routes (GET list, GET by id, POST create, access control & validation)
 *  - Request routes (submission validation, role guards, student self-approval restriction)
 *  - Staff queue routes (role guards, step action validation)
 *  - Admin routes (stats, list all requests, role guards)
 *  - Notification routes (authentication & read marking)
 *  - State machine transition rules & Rule 5 enforcement
 */

import { test, describe, mock } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import jwt from 'jsonwebtoken';
import Department from '../src/models/Department.js';
import Service from '../src/models/Service.js';
import Request from '../src/models/Request.js';

const { default: app } = await import('../src/app.js');
const requestService = await import('../src/services/request.service.js');

const JWT_SECRET = process.env.JWT_SECRET;

function createToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '1h' });
}

const studentToken = createToken({
  id: '64a1b2c3d4e5f6a7b8c9d001',
  role: 'student',
  email: 'student@uniflow.edu',
});

const staffToken = createToken({
  id: '64a1b2c3d4e5f6a7b8c9d002',
  role: 'staff',
  email: 'staff@uniflow.edu',
});

const adminToken = createToken({
  id: '64a1b2c3d4e5f6a7b8c9d003',
  role: 'admin',
  email: 'admin@uniflow.edu',
});

// ─── 1. Departments ──────────────────────────────────────────────────────────

describe('GET /api/departments', () => {
  test('returns 200 with standard success envelope and array', async () => {
    mock.method(Department, 'find', () => ({
      sort: () => ({
        select: async () => [
          {
            _id: '64a1b2c3d4e5f6a7b8c9d004',
            name: 'Computer Science',
            code: 'CS',
            institution: '64a1b2c3d4e5f6a7b8c9d000',
            isActive: true,
          },
        ],
      }),
    }));

    const res = await request(app).get('/api/departments');
    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.ok(Array.isArray(res.body.data));
    assert.equal(res.body.data[0].name, 'Computer Science');
    assert.equal(res.body.data[0].code, 'CS');
  });
});

// ─── 2. Services ─────────────────────────────────────────────────────────────

describe('GET /api/services — access control & listing', () => {
  test('no token returns 401 MISSING_TOKEN', async () => {
    const res = await request(app).get('/api/services');
    assert.equal(res.status, 401);
    assert.equal(res.body.error.code, 'MISSING_TOKEN');
  });

  test('authenticated student can retrieve service catalogue', async () => {
    mock.method(Service, 'find', () => ({
      populate: () => ({
        populate: () => ({
          sort: () => ({
            lean: async () => [
              {
                _id: '64a1b2c3d4e5f6a7b8c9d0e2',
                name: 'Bonafide Certificate',
                slug: 'bonafide-certificate',
                description: 'Enrolment letter',
                category: 'Academic',
                estimatedDays: 3,
                requiredDocuments: ['ID card'],
                responsibleDepartment: { _id: '64a1b2c3d4e5f6a7b8c9d0e8', name: 'Administration', code: 'ADMIN' },
                workflow: { steps: [{}, {}], version: 1 },
                isActive: true,
              },
            ],
          }),
        }),
      }),
    }));

    const res = await request(app)
      .get('/api/services')
      .set('Authorization', `Bearer ${studentToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.ok(Array.isArray(res.body.data));
    assert.equal(res.body.data[0].slug, 'bonafide-certificate');
    assert.equal(res.body.data[0].workflowStepCount, 2);
  });

  test('authenticated user can retrieve service details by slug', async () => {
    mock.method(Service, 'findOne', () => ({
      populate: () => ({
        populate: () => ({
          lean: async () => ({
            _id: '64a1b2c3d4e5f6a7b8c9d0e2',
            name: 'Bonafide Certificate',
            slug: 'bonafide-certificate',
            description: 'Enrolment letter',
            category: 'Academic',
            estimatedDays: 3,
            formFields: [{ name: 'purpose', label: 'Purpose', type: 'select', required: true }],
            workflow: { _id: '64a1b2c3d4e5f6a7b8c9d0f1', name: 'Bonafide Workflow', version: 1, steps: [] },
            isActive: true,
          }),
        }),
      }),
    }));

    const res = await request(app)
      .get('/api/services/bonafide-certificate')
      .set('Authorization', `Bearer ${studentToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(res.body.data.slug, 'bonafide-certificate');
    assert.ok(Array.isArray(res.body.data.formFields));
  });
});

describe('POST /api/services — admin role enforcement and validation', () => {
  test('student token returns 403 FORBIDDEN', async () => {
    const res = await request(app)
      .post('/api/services')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ name: 'Test Service' });

    assert.equal(res.status, 403);
    assert.equal(res.body.error.code, 'FORBIDDEN');
  });

  test('staff token returns 403 FORBIDDEN', async () => {
    const res = await request(app)
      .post('/api/services')
      .set('Authorization', `Bearer ${staffToken}`)
      .send({ name: 'Test Service' });

    assert.equal(res.status, 403);
    assert.equal(res.body.error.code, 'FORBIDDEN');
  });

  test('admin token with empty body returns 400 VALIDATION_ERROR', async () => {
    const res = await request(app)
      .post('/api/services')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});

    assert.equal(res.status, 400);
    assert.equal(res.body.error.code, 'VALIDATION_ERROR');
    assert.ok(Array.isArray(res.body.error.details));
  });

  test('admin token with invalid category returns 400 VALIDATION_ERROR', async () => {
    const res = await request(app)
      .post('/api/services')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'New Service',
        description: 'A valid description for service.',
        category: 'InvalidCategory',
        responsibleDepartmentId: '64a1b2c3d4e5f6a7b8c9d004',
      });

    assert.equal(res.status, 400);
    assert.equal(res.body.error.code, 'VALIDATION_ERROR');
    const catErr = res.body.error.details.find((d) => d.field === 'category');
    assert.ok(catErr);
  });
});

// ─── 3. Requests ─────────────────────────────────────────────────────────────

describe('POST /api/requests — role & validation', () => {
  test('unauthenticated returns 401 MISSING_TOKEN', async () => {
    const res = await request(app).post('/api/requests').send({});
    assert.equal(res.status, 401);
  });

  test('staff token returns 403 FORBIDDEN (student only)', async () => {
    const res = await request(app)
      .post('/api/requests')
      .set('Authorization', `Bearer ${staffToken}`)
      .send({ serviceId: '64a1b2c3d4e5f6a7b8c9d005' });

    assert.equal(res.status, 403);
    assert.equal(res.body.error.code, 'FORBIDDEN');
  });

  test('student token with empty body returns 400 VALIDATION_ERROR', async () => {
    const res = await request(app)
      .post('/api/requests')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({});

    assert.equal(res.status, 400);
    assert.equal(res.body.error.code, 'VALIDATION_ERROR');
    const err = res.body.error.details.find((d) => d.field === 'serviceId');
    assert.ok(err, 'Should flag missing serviceId');
  });
});

describe('Step Actions — role & validation', () => {
  test('student token cannot approve step (returns 403 FORBIDDEN)', async () => {
    const res = await request(app)
      .patch('/api/requests/64a1b2c3d4e5f6a7b8c9d005/steps/0/approve')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ comment: 'Self approval attempt' });

    assert.equal(res.status, 403);
    assert.equal(res.body.error.code, 'FORBIDDEN');
  });

  test('staff step rejection without comment returns 400 VALIDATION_ERROR', async () => {
    const res = await request(app)
      .patch('/api/requests/64a1b2c3d4e5f6a7b8c9d005/steps/0/reject')
      .set('Authorization', `Bearer ${staffToken}`)
      .send({ comment: '' });

    assert.equal(res.status, 400);
    assert.equal(res.body.error.code, 'VALIDATION_ERROR');
    const err = res.body.error.details.find((d) => d.field === 'comment');
    assert.ok(err, 'Comment is required when rejecting a step');
  });

  test('staff cannot call student payment confirmation endpoint (returns 403)', async () => {
    const res = await request(app)
      .patch('/api/requests/64a1b2c3d4e5f6a7b8c9d005/payment')
      .set('Authorization', `Bearer ${staffToken}`);

    assert.equal(res.status, 403);
    assert.equal(res.body.error.code, 'FORBIDDEN');
  });
});

// ─── 4. Staff Queue ──────────────────────────────────────────────────────────

describe('GET /api/staff/queue — role access', () => {
  test('no token returns 401', async () => {
    const res = await request(app).get('/api/staff/queue');
    assert.equal(res.status, 401);
  });

  test('student token returns 403 FORBIDDEN', async () => {
    const res = await request(app)
      .get('/api/staff/queue')
      .set('Authorization', `Bearer ${studentToken}`);

    assert.equal(res.status, 403);
    assert.equal(res.body.error.code, 'FORBIDDEN');
  });

  test('staff token receives queue array', async () => {
    mock.method(Request, 'find', () => ({
      populate: () => ({
        populate: () => ({
          sort: () => ({
            lean: async () => [
              {
                _id: '64a1b2c3d4e5f6a7b8c9d005',
                requestNumber: 'UF-20251014-ABCDEF',
                currentStepIndex: 0,
                status: 'DEPARTMENT_VERIFICATION_PENDING',
                createdAt: new Date(),
                runtimeSteps: [{ name: 'Department Verification', assignedRole: 'staff' }],
                student: { name: 'Arjun', email: 'arjun@test.edu', studentId: 'CS01' },
                service: { name: 'Bonafide Certificate', category: 'Academic' },
              },
            ],
          }),
        }),
      }),
    }));

    const res = await request(app)
      .get('/api/staff/queue')
      .set('Authorization', `Bearer ${staffToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.ok(Array.isArray(res.body.data));
    assert.equal(res.body.data[0].requestNumber, 'UF-20251014-ABCDEF');
  });
});

// ─── 5. Admin Endpoints ──────────────────────────────────────────────────────

describe('Admin Endpoints — role access', () => {
  test('GET /api/admin/stats with student token returns 403 FORBIDDEN', async () => {
    const res = await request(app)
      .get('/api/admin/stats')
      .set('Authorization', `Bearer ${studentToken}`);

    assert.equal(res.status, 403);
    assert.equal(res.body.error.code, 'FORBIDDEN');
  });

  test('GET /api/admin/stats with staff token returns 403 FORBIDDEN', async () => {
    const res = await request(app)
      .get('/api/admin/stats')
      .set('Authorization', `Bearer ${staffToken}`);

    assert.equal(res.status, 403);
    assert.equal(res.body.error.code, 'FORBIDDEN');
  });

  test('GET /api/admin/requests with student token returns 403 FORBIDDEN', async () => {
    const res = await request(app)
      .get('/api/admin/requests')
      .set('Authorization', `Bearer ${studentToken}`);

    assert.equal(res.status, 403);
    assert.equal(res.body.error.code, 'FORBIDDEN');
  });
});

// ─── 6. Notifications ────────────────────────────────────────────────────────

describe('Notifications Endpoints — authentication', () => {
  test('GET /api/notifications without token returns 401', async () => {
    const res = await request(app).get('/api/notifications');
    assert.equal(res.status, 401);
  });

  test('PATCH /api/notifications/read-all without token returns 401', async () => {
    const res = await request(app).patch('/api/notifications/read-all');
    assert.equal(res.status, 401);
  });

  test('PATCH /api/notifications/:id/read without token returns 401', async () => {
    const res = await request(app).patch('/api/notifications/64a1b2c3d4e5f6a7b8c9d005/read');
    assert.equal(res.status, 401);
  });
});

// ─── 7. Workflow State Machine Unit Rules ─────────────────────────────────────

describe('Workflow State Machine — business rules & restrictions', () => {
  test('Rule 5: Student cannot approve their own request', async () => {
    const studentId = '64a1b2c3d4e5f6a7b8c9d001';
    mock.method(Request, 'findById', () => ({
      populate: async () => ({
        _id: '64a1b2c3d4e5f6a7b8c9d005',
        requestNumber: 'UF-20251014-ABCDEF',
        student: { toString: () => studentId },
        status: 'DEPARTMENT_VERIFICATION_PENDING',
        currentStepIndex: 0,
        runtimeSteps: [{ assignedRole: 'staff', name: 'Dept Verification' }],
        service: { name: 'Bonafide Certificate' },
      }),
    }));

    await assert.rejects(
      async () => {
        await requestService.actionStep({
          requestId: '64a1b2c3d4e5f6a7b8c9d005',
          stepIndex: 0,
          action: 'APPROVE',
          actorUser: { id: studentId, role: 'staff' }, // even if dual role or student attempt
        });
      },
      (err) => {
        assert.equal(err.statusCode, 403);
        assert.match(err.message, /student cannot approve/i);
        return true;
      }
    );
  });

  test('Cannot action terminal request (COMPLETED or REJECTED)', async () => {
    mock.method(Request, 'findById', () => ({
      populate: async () => ({
        _id: '64a1b2c3d4e5f6a7b8c9d005',
        requestNumber: 'UF-20251014-ABCDEF',
        student: { toString: () => '64a1b2c3d4e5f6a7b8c9d999' },
        status: 'COMPLETED',
        currentStepIndex: 1,
        runtimeSteps: [],
        service: { name: 'Bonafide Certificate' },
      }),
    }));

    await assert.rejects(
      async () => {
        await requestService.actionStep({
          requestId: '64a1b2c3d4e5f6a7b8c9d005',
          stepIndex: 1,
          action: 'APPROVE',
          actorUser: { id: '64a1b2c3d4e5f6a7b8c9d888', role: 'admin' },
        });
      },
      (err) => {
        assert.equal(err.statusCode, 400);
        assert.equal(err.errorCode, 'INVALID_TRANSITION');
        return true;
      }
    );
  });

  test('Rejection requires a non-empty comment', async () => {
    mock.method(Request, 'findById', () => ({
      populate: async () => ({
        _id: '64a1b2c3d4e5f6a7b8c9d005',
        requestNumber: 'UF-20251014-ABCDEF',
        student: { toString: () => '64a1b2c3d4e5f6a7b8c9d999' },
        status: 'DEPARTMENT_VERIFICATION_PENDING',
        currentStepIndex: 0,
        runtimeSteps: [{ assignedRole: 'staff', name: 'Dept Verification' }],
        service: { name: 'Bonafide Certificate' },
      }),
    }));

    await assert.rejects(
      async () => {
        await requestService.actionStep({
          requestId: '64a1b2c3d4e5f6a7b8c9d005',
          stepIndex: 0,
          action: 'REJECT',
          actorUser: { id: '64a1b2c3d4e5f6a7b8c9d888', role: 'staff' },
          comment: '',
        });
      },
      (err) => {
        assert.equal(err.statusCode, 400);
        assert.equal(err.errorCode, 'VALIDATION_ERROR');
        return true;
      }
    );
  });

  test('Payment step confirmation requires PAYMENT_REQUIRED status', async () => {
    const studentId = '64a1b2c3d4e5f6a7b8c9d001';
    mock.method(Request, 'findById', () => ({
      populate: async () => ({
        _id: '64a1b2c3d4e5f6a7b8c9d005',
        requestNumber: 'UF-20251014-ABCDEF',
        student: { toString: () => studentId },
        status: 'SECURITY_REVIEW_PENDING', // not yet at payment step
        currentStepIndex: 0,
        runtimeSteps: [{ isPaymentStep: false }],
        service: { name: 'ID Card Replacement' },
      }),
    }));

    await assert.rejects(
      async () => {
        await requestService.confirmPayment({
          requestId: '64a1b2c3d4e5f6a7b8c9d005',
          studentUser: { id: studentId, role: 'student' },
        });
      },
      (err) => {
        assert.equal(err.statusCode, 400);
        assert.equal(err.errorCode, 'INVALID_TRANSITION');
        return true;
      }
    );
  });

  test('Non-owning student cannot confirm payment on another student request', async () => {
    mock.method(Request, 'findById', () => ({
      populate: async () => ({
        _id: '64a1b2c3d4e5f6a7b8c9d005',
        requestNumber: 'UF-20251014-ABCDEF',
        student: { toString: () => '64a1b2c3d4e5f6a7b8c9d001' },
        status: 'PAYMENT_REQUIRED',
        currentStepIndex: 1,
        runtimeSteps: [{}, { isPaymentStep: true }],
        service: { name: 'ID Card Replacement' },
      }),
    }));

    await assert.rejects(
      async () => {
        await requestService.confirmPayment({
          requestId: '64a1b2c3d4e5f6a7b8c9d005',
          studentUser: { id: '64a1b2c3d4e5f6a7b8c9d999', role: 'student' }, // different student
        });
      },
      (err) => {
        assert.equal(err.statusCode, 403);
        assert.equal(err.errorCode, 'FORBIDDEN');
        return true;
      }
    );
  });
});

