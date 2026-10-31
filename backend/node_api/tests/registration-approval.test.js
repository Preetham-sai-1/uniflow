/**
 * tests/registration-approval.test.js
 *
 * Tests for user registration and admin approval workflow:
 *  - User model approvalStatus defaults and enums
 *  - Registration assigning 'student' role and 'PENDING' approvalStatus
 *  - Duplicate email and student ID conflict handling (409)
 *  - Pending and rejected user login blocks (403)
 *  - Admin listing pending registrations
 *  - Admin approve and reject operations
 *  - Role-based authorization for approval endpoints
 */

import { test, describe, mock } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import jwt from 'jsonwebtoken';
import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

import User from '../src/models/User.js';
import Department from '../src/models/Department.js';
import Institution from '../src/models/Institution.js';

const { default: app } = await import('../src/app.js');

const JWT_SECRET = process.env.JWT_SECRET || 'test-jwt-secret-at-least-32-chars-long';

function createToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '1h' });
}

const adminToken = createToken({
  id: '64a1b2c3d4e5f6a7b8c9d001',
  role: 'admin',
  email: 'admin@uniflow.edu',
  institution: '64a1b2c3d4e5f6a7b8c9d000',
});

const staffToken = createToken({
  id: '64a1b2c3d4e5f6a7b8c9d002',
  role: 'staff',
  email: 'staff@uniflow.edu',
  institution: '64a1b2c3d4e5f6a7b8c9d000',
});

const studentToken = createToken({
  id: '64a1b2c3d4e5f6a7b8c9d003',
  role: 'student',
  email: 'student@uniflow.edu',
  institution: '64a1b2c3d4e5f6a7b8c9d000',
});

const fakeInstId = new mongoose.Types.ObjectId();
const fakeDeptId = new mongoose.Types.ObjectId();

describe('User Model — approvalStatus schema', () => {
  test('approvalStatus defaults to APPROVED for backward compatibility', () => {
    const user = new User({
      name: 'Existing User',
      email: 'existing@uniflow.edu',
      passwordHash: 'hashed',
      role: 'student',
      institution: fakeInstId,
    });
    assert.equal(user.approvalStatus, 'APPROVED');
  });

  test('approvalStatus accepts PENDING, APPROVED, and REJECTED', async () => {
    for (const status of ['PENDING', 'APPROVED', 'REJECTED']) {
      const user = new User({
        name: 'Status Test',
        email: `status_${status.toLowerCase()}@uniflow.edu`,
        passwordHash: 'hashed',
        role: 'student',
        institution: fakeInstId,
        approvalStatus: status,
      });
      await assert.doesNotReject(() => user.validate());
    }
  });

  test('approvalStatus rejects invalid status values', async () => {
    const user = new User({
      name: 'Invalid Status',
      email: 'invalid@uniflow.edu',
      passwordHash: 'hashed',
      role: 'student',
      institution: fakeInstId,
      approvalStatus: 'UNKNOWN_STATUS',
    });
    await assert.rejects(() => user.validate(), /Approval status must be one of/i);
  });
});

describe('POST /api/auth/register — approval & role isolation', () => {
  test('registers student with approvalStatus PENDING and role student', async () => {
    mock.method(Institution, 'findOne', () => ({
      lean: async () => ({
        _id: fakeInstId,
        name: 'Demo University',
        isActive: true,
      }),
    }));

    mock.method(Department, 'findOne', () => ({
      lean: async () => ({
        _id: fakeDeptId,
        name: 'Computer Science',
        institution: fakeInstId,
      }),
    }));

    mock.method(User, 'findOne', () => ({
      lean: async () => null,
    }));

    mock.method(User, 'create', async (doc) => ({
      _id: new mongoose.Types.ObjectId(),
      ...doc,
      createdAt: new Date(),
    }));

    const res = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Rohan Sharma',
        email: 'rohan.sharma@campus.edu',
        password: 'Password123!',
        studentId: 'STU99881',
        departmentId: fakeDeptId.toString(),
      });

    assert.equal(res.status, 201);
    assert.equal(res.body.success, true);
    assert.equal(res.body.data.user.role, 'student', 'Server must enforce role: student');
    assert.equal(res.body.data.user.approvalStatus, 'PENDING');
    assert.equal(res.body.data.user.studentId, 'STU99881');
    assert.equal(res.body.data.token, undefined, 'Must not issue active JWT session before approval');
    assert.equal(res.body.data.user.passwordHash, undefined, 'Must not expose passwordHash');

    mock.restoreAll();
  });

  test('rejects duplicate email with 409 CONFLICT', async () => {
    mock.method(Institution, 'findOne', () => ({
      lean: async () => ({
        _id: fakeInstId,
        name: 'Demo University',
        isActive: true,
      }),
    }));

    mock.method(User, 'findOne', (query) => ({
      lean: async () => {
        if (query.email) {
          return { _id: fakeDeptId, email: query.email };
        }
        return null;
      },
    }));

    const res = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Rohan Sharma',
        email: 'rohan.duplicate@campus.edu',
        password: 'Password123!',
        studentId: 'STU99882',
      });

    assert.equal(res.status, 409);
    assert.equal(res.body.success, false);
    assert.equal(res.body.error.code, 'CONFLICT');
    assert.match(res.body.error.message, /email/i);

    mock.restoreAll();
  });

  test('rejects duplicate studentId with 409 CONFLICT', async () => {
    mock.method(Institution, 'findOne', () => ({
      lean: async () => ({
        _id: fakeInstId,
        name: 'Demo University',
        isActive: true,
      }),
    }));

    mock.method(User, 'findOne', (query) => ({
      lean: async () => {
        if (query.studentId) {
          return { _id: fakeDeptId, studentId: query.studentId };
        }
        return null;
      },
    }));

    const res = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Rohan Sharma',
        email: 'rohan.unique@campus.edu',
        password: 'Password123!',
        studentId: 'STU99883',
      });

    assert.equal(res.status, 409);
    assert.equal(res.body.success, false);
    assert.equal(res.body.error.code, 'CONFLICT');
    assert.match(res.body.error.message, /student id/i);

    mock.restoreAll();
  });
});

describe('POST /api/auth/login — approval enforcement', () => {
  const hash = bcrypt.hashSync('Password123!', 10);

  test('blocks pending user with 403 ACCOUNT_PENDING_APPROVAL', async () => {
    mock.method(User, 'findOne', () => ({
      select: () => ({
        _id: new mongoose.Types.ObjectId(),
        email: 'pending@campus.edu',
        name: 'Pending Student',
        passwordHash: hash,
        role: 'student',
        isActive: true,
        approvalStatus: 'PENDING',
      }),
    }));

    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'pending@campus.edu',
        password: 'Password123!',
      });

    assert.equal(res.status, 403);
    assert.equal(res.body.success, false);
    assert.equal(res.body.error.code, 'ACCOUNT_PENDING_APPROVAL');

    mock.restoreAll();
  });

  test('blocks rejected user with 403 ACCOUNT_REJECTED', async () => {
    mock.method(User, 'findOne', () => ({
      select: () => ({
        _id: new mongoose.Types.ObjectId(),
        email: 'rejected@campus.edu',
        name: 'Rejected Student',
        passwordHash: hash,
        role: 'student',
        isActive: false,
        approvalStatus: 'REJECTED',
        rejectionReason: 'Invalid student ID documentation',
      }),
    }));

    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'rejected@campus.edu',
        password: 'Password123!',
      });

    assert.equal(res.status, 403);
    assert.equal(res.body.success, false);
    assert.equal(res.body.error.code, 'ACCOUNT_REJECTED');
    assert.match(res.body.error.message, /Invalid student ID documentation/);

    mock.restoreAll();
  });

  test('allows approved user to log in and returns JWT', async () => {
    mock.method(User, 'findOne', () => ({
      select: () => ({
        _id: new mongoose.Types.ObjectId(),
        email: 'approved@campus.edu',
        name: 'Approved Student',
        passwordHash: hash,
        role: 'student',
        isActive: true,
        approvalStatus: 'APPROVED',
      }),
    }));

    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'approved@campus.edu',
        password: 'Password123!',
      });

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.ok(res.body.data.token, 'Should return jwt token');
    assert.equal(res.body.data.user.approvalStatus, 'APPROVED');

    mock.restoreAll();
  });
});

describe('Admin Approval Endpoints — Role-Based Authorization', () => {
  const targetUserId = '64a1b2c3d4e5f6a7b8c9d999';

  test('GET /api/admin/pending-users rejected for unauthenticated request (401)', async () => {
    const res = await request(app).get('/api/admin/pending-users');
    assert.equal(res.status, 401);
  });

  test('GET /api/admin/pending-users rejected for student (403 FORBIDDEN)', async () => {
    const res = await request(app)
      .get('/api/admin/pending-users')
      .set('Authorization', `Bearer ${studentToken}`);
    assert.equal(res.status, 403);
  });

  test('GET /api/admin/pending-users rejected for staff (403 FORBIDDEN)', async () => {
    const res = await request(app)
      .get('/api/admin/pending-users')
      .set('Authorization', `Bearer ${staffToken}`);
    assert.equal(res.status, 403);
  });

  test('GET /api/admin/pending-users succeeds for admin (200)', async () => {
    mock.method(User, 'find', () => ({
      populate: () => ({
        populate: () => ({
          sort: () => ({
            lean: async () => [
              {
                _id: new mongoose.Types.ObjectId(targetUserId),
                name: 'Pending Student',
                email: 'pending@campus.edu',
                studentId: 'STU111',
                approvalStatus: 'PENDING',
                createdAt: new Date(),
              },
            ],
          }),
        }),
      }),
    }));

    const res = await request(app)
      .get('/api/admin/pending-users')
      .set('Authorization', `Bearer ${adminToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.ok(Array.isArray(res.body.data));
    assert.equal(res.body.data.length, 1);
    assert.equal(res.body.data[0].approvalStatus, 'PENDING');

    mock.restoreAll();
  });

  test('PATCH /api/admin/users/:id/approve updates user to APPROVED', async () => {
    const mockUser = {
      _id: new mongoose.Types.ObjectId(targetUserId),
      name: 'Pending Student',
      email: 'pending@campus.edu',
      role: 'student',
      approvalStatus: 'PENDING',
      isActive: false,
      save: async function () {
        return this;
      },
      populate: async function () {
        return this;
      },
    };

    mock.method(User, 'findById', async () => mockUser);

    const res = await request(app)
      .patch(`/api/admin/users/${targetUserId}/approve`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send();

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(mockUser.approvalStatus, 'APPROVED');
    assert.equal(mockUser.isActive, true);
    assert.ok(mockUser.approvedAt);

    mock.restoreAll();
  });

  test('PATCH /api/admin/users/:id/reject updates user to REJECTED with reason', async () => {
    const mockUser = {
      _id: new mongoose.Types.ObjectId(targetUserId),
      name: 'Pending Student',
      email: 'pending@campus.edu',
      role: 'student',
      approvalStatus: 'PENDING',
      isActive: false,
      save: async function () {
        return this;
      },
      populate: async function () {
        return this;
      },
    };

    mock.method(User, 'findById', async () => mockUser);

    const res = await request(app)
      .patch(`/api/admin/users/${targetUserId}/reject`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ reason: 'Invalid identity documentation provided' });

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(mockUser.approvalStatus, 'REJECTED');
    assert.equal(mockUser.rejectionReason, 'Invalid identity documentation provided');

    mock.restoreAll();
  });
});
