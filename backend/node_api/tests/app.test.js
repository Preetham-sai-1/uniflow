/**
 * tests/app.test.js
 *
 * Tests for basic application initialization.
 * Verifies the Express app is created correctly without needing a database.
 *
 * Environment: loaded from tests/.env.test via --env-file flag in `npm test`.
 */

import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

describe('Application initialization', () => {
  test('app module exports a valid Express application', async () => {
    const { default: app } = await import('../src/app.js');
    assert.ok(app, 'app should be defined');
    assert.equal(typeof app, 'function', 'Express app should be a function');
  });

  test('app has the expected Express request handler properties', async () => {
    const { default: app } = await import('../src/app.js');
    // Express apps expose these properties
    assert.ok(typeof app.use === 'function', 'app.use should be a function');
    assert.ok(typeof app.get === 'function', 'app.get should be a function');
    assert.ok(typeof app.listen === 'function', 'app.listen should be a function');
  });
});
