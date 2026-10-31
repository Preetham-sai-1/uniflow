/**
 * src/api/requestsApi.js
 *
 * Student requests and workflow instance API client.
 */

import httpClient from './httpClient.js';

/**
 * List requests (for student: own requests; for staff/admin: filtered list).
 * @param {Object} [params] - Query params: status, serviceId, page, limit
 * @returns {Promise<{ items: Array, pagination: Object }>}
 */
export async function getRequests(params = {}) {
  const response = await httpClient.get('/requests', { params });
  return {
    items: response.data.data,
    pagination: response.data.pagination,
  };
}

/**
 * Get full request details by ID (including runtime steps, student, and audit log).
 * @param {string} id - Request ObjectId
 * @returns {Promise<Object>} Request details
 */
export async function getRequestById(id) {
  const response = await httpClient.get(`/requests/${id}`);
  return response.data.data;
}

/**
 * Submit a new student journey / service request.
 * @param {Object} payload - { serviceId, formData }
 * @returns {Promise<Object>} Created request
 */
export async function submitRequest({ serviceId, formData = {} }) {
  const response = await httpClient.post('/requests', { serviceId, formData });
  return response.data.data;
}

/**
 * Confirm simulated payment for an ID Card Replacement request in PAYMENT_REQUIRED status.
 * @param {string} id - Request ObjectId
 * @returns {Promise<Object>} Updated request transitioned to next step
 */
export async function confirmPayment(id) {
  const response = await httpClient.patch(`/requests/${id}/payment`);
  return response.data.data;
}

/**
 * Approve a workflow step.
 * @param {string} id - Request ObjectId
 * @param {number} stepIndex - Index of the step to approve
 * @param {string} [comment] - Optional approver comment
 * @returns {Promise<Object>} Updated request
 */
export async function approveStep(id, stepIndex, comment = '') {
  const response = await httpClient.patch(`/requests/${id}/steps/${stepIndex}/approve`, {
    comment,
  });
  return response.data.data;
}

/**
 * Reject a workflow step.
 * @param {string} id - Request ObjectId
 * @param {number} stepIndex - Index of the step to reject
 * @param {string} comment - Mandatory explanation for rejection
 * @returns {Promise<Object>} Updated request in REJECTED status
 */
export async function rejectStep(id, stepIndex, comment) {
  const response = await httpClient.patch(`/requests/${id}/steps/${stepIndex}/reject`, {
    comment,
  });
  return response.data.data;
}
