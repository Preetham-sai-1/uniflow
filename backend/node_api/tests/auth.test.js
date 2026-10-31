/**
 * tests/auth.test.js
 *
 * Tests for authentication route behavior that does NOT require a database.
 *
 * Tested without DB:
 *  - Input validation errors (400) for register and login
 *  - Missing Authorization header (401)
 *  - Malformed / expired JWT (401)
 *  - requireRole behavior via /api/auth/me
 *
 * NOT tested here (requires a live MongoDB connection):
 *  - Successful registration creating a user in the database
 *  - Successful login returning a JWT
 *  - Duplicate email conflict (409)
 *  - GET /api/auth/me with a valid token returning user data
 *
 * Integration tests requiring a DB are documented as future work
 * in docs/DEVELOPMENT_PROGRESS.md.
 *
 * Environment: loaded from tests/.env.test via --env-file flag in `npm test`.
 */

import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';

const { default: app } = await import('../src/app.js');

// ─── POST /api/auth/register ──────────────────────────────────────────────────

describe('POST /api/auth/register — validation', () => {
  test('empty body returns 400 VALIDATION_ERROR', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({})
      .set('Content-Type', 'application/json');

    assert.equal(res.status, 400);
    assert.equal(res.body.success, false);
    assert.equal(res.body.error.code, 'VALIDATION_ERROR');
    assert.ok(Array.isArray(res.body.error.details));
  });

  test('invalid email returns 400 with email field error', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Arjun', email: 'not-valid', password: 'Secure@123', role: 'student' });

    assert.equal(res.status, 400);
    assert.equal(res.body.error.code, 'VALIDATION_ERROR');
    const emailError = res.body.error.details.find((d) => d.field === 'email');
    assert.ok(emailError, 'Should have an error for the email field');
  });

  test('password too short returns 400', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Arjun', email: 'arjun@test.edu', password: 'short', role: 'student' });

    assert.equal(res.status, 400);
    const pwError = res.body.error.details.find((d) => d.field === 'password');
    assert.ok(pwError, 'Should have a password validation error');
  });

  test('invalid role returns 400', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Arjun', email: 'arjun@test.edu', password: 'Secure@1234', role: 'superuser' });

    assert.equal(res.status, 400);
    const roleError = res.body.error.details.find((d) => d.field === 'role');
    assert.ok(roleError, 'Should have a role validation error');
  });

  test('attempting role: admin returns 400 VALIDATION_ERROR (prevents privilege escalation)', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Hacker', email: 'hacker@test.edu', password: 'Secure@1234', role: 'admin' });

    assert.equal(res.status, 400);
    const roleError = res.body.error.details.find((d) => d.field === 'role');
    assert.ok(roleError, 'Should prevent non-student registration');
  });

  test('missing name returns 400 with name field error', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ email: 'arjun@test.edu', password: 'Secure@1234', role: 'student' });

    assert.equal(res.status, 400);
    const nameError = res.body.error.details.find((d) => d.field === 'name');
    assert.ok(nameError, 'Should have a name validation error');
  });

  test('name too short (1 char) returns 400', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ name: 'A', email: 'a@test.edu', password: 'Secure@1234', role: 'student' });

    assert.equal(res.status, 400);
    assert.equal(res.body.error.code, 'VALIDATION_ERROR');
  });
});

// ─── POST /api/auth/login ─────────────────────────────────────────────────────

describe('POST /api/auth/login — validation', () => {
  test('empty body returns 400 VALIDATION_ERROR', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({})
      .set('Content-Type', 'application/json');

    assert.equal(res.status, 400);
    assert.equal(res.body.error.code, 'VALIDATION_ERROR');
    assert.ok(Array.isArray(res.body.error.details));
  });

  test('invalid email format returns 400', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'bademail', password: 'anything' });

    assert.equal(res.status, 400);
    assert.equal(res.body.error.code, 'VALIDATION_ERROR');
  });

  test('missing password returns 400', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'user@test.edu' });

    assert.equal(res.status, 400);
    assert.equal(res.body.error.code, 'VALIDATION_ERROR');
  });
});

// ─── GET /api/auth/me — token handling ───────────────────────────────────────

describe('GET /api/auth/me — token validation', () => {
  test('no Authorization header returns 401 MISSING_TOKEN', async () => {
    const res = await request(app).get('/api/auth/me');

    assert.equal(res.status, 401);
    assert.equal(res.body.success, false);
    assert.equal(res.body.error.code, 'MISSING_TOKEN');
  });

  test('"Authorization: Bearer" without token returns 401', async () => {
    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', 'Bearer ');

    assert.equal(res.status, 401);
    assert.equal(res.body.success, false);
  });

  test('invalid JWT string returns 401 INVALID_TOKEN', async () => {
    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', 'Bearer eyJhbGciOiJIUzI1NiJ9.invalid.signature');

    assert.equal(res.status, 401);
    assert.equal(res.body.error.code, 'INVALID_TOKEN');
  });

  test('totally malformed token returns 401', async () => {
    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', 'Bearer not.a.jwt.at.all.here');

    assert.equal(res.status, 401);
    assert.equal(res.body.success, false);
  });

  test('Basic auth scheme (not Bearer) returns 401', async () => {
    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', 'Basic dXNlcjpwYXNz');

    assert.equal(res.status, 401);
    assert.equal(res.body.error.code, 'MISSING_TOKEN');
  });
});

// ─── Standard response envelope ───────────────────────────────────────────────

describe('Standard error response envelope', () => {
  test('all error responses have success: false and error object', async () => {
    const endpoints = [
      { method: 'POST', path: '/api/auth/register', body: {} },
      { method: 'POST', path: '/api/auth/login', body: {} },
      { method: 'GET', path: '/api/auth/me', body: null },
    ];

    for (const { method, path, body } of endpoints) {
      let req = request(app)[method.toLowerCase()](path);
      if (body) req = req.send(body).set('Content-Type', 'application/json');
      const res = await req;

      assert.equal(typeof res.body, 'object', `${method} ${path} should return an object`);
      assert.equal(res.body.success, false, `${method} ${path} should have success: false`);
      assert.ok(res.body.error, `${method} ${path} should have an error object`);
      assert.ok(res.body.error.code, `${method} ${path} error should have a code`);
      assert.ok(res.body.error.message, `${method} ${path} error should have a message`);
    }
  });
});
