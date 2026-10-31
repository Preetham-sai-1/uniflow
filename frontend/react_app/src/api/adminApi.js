/**
 * src/api/adminApi.js
 *
 * Administrator operational statistics and request oversight API client.
 */

import httpClient from './httpClient.js';

/**
 * Get institutional summary statistics across all workflows.
 * @returns {Promise<Object>} Statistics { requests, bookings, byService }
 */
export async function getAdminStats() {
  const response = await httpClient.get('/admin/stats');
  return response.data.data;
}

/**
 * List all institutional requests across all students with filters.
 * @param {Object} [params] - Query params: status, serviceId, page, limit
 * @returns {Promise<{ items: Array, pagination: Object }>}
 */
export async function getAllRequests(params = {}) {
  const response = await httpClient.get('/admin/requests', { params });
  return {
    items: response.data.data,
    pagination: response.data.pagination,
  };
}
