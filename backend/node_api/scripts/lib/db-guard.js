/**
 * scripts/lib/db-guard.js
 *
 * Mandatory database isolation guard for production scripts.
 *
 * Enforces that maintenance, initialization, and administrative scripts can ONLY
 * execute against the designated production database ('uniflow_prod').
 * If connected to any other database (such as 'uniflow', 'uniflow_dev', or 'test'),
 * execution halts immediately BEFORE any schema mutation, insert, or write occurs.
 */

export const REQUIRED_PROD_DB_NAME = 'uniflow_prod';

/**
 * Verifies whether the provided database connection targets the designated production database.
 * @param {object} dbOrConnection - A Mongoose connection or MongoDB Db object.
 * @param {string} [expectedName=REQUIRED_PROD_DB_NAME] - Expected database name.
 * @returns {{ allowed: boolean, actualDb: string|null, error?: string }}
 */
export function verifyProductionDatabase(dbOrConnection, expectedName = REQUIRED_PROD_DB_NAME) {
  const actualDb =
    dbOrConnection?.databaseName ??
    dbOrConnection?.db?.databaseName ??
    dbOrConnection?.connection?.db?.databaseName ??
    null;

  if (!actualDb) {
    return {
      allowed: false,
      actualDb: null,
      error: 'Database isolation check failed: No active database connection found to inspect database name.',
    };
  }

  if (actualDb !== expectedName) {
    return {
      allowed: false,
      actualDb,
      error: `DATABASE ISOLATION VIOLATION: Production script requires database '${expectedName}', but connected to '${actualDb}'. Operation aborted immediately.`,
    };
  }

  return {
    allowed: true,
    actualDb,
  };
}

/**
 * Asserts that the connected database is the expected production database.
 * Throws a descriptive error if connected to any other database.
 * @param {object} dbOrConnection - A Mongoose connection or MongoDB Db object.
 * @param {string} [expectedName=REQUIRED_PROD_DB_NAME] - Expected database name.
 * @throws {Error} If database name does not match expectedName.
 * @returns {boolean} True if validation passes.
 */
export function assertProductionDatabase(dbOrConnection, expectedName = REQUIRED_PROD_DB_NAME) {
  const check = verifyProductionDatabase(dbOrConnection, expectedName);
  if (!check.allowed) {
    const error = new Error(check.error);
    error.code = 'DATABASE_ISOLATION_VIOLATION';
    error.actualDb = check.actualDb;
    throw error;
  }
  return true;
}
