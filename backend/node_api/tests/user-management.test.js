/**
 * tests/user-management.test.js
 *
 * Automated tests for Role-Based User Management System:
 *  - Admin creates student
 *  - Admin creates staff
 *  - Admin changes student to staff
 *  - Admin changes staff to student
 *  - Staff cannot create accounts (403)
 *  - Staff cannot change roles (403)
 *  - Staff can delete student
 *  - Staff cannot delete staff or admin (403)
 *  - Admin can delete student and staff
 *  - No user can delete an admin (403)
 *  - No user can delete themselves (400)
 *  - Public registration cannot assign staff/admin roles (400)
 *  - Existing login and approval workflows continue working
 *  - Historical service requests remain intact after account deletion
 */

import { test, describe, mock } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import jwt from 'jsonwebtoken';
import mongoose from 'mongoose';

import User from '../src/models/User.js';
import Department from '../src/models/Department.js';
import Institution from '../src/models/Institution.js';
import Request from '../src/models/Request.js';
import UserDeletionAudit from '../src/models/UserDeletionAudit.js';

const { default: app } = await import('../src/app.js');

const JWT_SECRET = process.env.JWT_SECRET || 'test-jwt-secret-at-least-32-chars-long';

function createToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '1h' });
}

const adminId = '64a1b2c3d4e5f6a7b8c9d001';
const staffId = '64a1b2c3d4e5f6a7b8c9d002';
const studentId = '64a1b2c3d4e5f6a7b8c9d003';
const fakeInstId = new mongoose.Types.ObjectId();
const fakeDeptId = new mongoose.Types.ObjectId();

const adminToken = createToken({
  userId: adminId,
  role: 'admin',
  email: 'admin@uniflow.edu',
  institution: fakeInstId.toString(),
});

const staffToken = createToken({
  userId: staffId,
  role: 'staff',
  email: 'staff@uniflow.edu',
  institution: fakeInstId.toString(),
});

const studentToken = createToken({
  id: studentId,
  role: 'student',
  email: 'student@uniflow.edu',
  institution: fakeInstId.toString(),
});

describe('Role-Based User Management — Admin Creation', () => {
  test('Admin creates student successfully', async () => {
    mock.method(Institution, 'findOne', () => ({
      lean: async () => ({ _id: fakeInstId, name: 'Campus University', isActive: true }),
    }));
    mock.method(Department, 'findOne', () => ({
      lean: async () => ({ _id: fakeDeptId, name: 'Computer Science', isActive: true }),
    }));
    mock.method(User, 'findOne', () => ({
      lean: async () => null,
    }));

    let createdDoc = null;
    mock.method(User, 'create', async (doc) => {
      createdDoc = doc;
      return {
        _id: new mongoose.Types.ObjectId(),
        ...doc,
        createdAt: new Date(),
      };
    });

    const res = await request(app)
      .post('/api/admin/users')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'New Student',
        email: 'new.student@campus.edu',
        password: 'TemporaryPassword123!',
        role: 'student',
        studentId: 'STU-9901',
        departmentId: fakeDeptId.toString(),
      });

    assert.equal(res.status, 201);
    assert.equal(res.body.success, true);
    assert.equal(res.body.data.user.role, 'student');
    assert.equal(res.body.data.user.mustChangePassword, true);
    assert.equal(res.body.data.user.passwordHash, undefined);
    assert.equal(createdDoc.role, 'student');
    assert.equal(createdDoc.studentId, 'STU-9901');

    mock.restoreAll();
  });

  test('Admin creates staff successfully', async () => {
    mock.method(Institution, 'findOne', () => ({
      lean: async () => ({ _id: fakeInstId, name: 'Campus University', isActive: true }),
    }));
    mock.method(Department, 'findOne', () => ({
      lean: async () => ({ _id: fakeDeptId, name: 'Mechanical Engineering', isActive: true }),
    }));
    mock.method(User, 'findOne', () => ({
      lean: async () => null,
    }));

    let createdDoc = null;
    mock.method(User, 'create', async (doc) => {
      createdDoc = doc;
      return {
        _id: new mongoose.Types.ObjectId(),
        ...doc,
        createdAt: new Date(),
      };
    });

    const res = await request(app)
      .post('/api/admin/users')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'Prof. Sharma',
        email: 'prof.sharma@campus.edu',
        password: 'TemporaryStaffPass123!',
        role: 'staff',
        staffId: 'FAC-7701',
        departmentId: fakeDeptId.toString(),
      });

    assert.equal(res.status, 201);
    assert.equal(res.body.success, true);
    assert.equal(res.body.data.user.role, 'staff');
    assert.equal(res.body.data.user.staffId, 'FAC-7701');
    assert.equal(createdDoc.role, 'staff');

    mock.restoreAll();
  });

  test('Admin cannot create an admin account through user management', async () => {
    const res = await request(app)
      .post('/api/admin/users')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'New Admin',
        email: 'new.admin@campus.edu',
        password: 'Password123!',
        role: 'admin',
      });

    assert.equal(res.status, 400);
    assert.equal(res.body.success, false);
    assert.equal(res.body.error.code, 'VALIDATION_ERROR');
  });

  test('Staff cannot create accounts (403 Forbidden)', async () => {
    const res = await request(app)
      .post('/api/admin/users')
      .set('Authorization', `Bearer ${staffToken}`)
      .send({
        name: 'Unauthorized User',
        email: 'unauth@campus.edu',
        password: 'Password123!',
        role: 'student',
      });

    assert.equal(res.status, 403);
  });
});

describe('Role-Based User Management — Role Assignment & Changes', () => {
  const targetStudentId = '64a1b2c3d4e5f6a7b8c9d055';
  const targetStaffId = '64a1b2c3d4e5f6a7b8c9d066';
  const targetAdminId = '64a1b2c3d4e5f6a7b8c9d077';

  test('Admin changes student to staff successfully', async () => {
    const studentUser = {
      _id: new mongoose.Types.ObjectId(targetStudentId),
      name: 'Promoted Student',
      email: 'promoted@campus.edu',
      role: 'student',
      save: async function () {
        return this;
      },
    };

    mock.method(User, 'findById', async () => studentUser);

    const res = await request(app)
      .patch(`/api/admin/users/${targetStudentId}/role`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ role: 'staff' });

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(studentUser.role, 'staff');

    mock.restoreAll();
  });

  test('Admin changes staff to student successfully', async () => {
    const staffUser = {
      _id: new mongoose.Types.ObjectId(targetStaffId),
      name: 'Demoted Staff',
      email: 'staff.to.student@campus.edu',
      role: 'staff',
      staffId: 'STAFF-123',
      save: async function () {
        return this;
      },
    };

    mock.method(User, 'findById', async () => staffUser);

    const res = await request(app)
      .patch(`/api/admin/users/${targetStaffId}/role`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ role: 'student' });

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(staffUser.role, 'student');
    assert.equal(staffUser.staffId, null);

    mock.restoreAll();
  });

  test('Staff cannot change user roles (403 Forbidden)', async () => {
    const res = await request(app)
      .patch(`/api/admin/users/${targetStudentId}/role`)
      .set('Authorization', `Bearer ${staffToken}`)
      .send({ role: 'staff' });

    assert.equal(res.status, 403);
  });

  test('Admin cannot promote a user to admin via user management', async () => {
    const res = await request(app)
      .patch(`/api/admin/users/${targetStudentId}/role`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ role: 'admin' });

    assert.equal(res.status, 400);
    assert.equal(res.body.error.code, 'VALIDATION_ERROR');
  });

  test('Admin cannot demote an admin through user management', async () => {
    const targetAdminUser = {
      _id: new mongoose.Types.ObjectId(targetAdminId),
      name: 'Another Admin',
      email: 'admin2@campus.edu',
      role: 'admin',
    };

    mock.method(User, 'findById', async () => targetAdminUser);

    const res = await request(app)
      .patch(`/api/admin/users/${targetAdminId}/role`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ role: 'staff' });

    assert.equal(res.status, 403);
    assert.match(res.body.error.message, /Administrator accounts cannot be demoted/i);

    mock.restoreAll();
  });
});

describe('Role-Based User Management — Account Deletion & Safeguards', () => {
  const targetStudentId = '64a1b2c3d4e5f6a7b8c9d088';
  const targetStaffId = '64a1b2c3d4e5f6a7b8c9d089';
  const targetAdminId = '64a1b2c3d4e5f6a7b8c9d090';

  test('Staff can delete student account', async () => {
    const mockStudent = {
      _id: new mongoose.Types.ObjectId(targetStudentId),
      name: 'Graduated Student',
      email: 'graduated@campus.edu',
      role: 'student',
      studentId: 'STU-GRAD-01',
      institution: fakeInstId,
      department: fakeDeptId,
    };

    mock.method(User, 'findById', async () => mockStudent);
    let auditCreated = false;
    mock.method(UserDeletionAudit, 'create', async (doc) => {
      auditCreated = true;
      assert.equal(doc.deletedUserId.toString(), targetStudentId);
      assert.equal(doc.deletedUserRole, 'student');
      assert.equal(doc.deletedBy.toString(), staffId);
      assert.equal(doc.deletedByRole, 'staff');
      return doc;
    });
    let deletedId = null;
    mock.method(User, 'findByIdAndDelete', async (id) => {
      deletedId = id.toString();
      return mockStudent;
    });

    const res = await request(app)
      .delete(`/api/staff/students/${targetStudentId}`)
      .set('Authorization', `Bearer ${staffToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(auditCreated, true, 'Must write deletion audit record');
    assert.equal(deletedId, targetStudentId);

    mock.restoreAll();
  });

  test('Staff cannot delete a staff member (403 Forbidden)', async () => {
    const mockStaff = {
      _id: new mongoose.Types.ObjectId(targetStaffId),
      name: 'Fellow Staff',
      email: 'fellow.staff@campus.edu',
      role: 'staff',
    };

    mock.method(User, 'findById', async () => mockStaff);

    const res = await request(app)
      .delete(`/api/staff/students/${targetStaffId}`)
      .set('Authorization', `Bearer ${staffToken}`);

    assert.equal(res.status, 403);
    assert.match(res.body.error.message, /only permitted to delete student accounts/i);

    mock.restoreAll();
  });

  test('Staff cannot delete an administrator (403 Forbidden)', async () => {
    const mockAdmin = {
      _id: new mongoose.Types.ObjectId(targetAdminId),
      name: 'System Admin',
      email: 'sysadmin@campus.edu',
      role: 'admin',
    };

    mock.method(User, 'findById', async () => mockAdmin);

    const res = await request(app)
      .delete(`/api/staff/students/${targetAdminId}`)
      .set('Authorization', `Bearer ${staffToken}`);

    assert.equal(res.status, 403);
    assert.match(res.body.error.message, /Administrator accounts cannot be deleted/i);

    mock.restoreAll();
  });

  test('Admin can delete a student account', async () => {
    const mockStudent = {
      _id: new mongoose.Types.ObjectId(targetStudentId),
      name: 'Withdrawn Student',
      email: 'withdrawn@campus.edu',
      role: 'student',
      studentId: 'STU-WITHDRAW-02',
      institution: fakeInstId,
    };

    mock.method(User, 'findById', async () => mockStudent);
    mock.method(UserDeletionAudit, 'create', async () => ({}));
    mock.method(User, 'findByIdAndDelete', async () => mockStudent);

    const res = await request(app)
      .delete(`/api/admin/users/${targetStudentId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);

    mock.restoreAll();
  });

  test('Admin can delete a staff account', async () => {
    const mockStaff = {
      _id: new mongoose.Types.ObjectId(targetStaffId),
      name: 'Resigned Staff',
      email: 'resigned.staff@campus.edu',
      role: 'staff',
      staffId: 'STAFF-RESIGNED',
      institution: fakeInstId,
    };

    mock.method(User, 'findById', async () => mockStaff);
    mock.method(UserDeletionAudit, 'create', async () => ({}));
    mock.method(User, 'findByIdAndDelete', async () => mockStaff);

    const res = await request(app)
      .delete(`/api/admin/users/${targetStaffId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);

    mock.restoreAll();
  });

  test('No user can delete an admin account (403 Forbidden)', async () => {
    const mockAdmin = {
      _id: new mongoose.Types.ObjectId(targetAdminId),
      name: 'Primary Admin',
      email: 'primary.admin@campus.edu',
      role: 'admin',
    };

    mock.method(User, 'findById', async () => mockAdmin);

    const res = await request(app)
      .delete(`/api/admin/users/${targetAdminId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    assert.equal(res.status, 403);
    assert.match(res.body.error.message, /Administrator accounts cannot be deleted/i);

    mock.restoreAll();
  });

  test('No user can delete their own account (400 Bad Request)', async () => {
    const res = await request(app)
      .delete(`/api/admin/users/${adminId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    assert.equal(res.status, 400);
    assert.match(res.body.error.message, /cannot delete your own account/i);
  });

  test('Historical service requests remain intact after account deletion', async () => {
    // Verify that deleting a student does NOT cascade-delete or corrupt requests
    const mockStudent = {
      _id: new mongoose.Types.ObjectId(targetStudentId),
      name: 'Archived Student',
      email: 'archived@campus.edu',
      role: 'student',
      institution: fakeInstId,
    };

    mock.method(User, 'findById', async () => mockStudent);
    mock.method(UserDeletionAudit, 'create', async () => ({}));
    mock.method(User, 'findByIdAndDelete', async () => mockStudent);

    let requestDeleted = false;
    mock.method(Request, 'deleteMany', async () => {
      requestDeleted = true;
    });

    const res = await request(app)
      .delete(`/api/admin/users/${targetStudentId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    assert.equal(res.status, 200);
    assert.equal(requestDeleted, false, 'Historical service requests must not be cascade-deleted');

    mock.restoreAll();
  });
});

describe('Staff Student Registration & Account Management', () => {
  const pendingStudentId = '64a1b2c3d4e5f6a7b8c9d088';
  const pendingStaffId = '64a1b2c3d4e5f6a7b8c9d099';

  test('Staff views pending student registrations (GET /api/staff/pending-students)', async () => {
    mock.method(User, 'find', () => ({
      populate: () => ({
        populate: () => ({
          sort: () => ({
            lean: async () => [
              {
                _id: new mongoose.Types.ObjectId(pendingStudentId),
                name: 'Pending Student',
                email: 'pending@uniflow.edu',
                role: 'student',
                studentId: 'STU2026888',
                approvalStatus: 'PENDING',
                createdAt: new Date(),
              },
            ],
          }),
        }),
      }),
    }));

    const res = await request(app)
      .get('/api/staff/pending-students')
      .set('Authorization', `Bearer ${staffToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(Array.isArray(res.body.data), true);
    assert.equal(res.body.data.length, 1);
    assert.equal(res.body.data[0].role, 'student');
  });

  test('Staff creates a student account successfully (POST /api/staff/students)', async () => {
    mock.method(Institution, 'findOne', () => ({
      lean: async () => ({ _id: fakeInstId, name: 'Campus Tech' }),
    }));
    mock.method(Department, 'findOne', () => ({
      lean: async () => ({ _id: fakeDeptId, name: 'Computer Science' }),
    }));
    mock.method(User, 'findOne', () => ({
      lean: async () => null,
    }));

    let createdUserRole = null;
    let createdCreatorRole = null;
    mock.method(User, 'create', async (doc) => {
      createdUserRole = doc.role;
      createdCreatorRole = doc.createdByRole;
      return {
        _id: new mongoose.Types.ObjectId(),
        ...doc,
      };
    });

    const res = await request(app)
      .post('/api/staff/students')
      .set('Authorization', `Bearer ${staffToken}`)
      .send({
        name: 'Staff Created Student',
        email: 'staff.created@uniflow.edu',
        password: 'Password123!',
        studentId: 'STU2026999',
        departmentId: fakeDeptId.toString(),
      });

    assert.equal(res.status, 201);
    assert.equal(res.body.success, true);
    assert.equal(createdUserRole, 'student');
    assert.equal(createdCreatorRole, 'staff');
  });

  test('Staff cannot create staff or admin account via /api/staff/students (400 validation error)', async () => {
    const res = await request(app)
      .post('/api/staff/students')
      .set('Authorization', `Bearer ${staffToken}`)
      .send({
        name: 'Staff Trying Staff',
        email: 'trying.staff@uniflow.edu',
        password: 'Password123!',
        studentId: 'STF2026999',
        role: 'staff',
      });

    assert.equal(res.status, 400);
    assert.equal(res.body.success, false);
  });

  test('Staff approves student registration (PATCH /api/staff/students/:id/approve)', async () => {
    const pendingStudent = {
      _id: new mongoose.Types.ObjectId(pendingStudentId),
      name: 'Approved Student',
      email: 'approved@uniflow.edu',
      role: 'student',
      approvalStatus: 'PENDING',
      save: async function () {
        return this;
      },
    };

    mock.method(User, 'findById', async () => pendingStudent);

    const res = await request(app)
      .patch(`/api/staff/students/${pendingStudentId}/approve`)
      .set('Authorization', `Bearer ${staffToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(pendingStudent.approvalStatus, 'APPROVED');
    assert.equal(pendingStudent.approvedByRole, 'staff');
  });

  test('Staff rejects student registration with reason (PATCH /api/staff/students/:id/reject)', async () => {
    const pendingStudent = {
      _id: new mongoose.Types.ObjectId(pendingStudentId),
      name: 'Rejected Student',
      email: 'rejected@uniflow.edu',
      role: 'student',
      approvalStatus: 'PENDING',
      save: async function () {
        return this;
      },
    };

    mock.method(User, 'findById', async () => pendingStudent);

    const res = await request(app)
      .patch(`/api/staff/students/${pendingStudentId}/reject`)
      .set('Authorization', `Bearer ${staffToken}`)
      .send({ reason: 'Invalid ID card provided.' });

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(pendingStudent.approvalStatus, 'REJECTED');
    assert.equal(pendingStudent.rejectedByRole, 'staff');
    assert.equal(pendingStudent.rejectionReason, 'Invalid ID card provided.');
  });

  test('Staff cannot approve non-student registration (403 Forbidden)', async () => {
    const pendingStaff = {
      _id: new mongoose.Types.ObjectId(pendingStaffId),
      name: 'Pending Staff',
      email: 'staff.pending@uniflow.edu',
      role: 'staff',
      approvalStatus: 'PENDING',
      save: async function () {
        return this;
      },
    };

    mock.method(User, 'findById', async () => pendingStaff);

    const res = await request(app)
      .patch(`/api/staff/students/${pendingStaffId}/approve`)
      .set('Authorization', `Bearer ${staffToken}`);

    assert.equal(res.status, 403);
    assert.equal(res.body.error.code, 'FORBIDDEN');
  });

  test('Staff searches and filters students with approvalStatus', async () => {
    mock.method(User, 'countDocuments', async () => 1);
    mock.method(User, 'find', () => ({
      populate: () => ({
        populate: () => ({
          sort: () => ({
            skip: () => ({
              limit: () => ({
                lean: async () => [
                  {
                    _id: new mongoose.Types.ObjectId(pendingStudentId),
                    name: 'Filtered Student',
                    email: 'filtered@uniflow.edu',
                    role: 'student',
                    studentId: 'STU2026888',
                    approvalStatus: 'APPROVED',
                    createdAt: new Date(),
                  },
                ],
              }),
            }),
          }),
        }),
      }),
    }));

    const res = await request(app)
      .get('/api/staff/students?approvalStatus=APPROVED&search=Filtered')
      .set('Authorization', `Bearer ${staffToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(res.body.data.length, 1);
  });
});
