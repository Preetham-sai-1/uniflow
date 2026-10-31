/**
 * src/api/staffApi.js
 *
 * Staff and departmental review queue API client.
 */

import httpClient from './httpClient.js';

/**
 * Get staff review queue of pending requests awaiting action.
 * @param {Object} [params] - Query params: page, limit
 * @returns {Promise<Array>} List of pending queue items
 */
export async function getStaffQueue(params = {}) {
  const response = await httpClient.get('/staff/queue', { params });
  return response.data.data;
}

/**
 * Approve a pending step from the staff review queue.
 * @param {string} requestId - Request ObjectId
 * @param {number} stepIndex - Step index
 * @param {string} [comment] - Optional approver comment
 * @returns {Promise<Object>} Updated request
 */
export async function approveStaffStep(requestId, stepIndex, comment = '') {
  const response = await httpClient.patch(
    `/staff/requests/${requestId}/steps/${stepIndex}/approve`,
    { comment }
  );
  return response.data.data;
}

/**
 * Reject a pending step from the staff review queue.
 * @param {string} requestId - Request ObjectId
 * @param {number} stepIndex - Step index
 * @param {string} comment - Mandatory explanation for rejection
 * @returns {Promise<Object>} Updated request
 */
export async function rejectStaffStep(requestId, stepIndex, comment) {
  const response = await httpClient.patch(
    `/staff/requests/${requestId}/steps/${stepIndex}/reject`,
    { comment }
  );
  return response.data.data;
}
