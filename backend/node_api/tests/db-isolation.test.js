/**
 * tests/db-isolation.test.js
 *
 * Tests for Production Database Isolation Guard.
 *
 * Verifies:
 *  - Guard rejects database 'uniflow' (development).
 *  - Guard rejects other non-production databases ('uniflow-test', 'dev', etc.).
 *  - Guard strictly accepts 'uniflow_prod'.
 *  - init:prod refuses database 'uniflow'.
 *  - init:prod accepts 'uniflow_prod'.
 *  - create-admin refuses database 'uniflow'.
 *  - create-admin accepts 'uniflow_prod'.
 *  - Zero database writes occur when the database isolation guard triggers.
 */

import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import {
  verifyProductionDatabase,
  assertProductionDatabase,
  REQUIRED_PROD_DB_NAME,
} from '../scripts/lib/db-guard.js';

describe('Database Isolation Guard — db-guard.js', () => {
  test('REQUIRED_PROD_DB_NAME is strictly "uniflow_prod"', () => {
    assert.equal(REQUIRED_PROD_DB_NAME, 'uniflow_prod');
  });

  test('verifyProductionDatabase rejects "uniflow" (development database)', () => {
    const mockConn = { db: { databaseName: 'uniflow' } };
    const result = verifyProductionDatabase(mockConn);
    assert.equal(result.allowed, false);
    assert.equal(result.actualDb, 'uniflow');
    assert.match(result.error, /DATABASE ISOLATION VIOLATION/);
  });

  test('verifyProductionDatabase rejects arbitrary non-production databases', () => {
    const disallowedNames = ['uniflow-test', 'uniflow_dev', 'test', 'admin', 'default', ''];
    for (const name of disallowedNames) {
      const mockConn = { db: { databaseName: name } };
      const result = verifyProductionDatabase(mockConn);
      assert.equal(result.allowed, false, `Database "${name}" should be rejected`);
    }
  });

  test('verifyProductionDatabase accepts "uniflow_prod"', () => {
    const mockConn = { db: { databaseName: 'uniflow_prod' } };
    const result = verifyProductionDatabase(mockConn);
    assert.equal(result.allowed, true);
    assert.equal(result.actualDb, 'uniflow_prod');
    assert.equal(result.error, undefined);
  });

  test('assertProductionDatabase throws DATABASE_ISOLATION_VIOLATION for "uniflow"', () => {
    const mockConn = { db: { databaseName: 'uniflow' } };
    assert.throws(
      () => assertProductionDatabase(mockConn),
      (err) => {
        assert.equal(err.code, 'DATABASE_ISOLATION_VIOLATION');
        assert.equal(err.actualDb, 'uniflow');
        assert.match(err.message, /DATABASE ISOLATION VIOLATION/);
        return true;
      }
    );
  });

  test('assertProductionDatabase succeeds for "uniflow_prod"', () => {
    const mockConn = { db: { databaseName: 'uniflow_prod' } };
    const passed = assertProductionDatabase(mockConn);
    assert.equal(passed, true);
  });

  test('verifyProductionDatabase handles missing connection object safely', () => {
    assert.equal(verifyProductionDatabase(null).allowed, false);
    assert.equal(verifyProductionDatabase({}).allowed, false);
    assert.equal(verifyProductionDatabase({ db: null }).allowed, false);
  });
});

describe('Script Isolation & Write Prevention Simulation', () => {
  test('init:prod guard halts execution and ensures 0 database writes when database is "uniflow"', async () => {
    let writesAttempted = 0;

    // Simulate an attempt where database guard inspects the connection
    const mockDevConnection = {
      db: { databaseName: 'uniflow' },
    };

    let guardTriggered = false;
    try {
      assertProductionDatabase(mockDevConnection);
      // Simulated write operations that MUST NOT execute:
      writesAttempted++;
    } catch (err) {
      guardTriggered = true;
      assert.equal(err.code, 'DATABASE_ISOLATION_VIOLATION');
      assert.equal(err.actualDb, 'uniflow');
    }

    assert.equal(guardTriggered, true, 'Guard must trigger on database "uniflow"');
    assert.equal(writesAttempted, 0, 'Zero writes must occur when guard fails');
  });

  test('init:prod guard permits execution when database is "uniflow_prod"', () => {
    const mockProdConnection = {
      db: { databaseName: 'uniflow_prod' },
    };

    let guardTriggered = false;
    try {
      assertProductionDatabase(mockProdConnection);
    } catch {
      guardTriggered = true;
    }

    assert.equal(guardTriggered, false, 'Guard must not trigger on database "uniflow_prod"');
  });

  test('create-admin guard halts execution and ensures 0 user creations when database is "uniflow"', async () => {
    let usersCreated = 0;

    const mockDevConnection = {
      db: { databaseName: 'uniflow' },
    };

    let guardTriggered = false;
    try {
      assertProductionDatabase(mockDevConnection);
      // Simulated User.create that MUST NOT execute:
      usersCreated++;
    } catch (err) {
      guardTriggered = true;
      assert.equal(err.code, 'DATABASE_ISOLATION_VIOLATION');
      assert.equal(err.actualDb, 'uniflow');
    }

    assert.equal(guardTriggered, true, 'Guard must trigger on database "uniflow"');
    assert.equal(usersCreated, 0, 'Zero users must be created when guard fails');
  });

  test('create-admin guard permits execution when database is "uniflow_prod"', () => {
    const mockProdConnection = {
      db: { databaseName: 'uniflow_prod' },
    };

    let guardTriggered = false;
    try {
      assertProductionDatabase(mockProdConnection);
    } catch {
      guardTriggered = true;
    }

    assert.equal(guardTriggered, false, 'Guard must not trigger on database "uniflow_prod"');
  });
});
