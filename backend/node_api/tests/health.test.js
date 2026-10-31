/**
 * tests/health.test.js
 *
 * Tests for GET /api/health and JSON 404 handling.
 * Uses supertest to make real HTTP requests against the Express app.
 * No database connection is needed — the health endpoint is DB-independent.
 *
 * Environment: loaded from tests/.env.test via --env-file flag in `npm test`.
 */

import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';

// Import app after env vars are loaded by --env-file
const { default: app } = await import('../src/app.js');

describe('GET /api/health', () => {
  test('returns 200 with operational status', async () => {
    const res = await request(app).get('/api/health');

    assert.equal(res.status, 200, 'Status should be 200');
    assert.equal(res.body.success, true, 'success should be true');
    assert.equal(res.body.data.status, 'operational', 'status should be "operational"');
    assert.equal(res.body.data.service, 'uniflow-api', 'service name should match');
    assert.ok(res.body.data.timestamp, 'timestamp should be present');
    assert.ok(res.body.data.version, 'version should be present');
  });

  test('response Content-Type is application/json', async () => {
    const res = await request(app).get('/api/health');
    assert.match(
      res.headers['content-type'],
      /application\/json/,
      'Content-Type should be application/json'
    );
  });

  test('response includes environment field', async () => {
    const res = await request(app).get('/api/health');
    assert.ok(
      ['development', 'production', 'test'].includes(res.body.data.environment),
      'environment should be one of the valid values'
    );
  });
});

describe('JSON 404 handling', () => {
  test('unknown /api/* route returns JSON 404', async () => {
    const res = await request(app).get('/api/does-not-exist');

    assert.equal(res.status, 404, 'Status should be 404');
    assert.equal(res.body.success, false, 'success should be false');
    assert.ok(res.body.error, 'error object should be present');
    assert.equal(res.body.error.code, 'NOT_FOUND', 'error code should be NOT_FOUND');
    assert.ok(res.body.error.message, 'error message should be present');
  });

  test('root path (/) returns JSON not HTML', async () => {
    const res = await request(app).get('/');

    assert.equal(res.status, 404, 'Status should be 404');
    assert.match(
      res.headers['content-type'],
      /application\/json/,
      'Should return JSON, not HTML'
    );
    assert.equal(res.body.success, false);
  });

  test('deeply nested unknown route returns JSON 404', async () => {
    const res = await request(app).get('/api/admin/users/99999/settings');
    assert.equal(res.status, 404);
    assert.equal(res.body.success, false);
    assert.equal(res.body.error.code, 'NOT_FOUND');
  });
});

describe('Error handling middleware', () => {
  test('POST to /api/auth/register with empty body returns 400 VALIDATION_ERROR', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({})
      .set('Content-Type', 'application/json');

    assert.equal(res.status, 400, 'Status should be 400');
    assert.equal(res.body.success, false, 'success should be false');
    assert.equal(res.body.error.code, 'VALIDATION_ERROR', 'code should be VALIDATION_ERROR');
    assert.ok(Array.isArray(res.body.error.details), 'details should be an array');
    assert.ok(res.body.error.details.length > 0, 'details should have at least one entry');
  });

  test('POST to /api/auth/login with invalid email returns 400 VALIDATION_ERROR', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'not-an-email', password: 'somepassword' })
      .set('Content-Type', 'application/json');

    assert.equal(res.status, 400);
    assert.equal(res.body.error.code, 'VALIDATION_ERROR');
  });

  test('GET /api/auth/me without token returns 401 MISSING_TOKEN', async () => {
    const res = await request(app).get('/api/auth/me');

    assert.equal(res.status, 401, 'Status should be 401');
    assert.equal(res.body.success, false);
    assert.equal(res.body.error.code, 'MISSING_TOKEN', 'code should be MISSING_TOKEN');
  });

  test('GET /api/auth/me with malformed token returns 401', async () => {
    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', 'Bearer this.is.not.a.valid.jwt');

    assert.equal(res.status, 401);
    assert.equal(res.body.success, false);
    assert.equal(res.body.error.code, 'INVALID_TOKEN');
  });
});
